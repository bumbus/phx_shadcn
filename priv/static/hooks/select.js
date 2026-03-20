/**
 * Select hook — custom styled select dropdown with keyboard navigation.
 *
 * Combines Floating UI positioning (from DropdownMenu) with single-value
 * selection and 3-mode state (from RadioGroup).
 *
 * Config via data attributes on the root element:
 *   data-state-mode="client|hybrid|server"
 *   data-value="val"              (server mode: current value)
 *   data-default-value="val"      (client/hybrid: initial value)
 *   data-on-value-change="event|JS"
 *   data-on-open-change="event|JS"
 *   data-auto-open="true|false"
 *   data-animation-duration="150"
 *
 * Children found by:
 *   [data-select-trigger]  — the trigger button
 *   [data-select-content]  — the floating listbox panel
 *   [data-slot="select-value"] — display element for selected label
 */
import {
  computePosition,
  offset,
  flip,
  shift,
  autoUpdate,
} from "../vendor/floating-ui.dom.esm.js";
import { notifyServer, listenForCommands, syncFormInput } from "./event-bridge.js";

// ── Floating UI placement helpers ────────────────────────────────────

function toPlacement(side, align) {
  if (align === "center") return side;
  return `${side}-${align === "start" ? "start" : "end"}`;
}

function fromPlacement(placement) {
  const parts = placement.split("-");
  return { side: parts[0], align: parts[1] || "center" };
}

// ── Item helpers ─────────────────────────────────────────────────────

const ITEM_SEL = "[data-slot='select-item']:not([data-disabled])";

function getItems(container) {
  return Array.from(container.querySelectorAll(ITEM_SEL));
}

function focusItem(item, container) {
  if (!item) return;
  container
    .querySelectorAll("[data-slot='select-item']")
    .forEach((el) => el.setAttribute("tabindex", "-1"));
  item.setAttribute("tabindex", "0");
  item.focus();
  item.scrollIntoView({ block: "nearest" });
}

// ── Hook ─────────────────────────────────────────────────────────────

