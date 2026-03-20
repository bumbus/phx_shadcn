/**
 * Collapsible hook — reusable for Accordion and Collapsible components.
 *
 * One hook instance per root element. Uses event delegation for triggers.
 * Supports 3 state modes: client, hybrid, server.
 *
 * Config via data attributes on root:
 *   data-type="single|multiple"
 *   data-collapsible="true|false"
 *   data-state-mode="client|hybrid|server"
 *   data-value="val1,val2" (server mode: current open values)
 *   data-default-value="val1,val2" (client/hybrid: initial open values)
 *   data-on-value-change="event_name|JS_struct" (hybrid/server: callback)
 *   data-item-selector="[data-slot=accordion-item]"
 *   data-trigger-selector="[data-slot=accordion-trigger]"
 *   data-content-selector="[data-slot=accordion-content]"
 */
import { notifyServer, listenForCommands } from "./event-bridge.js";

const Collapsible = {
  mounted() {
    this.type = this.el.dataset.type || "single";
    this.collapsible = this.el.dataset.collapsible === "true";
    this.stateMode = this.el.dataset.stateMode || "client";
    this.eventCallback = this.el.dataset.onValueChange || null;
    this.itemSel = this.el.dataset.itemSelector || "[data-slot=accordion-item]";
    this.triggerSel = this.el.dataset.triggerSelector || "[data-slot=accordion-trigger]";
    this.contentSel = this.el.dataset.contentSelector || "[data-slot=accordion-content]";

    // Parse initial open set
    this.openSet = new Set();
    const initial = this.stateMode === "server"
      ? this.el.dataset.value
      : this.el.dataset.defaultValue;

    if (initial) {
      initial.split(",").filter(Boolean).forEach(v => this.openSet.add(v));
    }

    // Set up aria attributes and IDs
    this._setupAria();

    // Apply initial open state
    this._applyState();

    // Bind click delegation
    this._onClick = (e) => {
      const trigger = e.target.closest(this.triggerSel);
      if (!trigger) return;

      const item = trigger.closest(this.itemSel);
      if (!item) return;
      if (item.dataset.disabled === "true") return;

      e.preventDefault();
      this._toggle(item.dataset.value, "user");
    };
    this.el.addEventListener("click", this._onClick);

    // Bind keyboard — Enter/Space on trigger
    this._onKeydown = (e) => {
      const trigger = e.target.closest(this.triggerSel);
      if (!trigger) return;

      if (e.key === "Enter" || e.key === " ") {
        e.preventDefault();
        const item = trigger.closest(this.itemSel);
        if (!item || item.dataset.disabled === "true") return;
        this._toggle(item.dataset.value, "user");
      }
    };
    this.el.addEventListener("keydown", this._onKeydown);

    // Hash support — check on mount
    this._checkHash();

    // Listen for hashchange (browser back/forward)
    this._onHashChange = () => this._checkHash();
    window.addEventListener("hashchange", this._onHashChange);

    // Server→client push_event commands
    listenForCommands(this, ({ command, value }) => {
      switch (command) {
        case "open":
          this._open(value, "server");
          break;
        case "close":
          this._close(value, "server");
          break;
        case "toggle":
          this._toggle(value, "server");
          break;
        case "set":
          // Full state replacement — value is comma-separated or array
          const values = Array.isArray(value) ? value : String(value).split(",").filter(Boolean);
          this.openSet = new Set(values);
          this._applyState();
          break;
      }
    });

    // External JS API — inbound CustomEvents
    this._onCustomOpen = (e) => {
      const value = e.detail && e.detail.value;
      if (value) this._open(value, "external");
    };
    this._onCustomClose = (e) => {
      const value = e.detail && e.detail.value;
      if (value) this._close(value, "external");
    };
    this._onCustomToggle = (e) => {
      const value = e.detail && e.detail.value;
      if (value) this._toggle(value, "external");
    };
    this.el.addEventListener("phx-shadcn:open", this._onCustomOpen);
    this.el.addEventListener("phx-shadcn:close", this._onCustomClose);
    this.el.addEventListener("phx-shadcn:toggle", this._onCustomToggle);
  },

  updated() {
    // Re-read state mode — it can change when value goes from nil to non-nil
    this.stateMode = this.el.dataset.stateMode || "client";
    this.eventCallback = this.el.dataset.onValueChange || null;

    if (this.stateMode === "server") {
      const serverValue = this.el.dataset.value || "";
      const newSet = new Set(serverValue.split(",").filter(Boolean));

      this.openSet = newSet;

      // Defer to next frame: LiveView's morphdom may still be patching descendant
      // elements (resetting static attrs like style="display:none") when updated()
      // fires on the hook element. Waiting one frame ensures all patches are settled.
      requestAnimationFrame(() => this._applyState());
    }
  },

  destroyed() {
    this.el.removeEventListener("click", this._onClick);
    this.el.removeEventListener("keydown", this._onKeydown);
    this.el.removeEventListener("phx-shadcn:open", this._onCustomOpen);
    this.el.removeEventListener("phx-shadcn:close", this._onCustomClose);
    this.el.removeEventListener("phx-shadcn:toggle", this._onCustomToggle);
    window.removeEventListener("hashchange", this._onHashChange);
  },

  // --- Public API (thin wrappers) ---

  toggle(value) {
    this._toggle(value, "user");
  },

  // --- Core state transitions ---

  _open(value, source) {
    if (this.openSet.has(value)) return;

    if (this.stateMode === "server" && source !== "server") {
      // Server mode: only notify, don't toggle locally
      this._notifyChange(value, "open", source);
      return;
    }

    if (this.type === "single") {
      // Close all others first
      const toClose = [...this.openSet];
      this.openSet.clear();
      toClose.forEach(v => this._animateClose(v));
    }

    this.openSet.add(value);
    this._animateOpen(value);
    this._updateHash(value, true);
    this._notifyChange(value, "open", source);
    this._dispatchOutbound("phx-shadcn:opened", value);
  },

  _close(value, source) {
    if (!this.openSet.has(value)) return;
    if (this.type === "single" && !this.collapsible) return;

    if (this.stateMode === "server" && source !== "server") {
      this._notifyChange(value, "close", source);
      return;
    }

    this.openSet.delete(value);
    this._animateClose(value);
    this._notifyChange(value, "close", source);
    this._dispatchOutbound("phx-shadcn:closed", value);
  },

  _toggle(value, source) {
    if (this.openSet.has(value)) {
      this._close(value, source);
    } else {
      this._open(value, source);
    }
  },

  // --- Notification ---

  _notifyChange(value, action, source) {
    // Server source suppresses outbound notification (prevents loops)
    if (source === "server") return;
    if (this.stateMode === "client") return;

    const payload = {
      id: this.el.id,
      value: this.type === "multiple" ? [...this.openSet] : value,
      action: action
    };

    notifyServer(this, this.eventCallback, payload);
  },

  _dispatchOutbound(eventName, value) {
    this.el.dispatchEvent(new CustomEvent(eventName, {
      detail: { id: this.el.id, value: value },
      bubbles: false
    }));
  },

  // --- Private ---

  // Returns all items — includes the root element itself if it matches the item selector.
  // This allows the same hook to work for both Accordion (items are descendants)
  // and Collapsible (root is the item).
  _getItems() {
    const items = [...this.el.querySelectorAll(this.itemSel)];
    if (this.el.matches(this.itemSel)) items.unshift(this.el);
    return items;
  },

  _setupAria() {
    const items = this._getItems();

    items.forEach(item => {
      const value = item.dataset.value;
      const trigger = item.querySelector(this.triggerSel);
      const content = item.querySelector(this.contentSel);

      if (!value || !trigger || !content) return;

      // NOTE: Do NOT set `id` on items, triggers, or content here.
      // Adding JS-only IDs causes LiveView's morphdom to treat them as
      // "server-deleted" on the next patch (the server HTML has no IDs
      // on these elements), which removes them from the DOM entirely.

      trigger.setAttribute("aria-expanded", "false");
      content.setAttribute("role", "region");
    });
  },

  _applyState() {
    const items = this._getItems();
    items.forEach(item => {
      const value = item.dataset.value;
      if (this.openSet.has(value)) {
        this._setOpen(item, true);
      } else {
        this._setOpen(item, false);
      }
    });
  },

  _setOpen(item, open) {
    const trigger = item.querySelector(this.triggerSel);
    const content = item.querySelector(this.contentSel);
    if (!trigger || !content) return;

    const state = open ? "open" : "closed";
    item.dataset.state = state;
    trigger.dataset.state = state;
    trigger.setAttribute("aria-expanded", String(open));
    content.dataset.state = state;
    content.style.display = open ? "" : "none";

    if (open) {
      // Measure and set height var for animation
      content.style.height = "auto";
      const height = content.scrollHeight;
      content.style.setProperty("--radix-accordion-content-height", `${height}px`);
    }
  },

  _animateOpen(value) {
    const item = this._findItem(value);
    if (!item) return;

    const content = item.querySelector(this.contentSel);
    const trigger = item.querySelector(this.triggerSel);
    if (!content || !trigger) return;

    // Set state to open
    item.dataset.state = "open";
    trigger.dataset.state = "open";
    trigger.setAttribute("aria-expanded", "true");
    content.dataset.state = "open";

    // Show and measure
    content.style.display = "";
    content.style.overflow = "hidden";
    content.style.height = "0px";

    // Force reflow
    void content.offsetHeight;

    const height = content.scrollHeight;
    content.style.setProperty("--radix-accordion-content-height", `${height}px`);
    content.style.height = `${height}px`;

    const onEnd = () => {
      content.style.height = "";
      content.style.overflow = "";
      content.removeEventListener("transitionend", onEnd);
      content.removeEventListener("animationend", onEnd);
    };

    content.addEventListener("transitionend", onEnd, { once: true });
    content.addEventListener("animationend", onEnd, { once: true });
  },

  _animateClose(value) {
    const item = this._findItem(value);
    if (!item) return;

    const content = item.querySelector(this.contentSel);
    const trigger = item.querySelector(this.triggerSel);
    if (!content || !trigger) return;

    // Measure current height before closing
    const height = content.scrollHeight;
    content.style.setProperty("--radix-accordion-content-height", `${height}px`);
    content.style.overflow = "hidden";
    content.style.height = `${height}px`;

    // Force reflow
    void content.offsetHeight;

    // Set state to closed (triggers CSS animation)
    item.dataset.state = "closed";
    trigger.dataset.state = "closed";
    trigger.setAttribute("aria-expanded", "false");
    content.dataset.state = "closed";

    content.style.height = "0px";

    const onEnd = () => {
      content.style.display = "none";
      content.style.height = "";
      content.style.overflow = "";
      content.removeEventListener("transitionend", onEnd);
      content.removeEventListener("animationend", onEnd);
    };

    content.addEventListener("transitionend", onEnd, { once: true });
    content.addEventListener("animationend", onEnd, { once: true });
  },

  _findItem(value) {
    // Check root first (Collapsible case), then descendants (Accordion case)
    if (this.el.matches(this.itemSel) && this.el.dataset.value === value) {
      return this.el;
    }
    return this.el.querySelector(`${this.itemSel}[data-value="${value}"]`);
  },

  _checkHash() {
    const hash = location.hash.replace("#", "");
    if (!hash) return;

    const rootId = this.el.id;
    if (!hash.startsWith(rootId + "-")) return;

    const value = hash.slice(rootId.length + 1);
    const item = this._findItem(value);
    if (!item) return;

    if (!this.openSet.has(value)) {
      this._open(value, "user");
    }

    // Scroll into view
    requestAnimationFrame(() => {
      item.scrollIntoView({ behavior: "smooth", block: "start" });
    });
  },

  _updateHash(value, opened) {
    if (!opened) return;
    const itemId = `${this.el.id}-${value}`;
    if (history.replaceState) {
      history.replaceState(null, null, `#${itemId}`);
    }
  }
};

export { Collapsible as PhxShadcnCollapsible };
export default Collapsible;
