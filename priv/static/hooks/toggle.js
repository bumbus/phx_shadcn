/**
 * Toggle hook — a two-state button (pressed/unpressed).
 *
 * Mounts directly on the <button> element.
 * Supports 3 state modes: client, hybrid, server.
 *
 * Config via data attributes on the button:
 *   data-state-mode="client|hybrid|server"
 *   data-state="on|off"
 *   data-default-pressed="true|false"
 *   data-on-pressed-change="event_name|JS_struct"
 *
 * External JS API — inbound CustomEvents:
 *   phx-shadcn:press    — press the toggle
 *   phx-shadcn:unpress  — unpress the toggle
 *   phx-shadcn:toggle   — flip the toggle
 *
 * Outbound CustomEvents (bubbles: false):
 *   phx-shadcn:pressed   — { id, pressed: true }
 *   phx-shadcn:unpressed — { id, pressed: false }
 */
import { notifyServer, listenForCommands, syncFormInput } from "./event-bridge.js";

const Toggle = {
  mounted() {
    this.stateMode = this.el.dataset.stateMode || "client";
    this.eventCallback = this.el.dataset.onPressedChange || null;

    // Initialize state for client/hybrid modes (skip form sync — server already set the value)
    this._initializing = true;
    if (this.stateMode !== "server") {
      const defaultPressed = this.el.dataset.defaultPressed === "true";
      this._setPressed(defaultPressed);
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
        case "press":
          this._setPressed(true, "server");
          break;
        case "unpress":
          this._setPressed(false, "server");
          break;
        case "toggle":
          this._toggle("server");
          break;
      }
    });

    // External JS API — inbound CustomEvents
    this._onCustomPress = () => this._setPressed(true, "external");
    this._onCustomUnpress = () => this._setPressed(false, "external");
    this._onCustomToggle = () => this._toggle("external");
    this.el.addEventListener("phx-shadcn:press", this._onCustomPress);
    this.el.addEventListener("phx-shadcn:unpress", this._onCustomUnpress);
    this.el.addEventListener("phx-shadcn:toggle", this._onCustomToggle);
  },

  updated() {
    this.stateMode = this.el.dataset.stateMode || "client";
    this.eventCallback = this.el.dataset.onPressedChange || null;

    if (this.stateMode === "server") {
      const pressed = this.el.dataset.state === "on";
      requestAnimationFrame(() => this._applyState(pressed));
    }
  },

  destroyed() {
    this.el.removeEventListener("click", this._onClick);
    this.el.removeEventListener("phx-shadcn:press", this._onCustomPress);
    this.el.removeEventListener("phx-shadcn:unpress", this._onCustomUnpress);
    this.el.removeEventListener("phx-shadcn:toggle", this._onCustomToggle);
  },

  // --- Core ---

  _toggle(source) {
    const currentlyPressed = this.el.dataset.state === "on";
    const newPressed = !currentlyPressed;

    if (this.stateMode === "server" && source !== "server") {
      this._notifyChange(newPressed, source);
      return;
    }

    this._setPressed(newPressed, source);
  },

  _setPressed(pressed, source) {
    if (this.stateMode === "server" && source !== "server") {
      this._notifyChange(pressed, source);
      return;
    }

    this._applyState(pressed);
    this._dispatchOutbound(pressed);

    if (source && source !== "server") {
      this._notifyChange(pressed, source);
    }
  },

  _applyState(pressed) {
    this.el.dataset.state = pressed ? "on" : "off";
    this.el.setAttribute("aria-pressed", String(pressed));

    // Sync hidden input for form integration (skip during mount — server already set the value)
    if (!this._initializing) {
      const pressedValue = this.el.dataset.pressedValue || "on";
      syncFormInput(this.el, pressed ? pressedValue : "");
    }
  },

  // --- Notification ---

  _notifyChange(pressed, source) {
    if (source === "server") return;
    if (this.stateMode === "client") return;

    const payload = {
      id: this.el.id,
      pressed: pressed
    };

    notifyServer(this, this.eventCallback, payload);
  },

  _dispatchOutbound(pressed) {
    const eventName = pressed ? "phx-shadcn:pressed" : "phx-shadcn:unpressed";
    this.el.dispatchEvent(new CustomEvent(eventName, {
      detail: { id: this.el.id, pressed: pressed },
      bubbles: false
    }));
  }
};

export { Toggle as PhxShadcnToggle };
export default Toggle;
