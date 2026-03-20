/**
 * ContextMenu hook — right-click triggered floating menu with keyboard navigation.
 *
 * Nearly identical to DropdownMenu, but triggered by `contextmenu` event and
 * positioned at the cursor via a virtual reference instead of anchored to a
 * trigger element.
 *
 * Config via data attributes on the root element:
 *   data-on-open-change="event|JS"  — callback on dismiss
 *   data-auto-open="true|false"     — open on mount (rarely useful)
 *   data-animation-duration="150"   — transition ms (fallback timer)
 *
 * Children found by:
 *   [data-context-trigger] — the trigger region (right-click area)
 *   [data-context-content] — the floating menu panel (role="menu")
 *
 * Sub-menus:
 *   [data-context-sub]             — sub-menu wrapper (inside content)
 *   [data-context-sub-trigger]     — item that opens a sub-menu
 *   [data-context-sub-content]     — nested floating panel
 *
 * Content positioning config (data attrs on content element):
 *   data-side="top|right|bottom|left"
 *   data-align="start|center|end"
 *   data-side-offset="2"
 */
import {
  computePosition,
  offset,
  flip,
  shift,
  autoUpdate,
} from "../vendor/floating-ui.dom.esm.js";
import { notifyServer, listenForCommands } from "./event-bridge.js";

// ── Floating UI placement helpers ────────────────────────────────────

function toPlacement(side, align) {
  if (align === "center") return side;
  return `${side}-${align === "start" ? "start" : "end"}`;
}

function fromPlacement(placement) {
  const parts = placement.split("-");
  return { side: parts[0], align: parts[1] || "center" };
}

// ── Roving focus helpers ─────────────────────────────────────────────

const ITEM_SELECTOR = "[data-roving-item]:not([data-disabled])";

function getItems(container) {
  return Array.from(container.querySelectorAll(ITEM_SELECTOR)).filter((el) => {
    // Exclude items inside closed sub-content panels
    const subContent = el.closest("[data-context-sub-content]");
    if (!subContent) return true; // top-level item, always include
    return subContent.dataset.state === "open"; // only include if sub is open
  });
}

function focusItem(item) {
  if (!item) return;
  // Remove tabindex from all roving items in the same menu level
  const menu =
    item.closest("[data-context-sub-content]") ||
    item.closest("[data-context-content]");
  if (menu) {
    menu
      .querySelectorAll("[data-roving-item]")
      .forEach((el) => el.setAttribute("tabindex", "-1"));
  }
  item.setAttribute("tabindex", "0");
  item.focus();
}

// ── Shared sub-menu positioning ──────────────────────────────────────

async function positionSubContent(trigger, content) {
  const side = content.dataset.side || "right";
  const align = content.dataset.align || "start";
  const sideOffset = parseInt(content.dataset.sideOffset, 10) || -4;

  const placement = toPlacement(side, align);

  const { x, y, placement: actualPlacement } = await computePosition(
    trigger,
    content,
    {
      strategy: "fixed",
      placement,
      middleware: [offset(sideOffset), flip(), shift({ padding: 8 })],
    },
  );

  Object.assign(content.style, {
    position: "fixed",
    left: `${x}px`,
    top: `${y}px`,
  });

  const actual = fromPlacement(actualPlacement);
  content.dataset.side = actual.side;
  content.dataset.align = actual.align;
}

// ── Hook ─────────────────────────────────────────────────────────────

