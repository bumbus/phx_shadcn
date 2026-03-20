/**
 * ToggleGroup hook — manages single/multiple selection across toggle buttons.
 *
 * Mounts on the group <div> element. Uses event delegation for item clicks.
 * Supports 3 state modes: client, hybrid, server.
 *
 * Config via data attributes on the group:
 *   data-type="single|multiple"
 *   data-state-mode="client|hybrid|server"
 *   data-value="val1,val2" (server mode: current selected values)
 *   data-default-value="val1,val2" (client/hybrid: initial selected values)
 *   data-on-value-change="event_name|JS_struct"
 *
 * External JS API — inbound CustomEvents:
 *   phx-shadcn:select   — { detail: { value: "x" } }
 *   phx-shadcn:deselect — { detail: { value: "x" } }
 *   phx-shadcn:toggle   — { detail: { value: "x" } }
 *   phx-shadcn:set      — { detail: { value: ["x","y"] } } (full replacement)
 *
 * Outbound CustomEvents (bubbles: false):
 *   phx-shadcn:selected   — { id, value, action: "select" }
 *   phx-shadcn:deselected — { id, value, action: "deselect" }
 */
import { notifyServer, listenForCommands, syncFormInput } from "./event-bridge.js";

const ITEM_SEL = "[data-slot=toggle-group-item]";

const ToggleGroup = {
  mounted() {
    this.type = this.el.dataset.type || "single";
    this.stateMode = this.el.dataset.stateMode || "client";
    this.eventCallback = this.el.dataset.onValueChange || null;

    // Parse initial selected set
    this.selectedSet = new Set();
    const initial = this.stateMode === "server"
      ? this.el.dataset.value
      : this.el.dataset.defaultValue;

    if (initial) {
      initial.split(",").filter(Boolean).forEach(v => this.selectedSet.add(v));
    }

    // Apply initial state (skip form sync — hidden input already has the right value)
    this._initializing = true;
    this._applyState();
    this._initializing = false;

    // Click delegation
    this._onClick = (e) => {
      const item = e.target.closest(ITEM_SEL);
      if (!item) return;
      if (item.dataset.disabled === "true") return;

      e.preventDefault();
      this._toggleItem(item.dataset.value, "user");
    };
    this.el.addEventListener("click", this._onClick);

    // Server->client push_event commands
    listenForCommands(this, ({ command, value }) => {
      switch (command) {
        case "select":
          this._select(value, "server");
          break;
        case "deselect":
          this._deselect(value, "server");
          break;
        case "toggle":
          this._toggleItem(value, "server");
          break;
        case "set": {
          const values = Array.isArray(value) ? value : String(value).split(",").filter(Boolean);
          this.selectedSet = new Set(values);
          this._applyState();
          break;
        }
      }
    });

    // External JS API — inbound CustomEvents
    this._onCustomSelect = (e) => {
      const value = e.detail && e.detail.value;
      if (value) this._select(value, "external");
    };
    this._onCustomDeselect = (e) => {
      const value = e.detail && e.detail.value;
      if (value) this._deselect(value, "external");
    };
    this._onCustomToggle = (e) => {
      const value = e.detail && e.detail.value;
      if (value) this._toggleItem(value, "external");
    };
    this._onCustomSet = (e) => {
      const value = e.detail && e.detail.value;
      if (value) {
        const values = Array.isArray(value) ? value : String(value).split(",").filter(Boolean);
        this.selectedSet = new Set(values);
        this._applyState();
      }
    };
    this.el.addEventListener("phx-shadcn:select", this._onCustomSelect);
    this.el.addEventListener("phx-shadcn:deselect", this._onCustomDeselect);
    this.el.addEventListener("phx-shadcn:toggle", this._onCustomToggle);
    this.el.addEventListener("phx-shadcn:set", this._onCustomSet);
  },

  updated() {
    this.type = this.el.dataset.type || "single";
    this.stateMode = this.el.dataset.stateMode || "client";
    this.eventCallback = this.el.dataset.onValueChange || null;

    if (this.stateMode === "server") {
      const serverValue = this.el.dataset.value || "";
      this.selectedSet = new Set(serverValue.split(",").filter(Boolean));
      requestAnimationFrame(() => this._applyState());
    }
  },

  destroyed() {
    this.el.removeEventListener("click", this._onClick);
    this.el.removeEventListener("phx-shadcn:select", this._onCustomSelect);
    this.el.removeEventListener("phx-shadcn:deselect", this._onCustomDeselect);
    this.el.removeEventListener("phx-shadcn:toggle", this._onCustomToggle);
    this.el.removeEventListener("phx-shadcn:set", this._onCustomSet);
  },

  // --- Core state transitions ---

  _select(value, source) {
    if (this.selectedSet.has(value)) return;

    if (this.stateMode === "server" && source !== "server") {
      this._notifyChange(value, "select", source);
      return;
    }

    if (this.type === "single") {
      this.selectedSet.clear();
    }

    this.selectedSet.add(value);
    this._applyState();
    this._notifyChange(value, "select", source);
    this._dispatchOutbound("phx-shadcn:selected", value, "select");
  },

  _deselect(value, source) {
    if (!this.selectedSet.has(value)) return;

    if (this.stateMode === "server" && source !== "server") {
      this._notifyChange(value, "deselect", source);
      return;
    }

    this.selectedSet.delete(value);
    this._applyState();
    this._notifyChange(value, "deselect", source);
    this._dispatchOutbound("phx-shadcn:deselected", value, "deselect");
  },

  _toggleItem(value, source) {
    if (this.selectedSet.has(value)) {
      this._deselect(value, source);
    } else {
      this._select(value, source);
    }
  },

  // --- State application ---

  _applyState() {
    const items = this.el.querySelectorAll(ITEM_SEL);
    items.forEach(item => {
      const value = item.dataset.value;
      const selected = this.selectedSet.has(value);
      item.dataset.state = selected ? "on" : "off";
      item.setAttribute("aria-pressed", String(selected));
    });

    // Sync hidden input for form integration (skip during mount — server already set the value)
    if (!this._initializing) {
      syncFormInput(this.el, [...this.selectedSet].join(","));
    }
  },

  // --- Notification ---

  _notifyChange(value, action, source) {
    if (source === "server") return;
    if (this.stateMode === "client") return;

    const payload = {
      id: this.el.id,
      value: this.type === "multiple" ? [...this.selectedSet] : value,
      action: action
    };

    notifyServer(this, this.eventCallback, payload);
  },

  _dispatchOutbound(eventName, value, action) {
    this.el.dispatchEvent(new CustomEvent(eventName, {
      detail: { id: this.el.id, value: value, action: action },
      bubbles: false
    }));
  }
};

export { ToggleGroup as PhxShadcnToggleGroup };
export default ToggleGroup;