const Select = {
  mounted() {
    this._trigger = this.el.querySelector("[data-select-trigger]");
    this._content = this.el.querySelector("[data-select-content]");
    this._open = false;
    this._transitioning = false;
    this._hideTimer = null;
    this._cleanupAutoUpdate = null;
    this._typeaheadBuffer = "";
    this._typeaheadTimer = null;

    this._readConfig();

    // Find the actual button inside the trigger wrapper
    this._triggerButton =
      this._trigger.querySelector("button") || this._trigger;

    // Parse initial value
    this._value = null;
    const initial =
      this._stateMode === "server"
        ? this.el.dataset.value
        : this.el.dataset.defaultValue;

    if (initial) {
      this._value = initial;
      this._applySelection();
      this._updateValueDisplay();
    }

    // ── Trigger click ────────────────────────────────────────────────
    this._onTriggerClick = (e) => {
      e.stopPropagation();
      if (this._open) this._hide();
      else this._show();
    };
    this._trigger.addEventListener("click", this._onTriggerClick);

    // ── Trigger keyboard — open on ArrowDown/Enter/Space ─────────────
    this._onTriggerKeydown = (e) => {
      if (e.key === "ArrowDown" || e.key === "Enter" || e.key === " ") {
        e.preventDefault();
        if (!this._open) this._show();
      }
      if (e.key === "ArrowUp") {
        e.preventDefault();
        if (!this._open) this._show(true); // focus last item
      }
    };
    this._triggerButton.addEventListener("keydown", this._onTriggerKeydown);

    // ── Click outside ────────────────────────────────────────────────
    this._onDocumentClick = (e) => {
      if (this._open && !this.el.contains(e.target)) {
        this._dismiss();
      }
    };
    document.addEventListener("click", this._onDocumentClick, true);

    // ── Listbox keyboard navigation ──────────────────────────────────
    this._onContentKeydown = (e) => {
      if (!this._open) return;

      const items = getItems(this._content);
      const currentIndex = items.indexOf(document.activeElement);

      switch (e.key) {
        case "ArrowDown": {
          e.preventDefault();
          const next =
            currentIndex < items.length - 1 ? currentIndex + 1 : 0;
          focusItem(items[next], this._content);
          break;
        }
        case "ArrowUp": {
          e.preventDefault();
          const prev =
            currentIndex > 0 ? currentIndex - 1 : items.length - 1;
          focusItem(items[prev], this._content);
          break;
        }
        case "Home": {
          e.preventDefault();
          focusItem(items[0], this._content);
          break;
        }
        case "End": {
          e.preventDefault();
          focusItem(items[items.length - 1], this._content);
          break;
        }
        case "Enter":
        case " ": {
          e.preventDefault();
          if (document.activeElement && items.includes(document.activeElement)) {
            const val = document.activeElement.dataset.val;
            if (val != null) this._selectItem(val, "user");
          }
          break;
        }
        case "Tab": {
          e.preventDefault();
          this._dismiss();
          break;
        }
        case "Escape": {
          e.preventDefault();
          e.stopPropagation();
          this._dismiss();
          break;
        }
        default: {
          // Typeahead — printable single character
          if (e.key.length === 1 && !e.ctrlKey && !e.metaKey && !e.altKey) {
            e.preventDefault();
            this._handleTypeahead(e.key, items);
          }
        }
      }
    };
    this._content.addEventListener("keydown", this._onContentKeydown);

    // ── Item click ───────────────────────────────────────────────────
    this._onContentClick = (e) => {
      const item = e.target.closest("[data-slot='select-item']");
      if (!item) return;
      if (item.hasAttribute("data-disabled")) {
        e.preventDefault();
        e.stopPropagation();
        return;
      }
      const val = item.dataset.val;
      if (val != null) this._selectItem(val, "user");
    };
    this._content.addEventListener("click", this._onContentClick);

    // ── Custom events (JS helpers) ───────────────────────────────────
    this._onShowEvent = () => this._show();
    this._onHideEvent = () => this._hide();
    this.el.addEventListener("phx-shadcn:show", this._onShowEvent);
    this.el.addEventListener("phx-shadcn:hide", this._onHideEvent);

    // ── Server→client push_event commands ────────────────────────────
    listenForCommands(this, ({ command, value }) => {
      if (command === "show") this._show();
      else if (command === "hide") this._hide();
      else if (command === "select" || command === "set") {
        this._selectItem(value, "server");
      }
    });

    // Auto-open on mount
    if (this.el.dataset.autoOpen === "true") {
      this._show();
    }
  },

  _readConfig() {
    this._stateMode = this.el.dataset.stateMode || "client";
    this._onValueChange = this.el.dataset.onValueChange || null;
    this._onOpenChange = this.el.dataset.onOpenChange || null;
    this._animationDuration =
      parseInt(this.el.dataset.animationDuration, 10) || 150;
  },

  // ── Typeahead ──────────────────────────────────────────────────────

  _handleTypeahead(char, items) {
    this._typeaheadBuffer += char.toLowerCase();
    clearTimeout(this._typeaheadTimer);
    this._typeaheadTimer = setTimeout(() => {
      this._typeaheadBuffer = "";
    }, 500);

    const match = items.find((item) => {
      const text = (item.textContent || "").trim().toLowerCase();
      return text.startsWith(this._typeaheadBuffer);
    });

    if (match) focusItem(match, this._content);
  },

  // ── Show / Hide ────────────────────────────────────────────────────

  _show(focusLast) {
    if (this._open) return;
    clearTimeout(this._hideTimer);
    this._transitioning = false;
    this._open = true;

    // ARIA
    this._triggerButton.setAttribute("aria-expanded", "true");

    // Unhide content
    this._content.removeAttribute("hidden");

    // Position and start transitions
    this._position().then(() => {
      this._cleanupAutoUpdate = autoUpdate(
        this._trigger,
        this._content,
        () => this._position(),
        { animationFrame: true },
      );

      // Force reflow before triggering transition
      void getComputedStyle(this._content).opacity;

      requestAnimationFrame(() => {
        this.el.dataset.state = "open";
        this._content.dataset.state = "open";

        // Focus selected item, or first/last item
        requestAnimationFrame(() => {
          const items = getItems(this._content);
          if (items.length === 0) return;

          // Try to find selected item
          let target = null;
          if (this._value) {
            target = items.find(
              (item) => item.dataset.val === this._value
            );
          }
          if (!target) {
            target = focusLast ? items[items.length - 1] : items[0];
          }
          focusItem(target, this._content);
        });
      });
    });
  },

  _hide() {
    if (!this._open || this._transitioning) return;
    this._transitioning = true;

    // ARIA
    this._triggerButton.setAttribute("aria-expanded", "false");

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

      // Return focus to trigger
      this._triggerButton.focus();
    };

    this._content.addEventListener("transitionend", cleanup, { once: true });
    this._hideTimer = setTimeout(cleanup, this._animationDuration + 50);
  },

  _dismiss() {
    this._hide();
    notifyServer(this, this._onOpenChange, { id: this.el.id, open: false });
  },

  // ── Selection ──────────────────────────────────────────────────────

  _selectItem(value, source) {
    if (this._value === value && source !== "server") {
      // Same value — just close
      this._hide();
      return;
    }

    if (this._stateMode === "server" && source !== "server") {
      // Server mode: notify only, don't apply locally
      this._notifyChange(value, source);
      this._hide();
      return;
    }

    this._value = value;
    this._applySelection();
    this._updateValueDisplay();

    // Sync hidden form input
    syncFormInput(this.el, value);

    this._notifyChange(value, source);

    // Close after selection (unless server-driven)
    if (source !== "server") {
      this._hide();
    }
  },

  _applySelection() {
    const allItems = this._content.querySelectorAll("[data-slot='select-item']");
    allItems.forEach((item) => {
      const selected = item.dataset.val === this._value;
      item.setAttribute("aria-selected", String(selected));
      item.dataset.state = selected ? "checked" : "unchecked";
    });
  },

  _updateValueDisplay() {
    const valueEl = this.el.querySelector("[data-slot='select-value']");
    if (!valueEl) return;

    if (!this._value) {
      // Show placeholder
      valueEl.dataset.placeholder = "";
      const placeholder = valueEl.getAttribute("data-placeholder-text") || "";
      valueEl.textContent = placeholder;
      return;
    }

    // Find the selected item and read its text
    const selectedItem = this._content.querySelector(
      `[data-slot='select-item'][data-val="${CSS.escape(this._value)}"]`
    );
    if (selectedItem) {
      // Get the text content excluding the check icon span
      const textParts = [];
      selectedItem.childNodes.forEach((node) => {
        if (node.nodeType === Node.TEXT_NODE) {
          textParts.push(node.textContent.trim());
        } else if (
          node.nodeType === Node.ELEMENT_NODE &&
          !node.hasAttribute("data-select-indicator")
        ) {
          textParts.push(node.textContent.trim());
        }
      });
      const text = textParts.filter(Boolean).join(" ");
      valueEl.textContent = text;
      delete valueEl.dataset.placeholder;
    }
  },

  _notifyChange(value, source) {
    if (source === "server") return;
    if (this._stateMode === "client") return;

    notifyServer(this, this._onValueChange, {
      id: this.el.id,
      value: value,
    });
  },

  // ── Positioning ────────────────────────────────────────────────────

  async _position() {
    const side = this._content.dataset.side || "bottom";
    const align = this._content.dataset.align || "start";
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

    // Set min-width to match trigger width
    const triggerWidth = this._trigger.getBoundingClientRect().width;

    Object.assign(this._content.style, {
      position: "fixed",
      left: `${x}px`,
      top: `${y}px`,
      minWidth: `${triggerWidth}px`,
    });

    // Update data-side/data-align to reflect actual placement
    const actual = fromPlacement(actualPlacement);
    this._content.dataset.side = actual.side;
    this._content.dataset.align = actual.align;
  },

  // ── Lifecycle ──────────────────────────────────────────────────────

  updated() {
    this._readConfig();

    // Re-sync server value
    if (this._stateMode === "server") {
      const serverValue = this.el.dataset.value || null;
      if (serverValue !== this._value) {
        this._value = serverValue;
        this._applySelection();
        this._updateValueDisplay();
      }
    }

    if (this._open && !this._transitioning) {
      // LiveView patch may re-add hidden and strip inline styles — restore them
      this._content.removeAttribute("hidden");
      this.el.dataset.state = "open";
      this._content.dataset.state = "open";
      this._triggerButton.setAttribute("aria-expanded", "true");
      this._position();
    }
  },

  destroyed() {
    clearTimeout(this._hideTimer);
    clearTimeout(this._typeaheadTimer);

    if (this._cleanupAutoUpdate) {
      this._cleanupAutoUpdate();
      this._cleanupAutoUpdate = null;
    }

    this._trigger.removeEventListener("click", this._onTriggerClick);
    this._triggerButton.removeEventListener("keydown", this._onTriggerKeydown);
    document.removeEventListener("click", this._onDocumentClick, true);
    this._content.removeEventListener("keydown", this._onContentKeydown);
    this._content.removeEventListener("click", this._onContentClick);
    this.el.removeEventListener("phx-shadcn:show", this._onShowEvent);
    this.el.removeEventListener("phx-shadcn:hide", this._onHideEvent);
  },
};

export { Select as PhxShadcnSelect };
export default Select;