const ContextMenu = {
  mounted() {
    this._trigger = this.el.querySelector("[data-context-trigger]");
    this._content = this.el.querySelector("[data-context-content]");
    this._open = false;
    this._transitioning = false;
    this._hideTimer = null;
    this._cleanupAutoUpdate = null;
    this._typeaheadBuffer = "";
    this._typeaheadTimer = null;

    // Virtual reference for cursor-anchored positioning
    this._virtualRef = null;
    this._cursorX = 0;
    this._cursorY = 0;

    // Sub-menu state
    this._openSub = null; // { sub, trigger, content, cleanup }
    this._subHoverTimer = null;

    this._readConfig();

    // ── Context menu trigger (right-click) ─────────────────────────
    this._onContextMenu = (e) => {
      e.preventDefault();

      // Store cursor position
      this._cursorX = e.clientX;
      this._cursorY = e.clientY;

      // Create virtual reference at cursor
      this._virtualRef = {
        getBoundingClientRect: () => ({
          x: this._cursorX,
          y: this._cursorY,
          width: 0,
          height: 0,
          top: this._cursorY,
          right: this._cursorX,
          bottom: this._cursorY,
          left: this._cursorX,
        }),
      };

      if (this._open) {
        // Re-right-click while open: close immediately, reopen at new position
        this._forceClose();
        // Reopen at new cursor position
        requestAnimationFrame(() => this._show());
      } else {
        this._show();
      }
    };
    this._trigger.addEventListener("contextmenu", this._onContextMenu);

    // ── Click outside ────────────────────────────────────────────────
    this._onDocumentClick = (e) => {
      if (this._open && !this._content.contains(e.target)) {
        this._dismiss();
      }
    };
    document.addEventListener("click", this._onDocumentClick, true);

    // Also close on right-click outside
    this._onDocumentContextMenu = (e) => {
      if (this._open && !this._trigger.contains(e.target) && !this._content.contains(e.target)) {
        this._dismiss();
      }
    };
    document.addEventListener("contextmenu", this._onDocumentContextMenu, true);

    // ── Menu keyboard navigation ─────────────────────────────────────
    this._onMenuKeydown = (e) => {
      if (!this._open) return;

      // Determine which menu level has focus
      const activeEl = document.activeElement;
      const inSub =
        this._openSub && this._openSub.content.contains(activeEl);
      const activeMenu = inSub ? this._openSub.content : this._content;
      const items = getItems(activeMenu);
      const currentIndex = items.indexOf(activeEl);

      switch (e.key) {
        case "ArrowDown": {
          e.preventDefault();
          const next =
            currentIndex < items.length - 1 ? currentIndex + 1 : 0;
          focusItem(items[next]);
          break;
        }
        case "ArrowUp": {
          e.preventDefault();
          const prev =
            currentIndex > 0 ? currentIndex - 1 : items.length - 1;
          focusItem(items[prev]);
          break;
        }
        case "ArrowRight": {
          // If focused item is a sub-trigger, open the sub-menu
          if (activeEl && activeEl.hasAttribute("data-context-sub-trigger")) {
            e.preventDefault();
            const sub = activeEl.closest("[data-context-sub]");
            if (sub) this._showSub(sub);
          }
          break;
        }
        case "ArrowLeft": {
          // If inside a sub-menu, close it and focus the sub-trigger
          if (inSub && this._openSub) {
            e.preventDefault();
            const trigger = this._openSub.trigger;
            this._hideSub();
            focusItem(trigger);
          }
          break;
        }
        case "Home": {
          e.preventDefault();
          focusItem(items[0]);
          break;
        }
        case "End": {
          e.preventDefault();
          focusItem(items[items.length - 1]);
          break;
        }
        case "Enter":
        case " ": {
          e.preventDefault();
          if (activeEl && items.includes(activeEl)) {
            // If it's a sub-trigger, open the sub-menu
            if (activeEl.hasAttribute("data-context-sub-trigger")) {
              const sub = activeEl.closest("[data-context-sub]");
              if (sub) this._showSub(sub);
            } else {
              activeEl.click();
              if (!activeEl.hasAttribute("data-keep-open")) {
                this._hide();
              }
            }
          }
          break;
        }
        case "Tab": {
          e.preventDefault();
          this._dismiss();
          break;
        }
        case "Escape": {
          e.preventDefault();
          e.stopPropagation();
          // If in sub-menu, close sub first
          if (inSub && this._openSub) {
            const trigger = this._openSub.trigger;
            this._hideSub();
            focusItem(trigger);
          } else {
            this._dismiss();
          }
          break;
        }
        default: {
          // Typeahead — printable single character
          if (e.key.length === 1 && !e.ctrlKey && !e.metaKey && !e.altKey) {
            e.preventDefault();
            this._handleTypeahead(e.key, items);
          }
        }
      }
    };
    this._content.addEventListener("keydown", this._onMenuKeydown);

    // ── Item click — close menu unless data-keep-open ────────────────
    this._onContentClick = (e) => {
      const item = e.target.closest("[data-roving-item]");
      if (!item) return;
      if (item.hasAttribute("data-disabled")) {
        e.preventDefault();
        e.stopPropagation();
        return;
      }
      // Sub-triggers open sub-menu on click too
      if (item.hasAttribute("data-context-sub-trigger")) {
        const sub = item.closest("[data-context-sub]");
        if (sub) this._showSub(sub);
        return;
      }
      if (!item.hasAttribute("data-keep-open")) {
        requestAnimationFrame(() => this._hide());
      }
    };
    this._content.addEventListener("click", this._onContentClick);

    // ── Sub-menu hover ───────────────────────────────────────────────
    this._onContentMouseover = (e) => {
      const subTrigger = e.target.closest("[data-context-sub-trigger]");
      if (subTrigger) {
        clearTimeout(this._subHoverTimer);
        const sub = subTrigger.closest("[data-context-sub]");
        if (sub && (!this._openSub || this._openSub.sub !== sub)) {
          this._subHoverTimer = setTimeout(() => this._showSub(sub), 100);
        }
      } else if (
        e.target.closest("[data-context-content]") === this._content &&
        !e.target.closest("[data-context-sub-content]")
      ) {
        // Hovering over a non-sub item in parent menu — close open sub
        clearTimeout(this._subHoverTimer);
        if (this._openSub) {
          this._subHoverTimer = setTimeout(() => this._hideSub(), 150);
        }
      }
    };
    this._content.addEventListener("mouseover", this._onContentMouseover);

    // Cancel sub-close when hovering into sub-content
    this._onContentMouseoverSub = (e) => {
      if (
        this._openSub &&
        this._openSub.content.contains(e.target)
      ) {
        clearTimeout(this._subHoverTimer);
      }
    };
    this._content.addEventListener("mouseover", this._onContentMouseoverSub);

    // ── Custom events (JS helpers) ───────────────────────────────────
    this._onShowEvent = () => this._show();
    this._onHideEvent = () => this._hide();
    this.el.addEventListener("phx-shadcn:show", this._onShowEvent);
    this.el.addEventListener("phx-shadcn:hide", this._onHideEvent);

    // ── Server→client push_event commands ────────────────────────────
    listenForCommands(this, ({ command }) => {
      if (command === "show") this._show();
      else if (command === "hide") this._hide();
    });

    // Auto-open on mount (rarely useful for context menu)
    if (this.el.dataset.autoOpen === "true") {
      this._show();
    }
  },

  _readConfig() {
    this._onOpenChange = this.el.dataset.onOpenChange || null;
    this._animationDuration =
      parseInt(this.el.dataset.animationDuration, 10) || 150;
  },

  // ── Typeahead ──────────────────────────────────────────────────────

  _handleTypeahead(char, items) {
    this._typeaheadBuffer += char.toLowerCase();
    clearTimeout(this._typeaheadTimer);
    this._typeaheadTimer = setTimeout(() => {
      this._typeaheadBuffer = "";
    }, 500);

    const match = items.find((item) => {
      const text = (item.textContent || "").trim().toLowerCase();
      return text.startsWith(this._typeaheadBuffer);
    });

    if (match) focusItem(match);
  },

  // ── Show / Hide ────────────────────────────────────────────────────

  _show(focusLast) {
    if (this._open) return;
    // Guard: can't position without a virtual ref (no right-click yet)
    if (!this._virtualRef) return;

    clearTimeout(this._hideTimer);
    this._transitioning = false;
    this._open = true;

    // Unhide content
    this._content.removeAttribute("hidden");

    // Position and start transitions
    this._position().then(() => {
      this._cleanupAutoUpdate = autoUpdate(
        this._virtualRef,
        this._content,
        () => this._position(),
        { animationFrame: true },
      );

      // Force reflow before triggering transition
      void getComputedStyle(this._content).opacity;

      requestAnimationFrame(() => {
        this.el.dataset.state = "open";
        this._content.dataset.state = "open";

        // Focus first (or last) non-disabled item
        requestAnimationFrame(() => {
          const items = getItems(this._content);
          if (items.length > 0) {
            focusItem(focusLast ? items[items.length - 1] : items[0]);
          }
        });
      });
    });
  },

  _hide() {
    if (!this._open || this._transitioning) return;
    this._transitioning = true;

    // Close any open sub-menu first
    this._hideSub();

    // Trigger exit transition
    this.el.dataset.state = "closing";
    this._content.dataset.state = "closing";

    const cleanup = () => {
      clearTimeout(this._hideTimer);
      this._transitioning = false;
      this._open = false;

      this._content.setAttribute("hidden", "");
      delete this.el.dataset.state;
      delete this._content.dataset.state;

      // Stop autoUpdate
      if (this._cleanupAutoUpdate) {
        this._cleanupAutoUpdate();
        this._cleanupAutoUpdate = null;
      }

      // Return focus to trigger region
      this._trigger.focus();
    };

    this._content.addEventListener("transitionend", cleanup, { once: true });
    this._hideTimer = setTimeout(cleanup, this._animationDuration + 50);
  },

  /** Force-close without animation (for re-right-click while open) */
  _forceClose() {
    clearTimeout(this._hideTimer);
    this._transitioning = false;
    this._open = false;

    this._hideSub();

    this._content.setAttribute("hidden", "");
    delete this.el.dataset.state;
    delete this._content.dataset.state;

    if (this._cleanupAutoUpdate) {
      this._cleanupAutoUpdate();
      this._cleanupAutoUpdate = null;
    }
  },

  _dismiss() {
    this._hide();
    notifyServer(this, this._onOpenChange, { id: this.el.id, open: false });
  },

  // ── Sub-menu management ────────────────────────────────────────────

  _showSub(sub) {
    // Close any currently open sub-menu
    if (this._openSub && this._openSub.sub !== sub) {
      this._hideSub();
    }
    if (this._openSub && this._openSub.sub === sub) return;

    const trigger = sub.querySelector("[data-context-sub-trigger]");
    const content = sub.querySelector("[data-context-sub-content]");
    if (!trigger || !content) return;

    content.removeAttribute("hidden");
    trigger.setAttribute("aria-expanded", "true");
    trigger.dataset.state = "open";

    positionSubContent(trigger, content).then(() => {
      const cleanupAU = autoUpdate(
        trigger,
        content,
        () => positionSubContent(trigger, content),
        { animationFrame: true },
      );

      void getComputedStyle(content).opacity;
      requestAnimationFrame(() => {
        content.dataset.state = "open";

        // Focus first item in sub-menu
        requestAnimationFrame(() => {
          const items = getItems(content);
          if (items.length > 0) focusItem(items[0]);
        });
      });

      this._openSub = { sub, trigger, content, cleanup: cleanupAU };
    });
  },

  _hideSub() {
    if (!this._openSub) return;
    clearTimeout(this._subHoverTimer);

    const { trigger, content, cleanup } = this._openSub;

    trigger.setAttribute("aria-expanded", "false");
    delete trigger.dataset.state;
    content.setAttribute("hidden", "");
    delete content.dataset.state;
    content.style.position = "";
    content.style.left = "";
    content.style.top = "";

    if (cleanup) cleanup();
    this._openSub = null;
  },

  // ── Positioning ────────────────────────────────────────────────────

  async _position() {
    if (!this._virtualRef) return;

    const side = this._content.dataset.side || "bottom";
    const align = this._content.dataset.align || "start";
    const sideOffset =
      parseInt(this._content.dataset.sideOffset, 10) || 2;

    const placement = toPlacement(side, align);

    const { x, y, placement: actualPlacement } = await computePosition(
      this._virtualRef,
      this._content,
      {
        strategy: "fixed",
        placement,
        middleware: [offset(sideOffset), flip(), shift({ padding: 8 })],
      },
    );

    Object.assign(this._content.style, {
      position: "fixed",
      left: `${x}px`,
      top: `${y}px`,
    });

    // Update data-side/data-align to reflect actual placement (may differ due to flip)
    const actual = fromPlacement(actualPlacement);
    this._content.dataset.side = actual.side;
    this._content.dataset.align = actual.align;
  },

  // ── Lifecycle ──────────────────────────────────────────────────────

  updated() {
    this._readConfig();

    if (this._open && !this._transitioning) {
      // LiveView patch may re-add hidden and strip inline styles — restore them
      this._content.removeAttribute("hidden");
      this.el.dataset.state = "open";
      this._content.dataset.state = "open";
      if (this._virtualRef) this._position();

      // Restore open sub-menu if any
      if (this._openSub) {
        const { trigger, content } = this._openSub;
        content.removeAttribute("hidden");
        content.dataset.state = "open";
        trigger.setAttribute("aria-expanded", "true");
        trigger.dataset.state = "open";
        positionSubContent(trigger, content);
      }
    }
  },

  destroyed() {
    clearTimeout(this._hideTimer);
    clearTimeout(this._typeaheadTimer);
    clearTimeout(this._subHoverTimer);

    this._hideSub();

    if (this._cleanupAutoUpdate) {
      this._cleanupAutoUpdate();
      this._cleanupAutoUpdate = null;
    }

    this._trigger.removeEventListener("contextmenu", this._onContextMenu);
    document.removeEventListener("click", this._onDocumentClick, true);
    document.removeEventListener("contextmenu", this._onDocumentContextMenu, true);
    this._content.removeEventListener("keydown", this._onMenuKeydown);
    this._content.removeEventListener("click", this._onContentClick);
    this._content.removeEventListener("mouseover", this._onContentMouseover);
    this._content.removeEventListener(
      "mouseover",
      this._onContentMouseoverSub,
    );
    this.el.removeEventListener("phx-shadcn:show", this._onShowEvent);
    this.el.removeEventListener("phx-shadcn:hide", this._onHideEvent);
  },
};

export { ContextMenu as PhxShadcnContextMenu };
export default ContextMenu;
