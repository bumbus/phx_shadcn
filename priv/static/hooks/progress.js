/**
 * Progress hook — a bar showing completion progress of a task.
 *
 * Mounts on the <div role="progressbar"> root element.
 * Supports 3 state modes: client, hybrid, server.
 *
 * Config via data attributes on the root:
 *   data-state-mode="client|hybrid|server"
 *   data-state="indeterminate|loading|complete"
 *   data-value="0..max"
 *   data-max="100"
 *   data-default-value="0..max"
 *   data-on-value-change="event_name|JS_struct"
 *
 * External JS API — inbound CustomEvents:
 *   phx-shadcn:set    — set value { value: N }
 *
 * Outbound CustomEvents (bubbles: false):
 *   phx-shadcn:progress — { id, value, percentage, state }
 */
import { notifyServer, listenForCommands } from "./event-bridge.js";

const Progress = {
  mounted() {
    this.stateMode = this.el.dataset.stateMode || "client";
    this.max = parseInt(this.el.dataset.max, 10) || 100;
    this.eventCallback = this.el.dataset.onValueChange || null;
    this._currentValue = null;

    this._initializing = true;
    if (this.stateMode !== "server") {
      const defaultValue = this.el.dataset.defaultValue;
      if (defaultValue != null && defaultValue !== "") {
        this._setValue(parseInt(defaultValue, 10), "init");
      }
    }
    this._initializing = false;

    // Server->client push_event commands
    listenForCommands(this, ({ command, value }) => {
      switch (command) {
        case "set":
          this._setValue(typeof value === "number" ? value : parseInt(value, 10), "server");
          break;
      }
    });

    // External JS API — inbound CustomEvents
    this._onCustomSet = (e) => {
      const val = e.detail && e.detail.value;
      if (val != null) {
        this._setValue(typeof val === "number" ? val : parseInt(val, 10), "external");
      }
    };
    this.el.addEventListener("phx-shadcn:set", this._onCustomSet);
  },

  updated() {
    this.stateMode = this.el.dataset.stateMode || "client";
    this.max = parseInt(this.el.dataset.max, 10) || 100;
    this.eventCallback = this.el.dataset.onValueChange || null;

    if (this.stateMode === "server") {
      const rawValue = this.el.dataset.value;
      if (rawValue != null && rawValue !== "") {
        const value = parseInt(rawValue, 10);
        requestAnimationFrame(() => this._applyState(value));
      } else {
        // Indeterminate
        requestAnimationFrame(() => this._applyIndeterminate());
      }
    } else if (this._currentValue != null) {
      // Re-apply client/hybrid value after server re-render (e.g. reconnect)
      requestAnimationFrame(() => this._applyState(this._currentValue));
    }
  },

  destroyed() {
    this.el.removeEventListener("phx-shadcn:set", this._onCustomSet);
  },

  // --- Core ---

  _setValue(value, source) {
    if (this.stateMode === "server" && source !== "server") {
      this._notifyChange(value, source);
      return;
    }

    // Clamp to [0, max]
    value = Math.max(0, Math.min(value, this.max));

    this._applyState(value);
    this._dispatchOutbound(value);

    if (source && source !== "server" && source !== "init") {
      this._notifyChange(value, source);
    }
  },

  _applyState(value) {
    this._currentValue = value;
    const percentage = (value / this.max) * 100;
    const state = value >= this.max ? "complete" : "loading";

    this.el.dataset.state = state;
    this.el.dataset.value = String(value);
    this.el.setAttribute("aria-valuenow", String(value));

    const indicator = this.el.querySelector("[data-slot='progress-indicator']");
    if (indicator) {
      indicator.dataset.state = state;
      indicator.style.transform = `translateX(-${100 - percentage}%)`;
      // Remove indeterminate animation class if present
      indicator.classList.remove("animate-progress-indeterminate");
    }
  },

  _applyIndeterminate() {
    this.el.dataset.state = "indeterminate";
    this.el.removeAttribute("aria-valuenow");
    delete this.el.dataset.value;

    const indicator = this.el.querySelector("[data-slot='progress-indicator']");
    if (indicator) {
      indicator.dataset.state = "indeterminate";
      indicator.style.transform = "translateX(-100%)";
      indicator.classList.add("animate-progress-indeterminate");
    }
  },

  // --- Notification ---

  _notifyChange(value, source) {
    if (source === "server") return;
    if (this.stateMode === "client") return;

    const percentage = (value / this.max) * 100;
    const state = value >= this.max ? "complete" : "loading";

    const payload = {
      id: this.el.id,
      value: value,
      percentage: percentage,
      state: state
    };

    notifyServer(this, this.eventCallback, payload);
  },

  _dispatchOutbound(value) {
    const percentage = (value / this.max) * 100;
    const state = value >= this.max ? "complete" : "loading";

    this.el.dispatchEvent(new CustomEvent("phx-shadcn:progress", {
      detail: { id: this.el.id, value: value, percentage: percentage, state: state },
      bubbles: false
    }));
  }
};

export { Progress as PhxShadcnProgress };
export default Progress;
