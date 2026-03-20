/**
 * RadioGroup hook — manages single selection across radio buttons with keyboard nav.
 *
 * Mounts on the group <div> element. Uses event delegation for item clicks.
 * Supports 3 state modes: client, hybrid, server.
 * Inlines roving focus keyboard nav (arrow keys, Home/End, wrapping).
 *
 * Config via data attributes on the group:
 *   data-state-mode="client|hybrid|server"
 *   data-value="val" (server mode: current selected value)
 *   data-default-value="val" (client/hybrid: initial selected value)
 *   data-on-value-change="event_name|JS_struct"
 *   data-orientation="vertical|horizontal"
 *
 * External JS API — inbound CustomEvents:
 *   phx-shadcn:select — { detail: { value: "x" } }
 *   phx-shadcn:set    — { detail: { value: "x" } } (alias for select)
 *
 * Outbound CustomEvents (bubbles: false):
 *   phx-shadcn:selected — { id, value, action: "select" }
 */
import { notifyServer, listenForCommands, syncFormInput } from "./event-bridge.js";

const ITEM_SEL = "[data-slot=radio-group-item]";

function getEnabledItems(el) {
  return [...el.querySelectorAll(ITEM_SEL)].filter(
    (item) => item.dataset.disabled !== "true" && !item.disabled
  );
}

const RadioGroup = {
  mounted() {
    this.stateMode = this.el.dataset.stateMode || "client";
    this.eventCallback = this.el.dataset.onValueChange || null;
    this.orientation = this.el.dataset.orientation || "vertical";

    // Parse initial selected value
    this.selectedValue = null;
    const initial =
      this.stateMode === "server"
        ? this.el.dataset.value
        : this.el.dataset.defaultValue;

    if (initial) {
      this.selectedValue = initial;
    }

    // Apply initial state (skip form sync — hidden input already has the right value)
    this._initializing = true;
    this._applyState();
    this._initializing = false;

    // Click delegation
    this._onClick = (e) => {
      const item = e.target.closest(ITEM_SEL);
      if (!item) return;
      if (item.dataset.disabled === "true" || item.disabled) return;

      e.preventDefault();
      this._select(item.dataset.value, "user");
    };
    this.el.addEventListener("click", this._onClick);

    // Keyboard nav (roving focus inlined)
    this._onKeydown = (e) => {
      const item = e.target.closest(ITEM_SEL);
      if (!item) return;

      const isVertical = this.orientation === "vertical";
      const prev = isVertical ? "ArrowUp" : "ArrowLeft";
      const next = isVertical ? "ArrowDown" : "ArrowRight";

      let target = null;

      if (e.key === prev || e.key === "ArrowLeft" || e.key === "ArrowUp") {
        e.preventDefault();
        target = this._adjacentItem(item, -1);
      } else if (
        e.key === next ||
        e.key === "ArrowRight" ||
        e.key === "ArrowDown"
      ) {
        e.preventDefault();
        target = this._adjacentItem(item, 1);
      } else if (e.key === "Home") {
        e.preventDefault();
        const items = getEnabledItems(this.el);
        target = items[0] || null;
      } else if (e.key === "End") {
        e.preventDefault();
        const items = getEnabledItems(this.el);
        target = items[items.length - 1] || null;
      } else if (e.key === " ") {
        // Space selects the focused item (standard radio behavior)
        e.preventDefault();
        this._select(item.dataset.value, "user");
        return;
      }

      if (target) {
        target.focus();
        // Radio groups select on focus by default (WAI-ARIA pattern)
        this._select(target.dataset.value, "user");
      }
    };
    this.el.addEventListener("keydown", this._onKeydown);

    // Server->client push_event commands
    listenForCommands(this, ({ command, value }) => {
      switch (command) {
        case "select":
        case "set":
          this._select(value, "server");
          break;
      }
    });

    // External JS API — inbound CustomEvents
    this._onCustomSelect = (e) => {
      const value = e.detail && e.detail.value;
      if (value) this._select(value, "external");
    };
    this._onCustomSet = (e) => {
      const value = e.detail && e.detail.value;
      if (value) this._select(value, "external");
    };
    this.el.addEventListener("phx-shadcn:select", this._onCustomSelect);
    this.el.addEventListener("phx-shadcn:set", this._onCustomSet);
  },

  updated() {
    this.stateMode = this.el.dataset.stateMode || "client";
    this.eventCallback = this.el.dataset.onValueChange || null;
    this.orientation = this.el.dataset.orientation || "vertical";

    if (this.stateMode === "server") {
      this.selectedValue = this.el.dataset.value || null;
      requestAnimationFrame(() => this._applyState());
    }
  },

  destroyed() {
    this.el.removeEventListener("click", this._onClick);
    this.el.removeEventListener("keydown", this._onKeydown);
    this.el.removeEventListener("phx-shadcn:select", this._onCustomSelect);
    this.el.removeEventListener("phx-shadcn:set", this._onCustomSet);
  },

  // --- Core state transitions ---

  _select(value, source) {
    if (this.selectedValue === value) return;

    if (this.stateMode === "server" && source !== "server") {
      this._notifyChange(value, source);
      return;
    }

    this.selectedValue = value;
    this._applyState();
    this._notifyChange(value, source);
    this._dispatchOutbound("phx-shadcn:selected", value);
  },

  // --- Roving focus helpers ---

  _adjacentItem(current, direction) {
    const items = getEnabledItems(this.el);
    const idx = items.indexOf(current);
    if (idx === -1) return items[0] || null;
    const next = (idx + direction + items.length) % items.length;
    return items[next];
  },

  // --- State application ---

  _applyState() {
    const items = this.el.querySelectorAll(ITEM_SEL);
    items.forEach((item) => {
      const value = item.dataset.value;
      const checked = value === this.selectedValue;
      item.dataset.state = checked ? "checked" : "unchecked";
      item.setAttribute("aria-checked", String(checked));
      // Roving tabindex: selected item gets 0, rest get -1
      item.setAttribute("tabindex", "-1");
      // Show/hide the circle indicator
      const circle = item.querySelector("[data-radio-circle]");
      if (circle) circle.style.display = checked ? "" : "none";
    });

    // Set tabindex=0 on the selected item, or first enabled item
    const selected = this.selectedValue
      ? this.el.querySelector(
          `${ITEM_SEL}[data-value="${CSS.escape(this.selectedValue)}"]`
        )
      : null;

    if (selected) {
      selected.setAttribute("tabindex", "0");
    } else {
      const first = getEnabledItems(this.el)[0];
      if (first) first.setAttribute("tabindex", "0");
    }

    // Sync hidden input for form integration (skip during mount)
    if (!this._initializing) {
      syncFormInput(this.el, this.selectedValue || "");
    }
  },

  // --- Notification ---

  _notifyChange(value, source) {
    if (source === "server") return;
    if (this.stateMode === "client") return;

    const payload = {
      id: this.el.id,
      value: value,
    };

    notifyServer(this, this.eventCallback, payload);
  },

  _dispatchOutbound(eventName, value) {
    this.el.dispatchEvent(
      new CustomEvent(eventName, {
        detail: { id: this.el.id, value: value, action: "select" },
        bubbles: false,
      })
    );
  },
};

export { RadioGroup as PhxShadcnRadioGroup };
export default RadioGroup;
