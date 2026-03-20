/**
 * Dialog hook — native <dialog> + showModal() with enter/exit transitions.
 *
 * The <dialog> element is full-viewport with bg-black/50 (acts as overlay).
 * An inner <div data-slot="dialog-content"> holds the centered panel.
 * Backdrop clicks detected via e.target === dialog (not a child).
 *
 * Transitions are driven by a `data-state` attribute ("open" | "closing")
 * on both the dialog and content elements. CSS transitions in the component
 * classes handle the actual animation (opacity, translate, scale).
 *
 * Config via data attributes on the <dialog>:
 *   data-auto-open="true|false"  — call showModal() on mount
 *   data-on-cancel="event|JS"    — callback on dismiss (Escape / backdrop click)
 */
import { notifyServer, listenForCommands } from "./event-bridge.js";

const Dialog = {
  mounted() {
    this._onCancel = this.el.dataset.onCancel || null;
    this._content = this.el.querySelector('[data-slot="dialog-content"], [data-slot="alert-dialog-content"], [data-slot="sheet-content"]');
    this._transitioning = false;
    this._hideTimer = null;

    // Open on mount if data-auto-open="true"
    if (this.el.dataset.autoOpen === "true" && !this.el.open) {
      this._show();
    }

    // Escape key — browser fires "cancel" on <dialog>
    this._onCancelEvent = (e) => {
      e.preventDefault();
      this._dismiss();
    };
    this.el.addEventListener("cancel", this._onCancelEvent);

    // Backdrop click — clicks on the dialog itself (not children)
    this._onClick = (e) => {
      if (e.target === this.el && this.el.dataset.noBackdropDismiss !== "true") {
        this._dismiss();
      }
    };
    this.el.addEventListener("click", this._onClick);

    // Custom events from JS helpers
    this._onShowEvent = () => this._show();
    this._onHideEvent = () => this._hide();
    this.el.addEventListener("phx-shadcn:show", this._onShowEvent);
    this.el.addEventListener("phx-shadcn:hide", this._onHideEvent);

    // Server→client push_event commands
    listenForCommands(this, ({ command }) => {
      if (command === "show") this._show();
      else if (command === "hide") this._hide();
    });
  },

  _show() {
    if (this.el.open) return;
    clearTimeout(this._hideTimer);
    this._transitioning = false;

    this.el.showModal();
    // Next frame: trigger enter transition (from opacity-0 → opacity-100, etc.)
    requestAnimationFrame(() => {
      this.el.dataset.state = "open";
      if (this._content) this._content.dataset.state = "open";
    });
  },

  _hide() {
    if (!this.el.open || this._transitioning) return;
    this._transitioning = true;

    // Trigger exit transition (back to base opacity-0, translate-y-4, etc.)
    this.el.dataset.state = "closing";
    if (this._content) this._content.dataset.state = "closing";

    const cleanup = () => {
      clearTimeout(this._hideTimer);
      this._transitioning = false;
      if (this.el.open) this.el.close();
      delete this.el.dataset.state;
      if (this._content) delete this._content.dataset.state;
    };

    // Wait for content panel transition to finish
    if (this._content) {
      this._content.addEventListener("transitionend", cleanup, { once: true });
    }
    // Fallback in case transitionend doesn't fire
    const duration = parseInt(this.el.dataset.animationDuration, 10) || 200;
    this._hideTimer = setTimeout(cleanup, duration + 50);
  },

  _dismiss() {
    notifyServer(this, this._onCancel, { id: this.el.id });
  },

  updated() {
    this._onCancel = this.el.dataset.onCancel || null;
    // Re-apply open state if dialog is open (morphdom safety)
    if (this.el.open && !this._transitioning) {
      this.el.dataset.state = "open";
      if (this._content) this._content.dataset.state = "open";
    }
  },

  destroyed() {
    clearTimeout(this._hideTimer);
    this.el.removeEventListener("cancel", this._onCancelEvent);
    this.el.removeEventListener("click", this._onClick);
    this.el.removeEventListener("phx-shadcn:show", this._onShowEvent);
    this.el.removeEventListener("phx-shadcn:hide", this._onHideEvent);
  },
};

export { Dialog as PhxShadcnDialog };
export default Dialog;
