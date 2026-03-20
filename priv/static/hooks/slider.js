/**
 * Slider hook — a draggable range input with multi-thumb support.
 *
 * Mounts on the root slider element (role="group" for multi, role="slider" for single).
 * Supports 3 state modes: client, hybrid, server.
 * Values can be integers or decimals (e.g. step="0.1", min="0", max="1").
 *
 * Config via data attributes on the root:
 *   data-state-mode="client|hybrid|server"
 *   data-values="25,50"          (comma-separated, multi-thumb)
 *   data-value="50"              (single-thumb compat)
 *   data-default-values="25,50"  (comma-separated, multi-thumb)
 *   data-default-value="50"      (single-thumb compat)
 *   data-min="0"
 *   data-max="100"
 *   data-step="1"
 *   data-orientation="horizontal|vertical"
 *   data-on-value-change="event_name|JS_struct"
 *   data-disabled
 *
 * External JS API — inbound CustomEvents:
 *   phx-shadcn:set — { values: [10, 50] } or { value: N } or { value: N, index: I }
 *
 * Outbound CustomEvents (bubbles: false):
 *   phx-shadcn:value-change — { id, values, percentages, value, percentage }
 */
import { notifyServer, listenForCommands, syncFormInput } from "./event-bridge.js";

function toNum(v) {
  if (typeof v === "number") return v;
  const n = parseFloat(v);
  return isNaN(n) ? 0 : n;
}

