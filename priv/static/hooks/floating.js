/**
 * Floating hook — generic positioning for Popover, Tooltip, DropdownMenu, etc.
 *
 * Uses Floating UI for anchor-based positioning with flip/shift middleware.
 * Manages show/hide transitions via `data-state` ("open" | "closing").
 *
 * Config via data attributes on the root element:
 *   data-trigger-type="click|hover|manual"
 *   data-on-open-change="event|JS"  — callback on dismiss
 *   data-auto-open="true|false"     — open on mount
 *   data-animation-duration="150"   — transition ms (fallback timer)
 *   data-open-delay="0"             — ms before showing (hover mode)
 *   data-close-delay="0"            — ms before hiding (hover mode)
 *
 * Children found by:
 *   [data-floating-trigger] — the trigger element
 *   [data-floating-content] — the floating content panel
 *
 * Content positioning config (data attrs on content element):
 *   data-side="top|right|bottom|left"
 *   data-align="start|center|end"
 *   data-side-offset="4"
 */
import {
  computePosition,
  offset,
  flip,
  shift,
  autoUpdate,
} from "../vendor/floating-ui.dom.esm.js";
import { notifyServer, listenForCommands } from "./event-bridge.js";

// Map side + align to Floating UI placement strings
function toPlacement(side, align) {
  if (align === "center") return side;
  return `${side}-${align === "start" ? "start" : "end"}`;
}

// Parse actual placement back to side + align
function fromPlacement(placement) {
  const parts = placement.split("-");
  return {
    side: parts[0],
    align: parts[1] || "center",
  };
}

