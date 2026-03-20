/**
 * RovingFocus hook — roving tabindex pattern for keyboard navigation.
 *
 * One item in the group has tabindex="0", the rest have tabindex="-1".
 * Arrow keys move focus between items per orientation.
 *
 * Config via data attributes on the root element:
 *   data-orientation="vertical|horizontal|both"  (default: "vertical")
 *   data-wrap="true|false"                        (default: "true")
 *
 * Items found by: [data-roving-item]:not([data-disabled])
 *
 * Pure client-side — no server communication. Consumer components
 * (RadioGroup, DropdownMenu, etc.) handle their own server notifications.
 */

const ITEM_SELECTOR = "[data-roving-item]:not([data-disabled])";

const RovingFocus = {
  mounted() {
    this._readConfig();
    this._initItems();

    this._onKeydown = (e) => this._handleKeydown(e);
    this._onFocusin = (e) => this._handleFocusin(e);

    this.el.addEventListener("keydown", this._onKeydown);
    this.el.addEventListener("focusin", this._onFocusin);
  },

  _readConfig() {
    this._orientation = this.el.dataset.orientation || "vertical";
    this._wrap = this.el.dataset.wrap !== "false";
  },

  _initItems() {
    const items = this._getItems();
    if (items.length === 0) return;

    // Preserve current focus if an item already has tabindex="0"
    const current = items.find((el) => el.getAttribute("tabindex") === "0");
    const active = current || items[0];

    for (const item of items) {
      item.setAttribute("tabindex", item === active ? "0" : "-1");
    }
  },

  _getItems() {
    return Array.from(this.el.querySelectorAll(ITEM_SELECTOR));
  },

  _handleKeydown(e) {
    const items = this._getItems();
    if (items.length === 0) return;

    const currentIndex = items.indexOf(document.activeElement);
    if (currentIndex === -1) return;

    let nextIndex = null;

    const isVertical =
      this._orientation === "vertical" || this._orientation === "both";
    const isHorizontal =
      this._orientation === "horizontal" || this._orientation === "both";

    if (e.key === "ArrowDown" && isVertical) {
      nextIndex = currentIndex + 1;
    } else if (e.key === "ArrowUp" && isVertical) {
      nextIndex = currentIndex - 1;
    } else if (e.key === "ArrowRight" && isHorizontal) {
      nextIndex = currentIndex + 1;
    } else if (e.key === "ArrowLeft" && isHorizontal) {
      nextIndex = currentIndex - 1;
    } else if (e.key === "Home") {
      nextIndex = 0;
    } else if (e.key === "End") {
      nextIndex = items.length - 1;
    }

    if (nextIndex === null) return;

    // Wrap or clamp
    if (this._wrap) {
      nextIndex = ((nextIndex % items.length) + items.length) % items.length;
    } else {
      nextIndex = Math.max(0, Math.min(nextIndex, items.length - 1));
      if (nextIndex === currentIndex) return;
    }

    e.preventDefault();
    this._focusItem(items, nextIndex);
  },

  _handleFocusin(e) {
    const items = this._getItems();
    const target = items.find((el) => el === e.target);
    if (!target) return;

    // Update tabindex to match the newly focused item
    for (const item of items) {
      item.setAttribute("tabindex", item === target ? "0" : "-1");
    }
  },

  _focusItem(items, index) {
    for (let i = 0; i < items.length; i++) {
      items[i].setAttribute("tabindex", i === index ? "0" : "-1");
    }
    items[index].focus();
  },

  updated() {
    this._readConfig();
    this._initItems();
  },

  destroyed() {
    this.el.removeEventListener("keydown", this._onKeydown);
    this.el.removeEventListener("focusin", this._onFocusin);
  },
};

export { RovingFocus as PhxShadcnRovingFocus };
export default RovingFocus;