const Slider = {
  mounted() {
    this._readConfig();
    this._currentValues = [];
    this._draggingIndex = null;
    this._focusedIndex = 0;
    this._rafPending = false;

    this._initializing = true;
    if (this.stateMode !== "server") {
      const values = this._parseInitialValues();
      if (values.length > 0) {
        this._currentValues = values;
        this._applyState(this._currentValues);
      }
    }
    this._initializing = false;

    // Pointer drag
    this._onPointerDown = this._handlePointerDown.bind(this);
    this._onPointerMove = this._handlePointerMove.bind(this);
    this._onPointerUp = this._handlePointerUp.bind(this);
    this.el.addEventListener("pointerdown", this._onPointerDown);

    // Keyboard — delegate from root, determine thumb from target
    this._onKeyDown = this._handleKeyDown.bind(this);
    this.el.addEventListener("keydown", this._onKeyDown);

    // Server->client push_event commands
    listenForCommands(this, ({ command, value, values, index }) => {
      switch (command) {
        case "set":
          this._handleSetCommand(value, values, index, "server");
          break;
      }
    });

    // External JS API — inbound CustomEvents
    this._onCustomSet = (e) => {
      const detail = e.detail || {};
      this._handleSetCommand(detail.value, detail.values, detail.index, "external");
    };
    this.el.addEventListener("phx-shadcn:set", this._onCustomSet);
  },

  updated() {
    this._readConfig();

    if (this.stateMode === "server") {
      const values = this._parseDataValues();
      if (values.length > 0) {
        requestAnimationFrame(() => this._applyState(values));
      }
    } else if (this._currentValues.length > 0) {
      // Re-apply client/hybrid values after server re-render
      requestAnimationFrame(() => this._applyState(this._currentValues));
    }
  },

  destroyed() {
    this.el.removeEventListener("pointerdown", this._onPointerDown);
    this.el.removeEventListener("keydown", this._onKeyDown);
    this.el.removeEventListener("phx-shadcn:set", this._onCustomSet);
    document.removeEventListener("pointermove", this._onPointerMove);
    document.removeEventListener("pointerup", this._onPointerUp);
  },

  // --- Config ---

  _readConfig() {
    this.stateMode = this.el.dataset.stateMode || "client";
    this.min = toNum(this.el.dataset.min);
    this.max = toNum(this.el.dataset.max) || 100;
    this.step = toNum(this.el.dataset.step) || 1;
    this.orientation = this.el.dataset.orientation || "horizontal";
    this.eventCallback = this.el.dataset.onValueChange || null;
    this.disabled = this.el.dataset.disabled != null;
  },

  // --- Value parsing ---

  _parseInitialValues() {
    // Prefer data-default-values (comma-separated), fall back to data-default-value (scalar)
    const csv = this.el.dataset.defaultValues;
    if (csv != null && csv !== "") {
      return csv.split(",").map((s) => toNum(s.trim()));
    }
    const scalar = this.el.dataset.defaultValue;
    if (scalar != null && scalar !== "") {
      return [toNum(scalar)];
    }
    return [0];
  },

  _parseDataValues() {
    // Prefer data-values (comma-separated), fall back to data-value (scalar)
    const csv = this.el.dataset.values;
    if (csv != null && csv !== "") {
      return csv.split(",").map((s) => toNum(s.trim()));
    }
    const scalar = this.el.dataset.value;
    if (scalar != null && scalar !== "") {
      return [toNum(scalar)];
    }
    return [];
  },

  // --- Set command (shared by push_event + CustomEvent) ---

  _handleSetCommand(value, values, index, source) {
    if (values != null && Array.isArray(values)) {
      // Replace all values
      const newValues = values.map((v) => this._snapToStep(toNum(v)));
      this._setAllValues(newValues, source);
    } else if (value != null) {
      const val = toNum(value);
      if (index != null) {
        this._setValueAt(parseInt(index, 10), val, source);
      } else if (this._currentValues.length === 1) {
        this._setValueAt(0, val, source);
      } else {
        // Single value without index on multi-thumb: set closest
        const idx = this._findClosestThumbIndex(val);
        this._setValueAt(idx, val, source);
      }
    }
  },

  // --- Pointer drag ---

  _handlePointerDown(e) {
    if (this.disabled) return;
    if (e.button !== 0) return;

    e.preventDefault();
    const raw = this._rawValueFromPointer(e);
    const snapped = this._snapToStep(raw);
    const idx = this._findClosestThumbIndex(snapped);

    this._draggingIndex = idx;
    this._focusedIndex = idx;
    this.el.setPointerCapture(e.pointerId);

    // Focus the thumb and disable transition for smooth drag
    const thumbs = this.el.querySelectorAll("[data-slot='slider-thumb']");
    if (thumbs[idx]) {
      thumbs[idx].focus();
      thumbs[idx].dataset.dragging = "";
    }

    // Apply raw visual position immediately
    this._applyDragVisual(idx, raw);

    document.addEventListener("pointermove", this._onPointerMove);
    document.addEventListener("pointerup", this._onPointerUp);
  },

  _handlePointerMove(e) {
    if (this._draggingIndex == null) return;
    if (this._rafPending) return;

    this._rafPending = true;
    requestAnimationFrame(() => {
      this._rafPending = false;
      if (this._draggingIndex == null) return;
      const raw = this._rawValueFromPointer(e);
      this._applyDragVisual(this._draggingIndex, raw);
    });
  },

  _handlePointerUp(e) {
    if (this._draggingIndex == null) return;
    const idx = this._draggingIndex;
    this._draggingIndex = null;

    // Re-enable transition for snap settle, then snap to step
    const thumbs = this.el.querySelectorAll("[data-slot='slider-thumb']");
    if (thumbs[idx]) {
      delete thumbs[idx].dataset.dragging;
    }

    const value = this._snapToStep(this._rawValueFromPointer(e));
    this._setValueAt(idx, value, "user");

    document.removeEventListener("pointermove", this._onPointerMove);
    document.removeEventListener("pointerup", this._onPointerUp);
  },

  // --- Closest thumb ---

  _findClosestThumbIndex(value) {
    if (this._currentValues.length <= 1) return 0;

    let closestIdx = 0;
    let closestDist = Math.abs(this._currentValues[0] - value);

    for (let i = 1; i < this._currentValues.length; i++) {
      const dist = Math.abs(this._currentValues[i] - value);
      if (dist < closestDist || (dist === closestDist && value >= this._currentValues[i])) {
        closestDist = dist;
        closestIdx = i;
      }
    }
    return closestIdx;
  },

  // --- Coordinate math ---

  _rawValueFromPointer(e) {
    const track = this.el.querySelector("[data-slot='slider-track']");
    if (!track) return this._currentValues[0] || this.min;

    const rect = track.getBoundingClientRect();
    let fraction;

    if (this.orientation === "vertical") {
      fraction = (rect.bottom - e.clientY) / rect.height;
    } else {
      fraction = (e.clientX - rect.left) / rect.width;
    }

    fraction = Math.max(0, Math.min(1, fraction));
    return Math.max(this.min, Math.min(this.max, this.min + fraction * (this.max - this.min)));
  },

  _snapToStep(raw) {
    const snapped = Math.round((raw - this.min) / this.step) * this.step + this.min;
    // Round to avoid floating point drift (e.g. 0.1 + 0.2 = 0.30000000000000004)
    const decimals = (String(this.step).split(".")[1] || "").length;
    const rounded = decimals > 0 ? parseFloat(snapped.toFixed(decimals)) : Math.round(snapped);
    return Math.max(this.min, Math.min(this.max, rounded));
  },

  // --- Drag visual (smooth, unsnapped) ---

  _applyDragVisual(index, rawValue) {
    const range = this.max - this.min;
    const rawPct = range > 0 ? ((rawValue - this.min) / range) * 100 : 0;

    // Build percentages array: current values for other thumbs, raw for dragged thumb
    const percentages = this._currentValues.map((v, i) =>
      i === index ? rawPct : (range > 0 ? ((v - this.min) / range) * 100 : 0)
    );

    // Position the dragged thumb
    const thumbs = this.el.querySelectorAll("[data-slot='slider-thumb']");
    const thumb = thumbs[index];
    if (thumb) {
      if (this.orientation === "vertical") {
        thumb.style.bottom = `${rawPct}%`;
        thumb.style.transform = "translateY(50%)";
        thumb.style.left = "50%";
        thumb.style.marginLeft = "-8px";
        thumb.style.top = "";
        thumb.style.marginTop = "";
      } else {
        thumb.style.left = `${rawPct}%`;
        thumb.style.transform = "translateX(-50%)";
        thumb.style.top = "50%";
        thumb.style.marginTop = "-8px";
        thumb.style.bottom = "";
        thumb.style.marginLeft = "";
      }
    }

    // Update range fill using mixed percentages
    const rangeEl = this.el.querySelector("[data-slot='slider-range']");
    if (rangeEl) {
      const minPct = Math.min(...percentages);
      const maxPct = Math.max(...percentages);

      if (this.orientation === "vertical") {
        rangeEl.style.bottom = `${minPct}%`;
        rangeEl.style.top = `${100 - maxPct}%`;
        rangeEl.style.left = "";
        rangeEl.style.right = "";
      } else {
        rangeEl.style.left = `${minPct}%`;
        rangeEl.style.right = `${100 - maxPct}%`;
        rangeEl.style.top = "";
        rangeEl.style.bottom = "";
      }
    }
  },

  // --- Keyboard ---

  _handleKeyDown(e) {
    if (this.disabled) return;

    // Determine which thumb from data-thumb-index on the focused element
    const thumbEl = e.target.closest("[data-thumb-index]");
    if (!thumbEl) return;

    const idx = parseInt(thumbEl.dataset.thumbIndex, 10);
    const current = this._currentValues[idx] != null ? this._currentValues[idx] : this.min;
    let newValue = null;

    switch (e.key) {
      case "ArrowRight":
      case "ArrowUp":
        newValue = current + this.step;
        break;
      case "ArrowLeft":
      case "ArrowDown":
        newValue = current - this.step;
        break;
      case "PageUp":
        newValue = current + this.step * 10;
        break;
      case "PageDown":
        newValue = current - this.step * 10;
        break;
      case "Home":
        newValue = this.min;
        break;
      case "End":
        newValue = this.max;
        break;
      default:
        return;
    }

    e.preventDefault();
    newValue = Math.max(this.min, Math.min(this.max, newValue));
    this._setValueAt(idx, newValue, "user");
  },

  // --- Core ---

  _setValueAt(index, value, source) {
    if (this.stateMode === "server" && source !== "server") {
      // Notify only, don't update local state
      const newValues = [...this._currentValues];
      newValues[index] = this._snapToStep(value);
      this._notifyChange(newValues, source);
      return;
    }

    value = this._snapToStep(value);
    const newValues = [...this._currentValues];
    newValues[index] = value;

    this._currentValues = newValues;
    this._applyState(newValues);
    this._dispatchOutbound(newValues);

    if (source && source !== "server" && source !== "init") {
      this._notifyChange(newValues, source);
    }
  },

  _setAllValues(values, source) {
    if (this.stateMode === "server" && source !== "server") {
      this._notifyChange(values, source);
      return;
    }

    this._currentValues = values;
    this._applyState(values);
    this._dispatchOutbound(values);

    if (source && source !== "server" && source !== "init") {
      this._notifyChange(values, source);
    }
  },

  _applyState(values) {
    this._currentValues = values;
    const range = this.max - this.min;
    const percentages = values.map((v) =>
      range > 0 ? ((v - this.min) / range) * 100 : 0
    );

    // Update data attrs
    this.el.dataset.values = values.join(",");
    // Backward compat: data-value = first value
    this.el.dataset.value = String(values[0]);

    // Range fill: from min(pcts) to max(pcts)
    const rangeEl = this.el.querySelector("[data-slot='slider-range']");
    if (rangeEl) {
      const minPct = Math.min(...percentages);
      const maxPct = Math.max(...percentages);

      if (this.orientation === "vertical") {
        rangeEl.style.bottom = `${minPct}%`;
        rangeEl.style.top = `${100 - maxPct}%`;
        rangeEl.style.left = "";
        rangeEl.style.right = "";
      } else {
        rangeEl.style.left = `${minPct}%`;
        rangeEl.style.right = `${100 - maxPct}%`;
        rangeEl.style.top = "";
        rangeEl.style.bottom = "";
      }
    }

    // Position each thumb
    const thumbs = this.el.querySelectorAll("[data-slot='slider-thumb']");
    percentages.forEach((pct, i) => {
      const thumb = thumbs[i];
      if (!thumb) return;

      // Update ARIA on each thumb
      thumb.setAttribute("aria-valuenow", String(values[i]));

      if (this.orientation === "vertical") {
        thumb.style.bottom = `${pct}%`;
        thumb.style.transform = "translateY(50%)";
        thumb.style.left = "50%";
        thumb.style.marginLeft = "-8px";
        thumb.style.top = "";
        thumb.style.marginTop = "";
      } else {
        thumb.style.left = `${pct}%`;
        thumb.style.transform = "translateX(-50%)";
        thumb.style.top = "50%";
        thumb.style.marginTop = "-8px";
        thumb.style.bottom = "";
        thumb.style.marginLeft = "";
      }
    });

    // Sync form inputs (skip during init to avoid triggering phx-change)
    if (!this._initializing) {
      syncFormInput(this.el, values);
    }
  },

  // --- Notification ---

  _notifyChange(values, source) {
    if (source === "server") return;
    if (this.stateMode === "client") return;
    if (source === "drag") return;

    const range = this.max - this.min;
    const percentages = values.map((v) =>
      range > 0 ? ((v - this.min) / range) * 100 : 0
    );

    const payload = {
      id: this.el.id,
      values: values,
      percentages: percentages,
      // Backward compat: scalar value/percentage (first thumb)
      value: values[0],
      percentage: percentages[0],
    };

    notifyServer(this, this.eventCallback, payload);
  },

  _dispatchOutbound(values) {
    const range = this.max - this.min;
    const percentages = values.map((v) =>
      range > 0 ? ((v - this.min) / range) * 100 : 0
    );

    this.el.dispatchEvent(new CustomEvent("phx-shadcn:value-change", {
      detail: {
        id: this.el.id,
        values: values,
        percentages: percentages,
        value: values[0],
        percentage: percentages[0],
      },
      bubbles: false,
    }));
  },
};

export { Slider as PhxShadcnSlider };
export default Slider;