const Floating = {
  mounted() {
    this._trigger = this.el.querySelector("[data-floating-trigger]");
    this._content = this.el.querySelector("[data-floating-content]");
    this._open = false;
    this._transitioning = false;
    this._hideTimer = null;
    this._showTimer = null;
    this._closeTimer = null;
    this._cleanupAutoUpdate = null;

    this._readConfig();

    // Trigger interaction
    if (this._triggerType === "click") {
      this._onTriggerClick = () => {
        if (this._open) this._hide();
        else this._show();
      };
      this._trigger.addEventListener("click", this._onTriggerClick);
    } else if (this._triggerType === "hover") {
      this._setupHoverListeners();
    }

    // Click outside — only for non-hover trigger types
    if (this._triggerType !== "hover") {
      this._onDocumentClick = (e) => {
        if (this._open && !this.el.contains(e.target)) {
          this._dismiss();
        }
      };
      document.addEventListener("click", this._onDocumentClick, true);
    }

    // Escape key
    this._onKeydown = (e) => {
      if (this._open && e.key === "Escape") {
        e.stopPropagation();
        this._dismiss();
      }
    };
    document.addEventListener("keydown", this._onKeydown);

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

    // Auto-open on mount
    if (this.el.dataset.autoOpen === "true") {
      this._show();
    }
  },

  _readConfig() {
    this._triggerType = this.el.dataset.triggerType || "click";
    this._onOpenChange = this.el.dataset.onOpenChange || null;
    this._animationDuration =
      parseInt(this.el.dataset.animationDuration, 10) || 150;
    this._openDelay = parseInt(this.el.dataset.openDelay, 10) || 0;
    this._closeDelay = parseInt(this.el.dataset.closeDelay, 10) || 0;
  },

  _setupHoverListeners() {
    // Trigger mouseenter — start open delay
    this._onTriggerMouseenter = () => {
      clearTimeout(this._closeTimer);
      this._showTimer = setTimeout(() => this._show(), this._openDelay);
    };

    // Trigger mouseleave — start close delay
    this._onTriggerMouseleave = () => {
      clearTimeout(this._showTimer);
      this._closeTimer = setTimeout(() => this._hide(), this._closeDelay);
    };

    // Content mouseenter — cancel close (grace period for moving to content)
    this._onContentMouseenter = () => {
      clearTimeout(this._closeTimer);
    };

    // Content mouseleave — start close delay
    this._onContentMouseleave = () => {
      this._closeTimer = setTimeout(() => this._hide(), this._closeDelay);
    };

    // Trigger focus — show immediately (a11y)
    this._onTriggerFocus = () => {
      clearTimeout(this._closeTimer);
      this._show();
    };

    // Trigger blur — start close delay
    this._onTriggerBlur = () => {
      this._closeTimer = setTimeout(() => this._hide(), this._closeDelay);
    };

    this._trigger.addEventListener("mouseenter", this._onTriggerMouseenter);
    this._trigger.addEventListener("mouseleave", this._onTriggerMouseleave);
    this._content.addEventListener("mouseenter", this._onContentMouseenter);
    this._content.addEventListener("mouseleave", this._onContentMouseleave);
    this._trigger.addEventListener("focusin", this._onTriggerFocus);
    this._trigger.addEventListener("focusout", this._onTriggerBlur);
  },

  _show() {
    if (this._open) return;
    clearTimeout(this._hideTimer);
    this._transitioning = false;
    this._open = true;

    // ARIA linking for hover mode (tooltip)
    if (this._triggerType === "hover") {
      this._setAriaDescribedBy();
    }

    // Unhide content
    this._content.removeAttribute("hidden");

    // Compute position
    this._position().then(() => {
      // Start autoUpdate (recalculates on scroll/resize)
      this._cleanupAutoUpdate = autoUpdate(
        this._trigger,
        this._content,
        () => this._position(),
        { animationFrame: true },
      );

      // Force the browser to commit the base (opacity-0, scale-95, translate)
      // layout before we flip to "open". Without this, the transition doesn't
      // fire because hidden→visible + class change happen in the same frame.
      // Reading a computed style property forces a synchronous reflow.
      void getComputedStyle(this._content).opacity;

      // Now trigger enter transition
      requestAnimationFrame(() => {
        this.el.dataset.state = "open";
        this._content.dataset.state = "open";
      });
    });
  },

  _hide() {
    if (!this._open || this._transitioning) return;
    this._transitioning = true;

    // Remove ARIA linking for hover mode
    if (this._triggerType === "hover") {
      this._removeAriaDescribedBy();
    }

    // Trigger exit transition
    this.el.dataset.state = "closing";
    this._content.dataset.state = "closing";

    const cleanup = () => {
      clearTimeout(this._hideTimer);
      this._transitioning = false;
      this._open = false;

      this._content.setAttribute("hidden", "");
      delete this.el.dataset.state;
      delete this._content.dataset.state;

      // Stop autoUpdate
      if (this._cleanupAutoUpdate) {
        this._cleanupAutoUpdate();
        this._cleanupAutoUpdate = null;
      }
    };

    this._content.addEventListener("transitionend", cleanup, { once: true });
    this._hideTimer = setTimeout(cleanup, this._animationDuration + 50);
  },

  _dismiss() {
    this._hide();
    notifyServer(this, this._onOpenChange, { id: this.el.id, open: false });
  },

  // ARIA: set aria-describedby on the trigger's focusable child (or trigger itself)
  _setAriaDescribedBy() {
    if (!this._content.id) {
      this._content.id = `${this.el.id}-content`;
    }
    const target =
      this._trigger.querySelector("button, a, input, [tabindex]") ||
      this._trigger;
    target.setAttribute("aria-describedby", this._content.id);
    this._ariaTarget = target;
  },

  _removeAriaDescribedBy() {
    if (this._ariaTarget) {
      this._ariaTarget.removeAttribute("aria-describedby");
      this._ariaTarget = null;
    }
  },

  async _position() {
    const side = this._content.dataset.side || "bottom";
    const align = this._content.dataset.align || "center";
    const sideOffset =
      parseInt(this._content.dataset.sideOffset, 10) || 4;

    const placement = toPlacement(side, align);

    const { x, y, placement: actualPlacement } = await computePosition(
      this._trigger,
      this._content,
      {
        strategy: "fixed",
        placement,
        middleware: [offset(sideOffset), flip(), shift({ padding: 8 })],
      },
    );

    // Apply position
    Object.assign(this._content.style, {
      position: "fixed",
      left: `${x}px`,
      top: `${y}px`,
    });

    // Update data-side/data-align to reflect actual placement (may differ due to flip)
    const actual = fromPlacement(actualPlacement);
    this._content.dataset.side = actual.side;
    this._content.dataset.align = actual.align;

    // Propagate side to arrow element (if present) for CSS positioning
    const arrow = this._content.querySelector("[data-slot='tooltip-arrow']");
    if (arrow) arrow.dataset.side = actual.side;
  },

  updated() {
    this._readConfig();

    // Re-apply open state if open (morphdom safety)
    if (this._open && !this._transitioning) {
      this.el.dataset.state = "open";
      this._content.dataset.state = "open";
      this._position();
    }
  },

  destroyed() {
    clearTimeout(this._hideTimer);
    clearTimeout(this._showTimer);
    clearTimeout(this._closeTimer);

    if (this._cleanupAutoUpdate) {
      this._cleanupAutoUpdate();
      this._cleanupAutoUpdate = null;
    }

    if (this._onTriggerClick) {
      this._trigger.removeEventListener("click", this._onTriggerClick);
    }
    if (this._onDocumentClick) {
      document.removeEventListener("click", this._onDocumentClick, true);
    }
    document.removeEventListener("keydown", this._onKeydown);
    this.el.removeEventListener("phx-shadcn:show", this._onShowEvent);
    this.el.removeEventListener("phx-shadcn:hide", this._onHideEvent);

    // Hover listeners
    if (this._onTriggerMouseenter) {
      this._trigger.removeEventListener("mouseenter", this._onTriggerMouseenter);
      this._trigger.removeEventListener("mouseleave", this._onTriggerMouseleave);
      this._content.removeEventListener("mouseenter", this._onContentMouseenter);
      this._content.removeEventListener("mouseleave", this._onContentMouseleave);
      this._trigger.removeEventListener("focusin", this._onTriggerFocus);
      this._trigger.removeEventListener("focusout", this._onTriggerBlur);
    }

    this._removeAriaDescribedBy();
  },
};

export { Floating as PhxShadcnFloating };
export default Floating;
