/**
 * Switch hook — a two-state slider control (checked/unchecked).
 *
 * Mounts directly on the <button role="switch"> element.
 * Supports 3 state modes: client, hybrid, server.
 *
 * Config via data attributes on the button:
 *   data-state-mode="client|hybrid|server"
 *   data-state="checked|unchecked"
 *   data-default-checked="true|false"
 *   data-on-checked-change="event_name|JS_struct"
 *
 * External JS API — inbound CustomEvents:
 *   phx-shadcn:check    — check the switch
 *   phx-shadcn:uncheck  — uncheck the switch
 *   phx-shadcn:toggle   — flip the switch
 *
 * Outbound CustomEvents (bubbles: false):
 *   phx-shadcn:checked   — { id, checked: true }
 *   phx-shadcn:unchecked — { id, checked: false }
 */
import { notifyServer, listenForCommands, syncFormInput } from "./event-bridge.js";

const Switch = {
  mounted() {
    this.stateMode = this.el.dataset.stateMode || "client";
    this.eventCallback = this.el.dataset.onCheckedChange || null;

    // Initialize state for client/hybrid modes (skip form sync — server already set the value)
    this._initializing = true;
    if (this.stateMode !== "server") {
      const defaultChecked = this.el.dataset.defaultChecked === "true";
      this._setChecked(defaultChecked);
    }
    this._initializing = false;

    // Click handler
    this._onClick = (e) => {
      if (this.el.disabled) return;
      this._toggle("user");
    };
    this.el.addEventListener("click", this._onClick);

    // Server->client push_event commands
    listenForCommands(this, ({ command }) => {
      switch (command) {
        case "check":
          this._setChecked(true, "server");
          break;
        case "uncheck":
          this._setChecked(false, "server");
          break;
        case "toggle":
          this._toggle("server");
          break;
      }
    });

    // External JS API — inbound CustomEvents
    this._onCustomCheck = () => this._setChecked(true, "external");
    this._onCustomUncheck = () => this._setChecked(false, "external");
    this._onCustomToggle = () => this._toggle("external");
    this.el.addEventListener("phx-shadcn:check", this._onCustomCheck);
    this.el.addEventListener("phx-shadcn:uncheck", this._onCustomUncheck);
    this.el.addEventListener("phx-shadcn:toggle", this._onCustomToggle);
  },

  updated() {
    this.stateMode = this.el.dataset.stateMode || "client";
    this.eventCallback = this.el.dataset.onCheckedChange || null;

    if (this.stateMode === "server") {
      const checked = this.el.dataset.state === "checked";
      requestAnimationFrame(() => this._applyState(checked));
    }
  },

  destroyed() {
    this.el.removeEventListener("click", this._onClick);
    this.el.removeEventListener("phx-shadcn:check", this._onCustomCheck);
    this.el.removeEventListener("phx-shadcn:uncheck", this._onCustomUncheck);
    this.el.removeEventListener("phx-shadcn:toggle", this._onCustomToggle);
  },

  // --- Core ---

  _toggle(source) {
    const currentlyChecked = this.el.dataset.state === "checked";
    const newChecked = !currentlyChecked;

    if (this.stateMode === "server" && source !== "server") {
      this._notifyChange(newChecked, source);
      return;
    }

    this._setChecked(newChecked, source);
  },

  _setChecked(checked, source) {
    if (this.stateMode === "server" && source !== "server") {
      this._notifyChange(checked, source);
      return;
    }

    this._applyState(checked);
    this._dispatchOutbound(checked);

    if (source && source !== "server") {
      this._notifyChange(checked, source);
    }
  },

  _applyState(checked) {
    const state = checked ? "checked" : "unchecked";
    this.el.dataset.state = state;
    this.el.setAttribute("aria-checked", String(checked));

    // Sync thumb data-state
    const thumb = this.el.querySelector("[data-slot='switch-thumb']");
    if (thumb) thumb.dataset.state = state;

    // Sync hidden input for form integration (skip during mount — server already set the value)
    if (!this._initializing) {
      const checkedValue = this.el.dataset.checkedValue || "on";
      syncFormInput(this.el, checked ? checkedValue : "");
    }
  },

  // --- Notification ---

  _notifyChange(checked, source) {
    if (source === "server") return;
    if (this.stateMode === "client") return;

    const payload = {
      id: this.el.id,
      checked: checked
    };

    notifyServer(this, this.eventCallback, payload);
  },

  _dispatchOutbound(checked) {
    const eventName = checked ? "phx-shadcn:checked" : "phx-shadcn:unchecked";
    this.el.dispatchEvent(new CustomEvent(eventName, {
      detail: { id: this.el.id, checked: checked },
      bubbles: false
    }));
  }
};

export { Switch as PhxShadcnSwitch };
export default Switch;
