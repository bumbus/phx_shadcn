/**
 * InputOTP hook — segmented code input (OTP, PIN, verification tokens).
 *
 * A single native <input> is positioned transparently over visual slot divs.
 * All keyboard, paste, and autocomplete events go to this native input.
 * The hook reads the input value on each `input` event and distributes
 * characters to slots.
 *
 * Config via data attributes on the root element:
 *   data-state-mode="client|hybrid|server"
 *   data-max-length="6"
 *   data-value="123456"           (server mode)
 *   data-default-value="123"      (client/hybrid: initial value)
 *   data-pattern="\d"             (per-char regex, default: digits)
 *   data-on-value-change="event|JS"
 *   data-on-complete="event|JS"
 *   data-disabled="true"
 *
 * Children found by:
 *   [data-slot='input-otp-native']  — the transparent native input
 *   [data-slot='input-otp-hidden']  — hidden form input (for phx-change)
 *   [data-slot-index]               — visual slot divs
 */
import { notifyServer, listenForCommands, syncFormInput } from "./event-bridge.js";

// ── Pattern resolution ─────────────────────────────────────────────

function resolvePattern(str) {
  if (!str || str === "\\d") return /^\d$/;
  if (str === "[a-zA-Z0-9]") return /^[a-zA-Z0-9]$/;
  try {
    return new RegExp("^" + str + "$");
  } catch {
    return /^\d$/;
  }
}

// ── Hook ───────────────────────────────────────────────────────────

const InputOTP = {
  mounted() {
    this._nativeInput = this.el.querySelector("[data-slot='input-otp-native']");
    this._slots = [];
    this._currentValue = "";
    this._focused = false;
    this._initializing = true;

    this._readConfig();
    this._collectSlots();

    // Init value
    const initial =
      this._stateMode === "server"
        ? this.el.dataset.value || ""
        : this.el.dataset.defaultValue || "";

    if (initial) {
      this._currentValue = this._filterValue(initial);
      this._nativeInput.value = this._currentValue;
    }

    this._applyState();
    this._initializing = false;

    // ── Native input events ─────────────────────────────────────────
    this._onInput = () => {
      const raw = this._nativeInput.value;
      const filtered = this._filterValue(raw);
      this._setValue(filtered, "user");
    };
    this._nativeInput.addEventListener("input", this._onInput);

    this._onFocus = () => {
      this._focused = true;
      this._applyState();
    };
    this._nativeInput.addEventListener("focus", this._onFocus);

    this._onBlur = () => {
      this._focused = false;
      this._clearActive();
    };
    this._nativeInput.addEventListener("blur", this._onBlur);

    // ── Click on root focuses native input ──────────────────────────
    this._onClick = () => {
      if (!this._disabled) {
        this._nativeInput.focus();
      }
    };
    this.el.addEventListener("click", this._onClick);

    // ── Server→client commands ──────────────────────────────────────
    listenForCommands(this, ({ command, value }) => {
      if (command === "set") {
        const filtered = this._filterValue(value || "");
        this._setValue(filtered, "server");
      }
    });
  },

  _readConfig() {
    this._stateMode = this.el.dataset.stateMode || "client";
    this._maxLength = parseInt(this.el.dataset.maxLength, 10) || 6;
    this._pattern = resolvePattern(this.el.dataset.pattern);
    this._onValueChange = this.el.dataset.onValueChange || null;
    this._onComplete = this.el.dataset.onComplete || null;
    this._disabled = this.el.dataset.disabled === "true";
  },

  _collectSlots() {
    this._slots = Array.from(this.el.querySelectorAll("[data-slot-index]")).sort(
      (a, b) => parseInt(a.dataset.slotIndex, 10) - parseInt(b.dataset.slotIndex, 10)
    );
  },

  // ── Value filtering ───────────────────────────────────────────────

  _filterValue(str) {
    let result = "";
    for (const ch of str) {
      if (this._pattern.test(ch) && result.length < this._maxLength) {
        result += ch;
      }
    }
    return result;
  },

  // ── Set value with 3-mode logic ───────────────────────────────────

  _setValue(value, source) {
    const prevValue = this._currentValue;

    if (this._stateMode === "server" && source !== "server") {
      // Server mode: notify only, don't update locally
      this._nativeInput.value = this._currentValue;
      this._notifyChange(value, source);
      if (value.length === this._maxLength && value !== prevValue) {
        this._notifyComplete(value, source);
      }
      return;
    }

    this._currentValue = value;
    this._nativeInput.value = value;
    this._applyState();

    // Sync hidden form input (skip during init)
    if (!this._initializing) {
      syncFormInput(this.el, value);
    }

    // Notify server (hybrid/server modes)
    if (!this._initializing) {
      this._notifyChange(value, source);
    }

    // Complete callback
    if (value.length === this._maxLength && value !== prevValue) {
      this._notifyComplete(value, source);
    }
  },

  // ── Apply visual state to slots ───────────────────────────────────

  _applyState() {
    const value = this._currentValue;
    const caretIndex = value.length;

    for (const slot of this._slots) {
      const idx = parseInt(slot.dataset.slotIndex, 10);
      const charEl = slot.querySelector("[data-slot='input-otp-slot-char']");
      const caretEl = slot.querySelector("[data-slot='input-otp-caret']");
      const char = value[idx] || "";

      if (charEl) charEl.textContent = char;

      const isActive = this._focused && idx === caretIndex && caretIndex < this._maxLength;
      slot.dataset.active = isActive ? "true" : "false";

      if (caretEl) {
        caretEl.style.display = isActive ? "block" : "none";
      }
    }
  },

  _clearActive() {
    for (const slot of this._slots) {
      slot.dataset.active = "false";
      const caretEl = slot.querySelector("[data-slot='input-otp-caret']");
      if (caretEl) caretEl.style.display = "none";
    }
  },

  // ── Notifications ─────────────────────────────────────────────────

  _notifyChange(value, source) {
    if (source === "server") return;
    if (this._stateMode === "client") return;

    notifyServer(this, this._onValueChange, {
      id: this.el.id,
      value: value,
    });
  },

  _notifyComplete(value, source) {
    if (source === "server") return;

    notifyServer(this, this._onComplete, {
      id: this.el.id,
      value: value,
    });
  },

  // ── Lifecycle ─────────────────────────────────────────────────────

  updated() {
    this._readConfig();
    this._collectSlots();

    if (this._stateMode === "server") {
      const serverValue = this.el.dataset.value || "";
      if (serverValue !== this._currentValue) {
        this._currentValue = this._filterValue(serverValue);
        this._nativeInput.value = this._currentValue;
        this._applyState();
      }
    } else {
      // Client/hybrid: restore value after LV patch
      this._nativeInput.value = this._currentValue;
      this._applyState();
    }
  },

  destroyed() {
    this._nativeInput.removeEventListener("input", this._onInput);
    this._nativeInput.removeEventListener("focus", this._onFocus);
    this._nativeInput.removeEventListener("blur", this._onBlur);
    this.el.removeEventListener("click", this._onClick);
  },
};

export { InputOTP as PhxShadcnInputOTP };
export default InputOTP;
