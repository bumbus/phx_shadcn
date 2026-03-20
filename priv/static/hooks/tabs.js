/**
 * Tabs hook — manages single tab selection with keyboard navigation.
 *
 * Mounts on the root <div> element. Uses event delegation for trigger clicks.
 * Supports 3 state modes: client, hybrid, server.
 *
 * Config via data attributes on the root:
 *   data-state-mode="client|hybrid|server"
 *   data-value="tab-name" (server mode: current active tab)
 *   data-default-value="tab-name" (client/hybrid: initial active tab)
 *   data-on-value-change="event_name|JS_struct"
 *   data-activation-mode="automatic|manual"
 *   data-orientation="horizontal|vertical"
 *
 * External JS API — inbound CustomEvents:
 *   phx-shadcn:activate — { detail: { value: "tab-name" } }
 *
 * Outbound CustomEvents (bubbles: false):
 *   phx-shadcn:tab-change — { id, value }
 *
 * Server push: phx_shadcn:command with command: "activate", value: "tab-name"
 */
import { notifyServer, listenForCommands } from "./event-bridge.js";

const TRIGGER_SEL = "[data-slot=tabs-trigger]";
const CONTENT_SEL = "[data-slot=tabs-content]";

const Tabs = {
  mounted() {
    this.stateMode = this.el.dataset.stateMode || "client";
    this.eventCallback = this.el.dataset.onValueChange || null;
    this.activationMode = this.el.dataset.activationMode || "automatic";
    this.orientation = this.el.dataset.orientation || "horizontal";

    // Determine initial value
    const initial = this.stateMode === "server"
      ? this.el.dataset.value
      : (this.el.dataset.defaultValue || null);

    // Apply initial state (use first enabled trigger if no initial value)
    this._initializing = true;
    const startValue = initial || this._firstEnabledTriggerValue();
    if (startValue) {
      this.activeValue = startValue;
      this._applyState();
    }
    this._initializing = false;

    // Click delegation
    this._onClick = (e) => {
      const trigger = e.target.closest(TRIGGER_SEL);
      if (!trigger) return;
      if (trigger.dataset.disabled === "true") return;

      // For patch/navigate links, let the link navigate naturally.
      // The hook will pick up the change in updated().
      if (trigger.tagName === "A") {
        // Still activate visually for instant feedback
        this._activate(trigger.dataset.value, "user");
        return;
      }

      e.preventDefault();
      this._activate(trigger.dataset.value, "user");
    };
    this.el.addEventListener("click", this._onClick);

    // Keyboard navigation
    this._onKeydown = (e) => {
      const trigger = e.target.closest(TRIGGER_SEL);
      if (!trigger) return;
      this._handleKeydown(e, trigger);
    };
    this.el.addEventListener("keydown", this._onKeydown);

    // Server->client push_event commands
    listenForCommands(this, ({ command, value }) => {
      if (command === "activate" && value) {
        this._activate(value, "server");
      }
    });

    // External JS API — inbound CustomEvents
    this._onCustomActivate = (e) => {
      const value = e.detail && e.detail.value;
      if (value) this._activate(value, "external");
    };
    this.el.addEventListener("phx-shadcn:activate", this._onCustomActivate);
  },

  updated() {
    this.stateMode = this.el.dataset.stateMode || "client";
    this.eventCallback = this.el.dataset.onValueChange || null;
    this.activationMode = this.el.dataset.activationMode || "automatic";
    this.orientation = this.el.dataset.orientation || "horizontal";

    if (this.stateMode === "server") {
      const serverValue = this.el.dataset.value;
      if (serverValue) {
        this.activeValue = serverValue;
      }
    }

    // Always re-apply after morphdom — it resets data-state on triggers
    requestAnimationFrame(() => this._applyState());
  },

  destroyed() {
    this.el.removeEventListener("click", this._onClick);
    this.el.removeEventListener("keydown", this._onKeydown);
    this.el.removeEventListener("phx-shadcn:activate", this._onCustomActivate);
  },

  // --- Core activation ---

  _activate(value, source) {
    if (value === this.activeValue) return;

    // Server mode + non-server source → notify only, don't change state
    if (this.stateMode === "server" && source !== "server") {
      this._notifyChange(value, source);
      return;
    }

    this.activeValue = value;
    this._applyState();
    this._notifyChange(value, source);
    this._dispatchOutbound(value);
  },

  // --- State application ---

  _applyState() {
    const triggers = this.el.querySelectorAll(TRIGGER_SEL);
    triggers.forEach(trigger => {
      const isActive = trigger.dataset.value === this.activeValue;
      trigger.dataset.state = isActive ? "active" : "inactive";
      trigger.setAttribute("aria-selected", String(isActive));
      trigger.setAttribute("tabindex", isActive ? "0" : "-1");
    });

    // Toggle content panels — gracefully handles panels not in DOM (server mode uses :if)
    const panels = this.el.querySelectorAll(CONTENT_SEL);
    panels.forEach(panel => {
      const isActive = panel.dataset.value === this.activeValue;
      panel.dataset.state = isActive ? "active" : "inactive";
      if (isActive) {
        panel.removeAttribute("hidden");
      } else {
        panel.setAttribute("hidden", "");
      }
    });
  },

  // --- Keyboard navigation ---

  _handleKeydown(e, currentTrigger) {
    const triggers = Array.from(this.el.querySelectorAll(TRIGGER_SEL))
      .filter(t => t.dataset.disabled !== "true");

    if (triggers.length === 0) return;

    const currentIndex = triggers.indexOf(currentTrigger);
    const isHorizontal = this.orientation === "horizontal";

    let nextIndex = -1;

    switch (e.key) {
      case "ArrowRight":
        if (isHorizontal) {
          nextIndex = (currentIndex + 1) % triggers.length;
        }
        break;
      case "ArrowLeft":
        if (isHorizontal) {
          nextIndex = (currentIndex - 1 + triggers.length) % triggers.length;
        }
        break;
      case "ArrowDown":
        if (!isHorizontal) {
          nextIndex = (currentIndex + 1) % triggers.length;
        }
        break;
      case "ArrowUp":
        if (!isHorizontal) {
          nextIndex = (currentIndex - 1 + triggers.length) % triggers.length;
        }
        break;
      case "Home":
        nextIndex = 0;
        break;
      case "End":
        nextIndex = triggers.length - 1;
        break;
      case "Enter":
      case " ":
        if (this.activationMode === "manual") {
          e.preventDefault();
          this._activate(currentTrigger.dataset.value, "user");
        }
        return;
      default:
        return;
    }

    if (nextIndex >= 0) {
      e.preventDefault();
      const nextTrigger = triggers[nextIndex];
      nextTrigger.focus();

      if (this.activationMode === "automatic") {
        this._activate(nextTrigger.dataset.value, "user");
      }
    }
  },

  // --- Helpers ---

  _firstEnabledTriggerValue() {
    const trigger = this.el.querySelector(TRIGGER_SEL + ":not([data-disabled=true])");
    return trigger ? trigger.dataset.value : null;
  },

  // --- Notification ---

  _notifyChange(value, source) {
    if (source === "server") return;
    if (this.stateMode === "client") return;

    notifyServer(this, this.eventCallback, {
      id: this.el.id,
      value: value
    });
  },

  _dispatchOutbound(value) {
    this.el.dispatchEvent(new CustomEvent("phx-shadcn:tab-change", {
      detail: { id: this.el.id, value: value },
      bubbles: false
    }));
  }
};

export { Tabs as PhxShadcnTabs };
export default Tabs;
