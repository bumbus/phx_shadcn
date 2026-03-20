/**
 * Menubar hook — horizontal menu bar with multi-menu coordination.
 *
 * Manages N trigger+content pairs in a bar. Supports hover-to-switch when
 * active, bar-level roving tabindex, cross-menu arrow navigation, sub-menus,
 * typeahead, and full ARIA menubar semantics.
 *
 * Config via data attributes on the root element:
 *   data-animation-duration="150"   — transition ms (fallback timer)
 *
 * Children found by:
 *   [data-menubar-menu]             — each menu container
 *   [data-menubar-trigger]          — trigger button inside each menu
 *   [data-menubar-content]          — floating menu panel inside each menu
 *
 * Sub-menus (inside content):
 *   [data-menubar-sub]              — sub-menu wrapper
 *   [data-menubar-sub-trigger]      — item that opens a sub-menu
 *   [data-menubar-sub-content]      — nested floating panel
 *
 * Content positioning config (data attrs on content element):
 *   data-side="bottom"
 *   data-align="start"
 *   data-side-offset="8"
 *   data-align-offset="-4"
 */
import {
  computePosition,
  offset,
  flip,
  shift,
  autoUpdate,
} from "../vendor/floating-ui.dom.esm.js";

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
    const subContent = el.closest("[data-menubar-sub-content]");
    if (!subContent) return true;
    return subContent.dataset.state === "open";
  });
}

function focusItem(item) {
  if (!item) return;
  const menu =
    item.closest("[data-menubar-sub-content]") ||
    item.closest("[data-menubar-content]");
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

const Menubar = {
  mounted() {
    this._openIndex = -1;
    this._barActive = false;
    this._focusedTriggerIndex = 0;
    this._cleanupAutoUpdate = null;
    this._typeaheadBuffer = "";
    this._typeaheadTimer = null;
    this._hideTimer = null;

    // Sub-menu state
    this._openSub = null;
    this._subHoverTimer = null;

    this._readConfig();
    this._scanMenus();
    this._setupBarRoving();

    // ── Trigger clicks ──────────────────────────────────────────────
    this._onTriggerClicks = [];
    this._onTriggerMouseenters = [];
    this._menus.forEach((menu, i) => {
      const onClick = (e) => {
        e.stopPropagation();
        if (this._openIndex === i) {
          this._hideMenu();
          this._barActive = false;
        } else {
          this._showMenu(i);
          this._barActive = true;
        }
      };
      menu.trigger.addEventListener("click", onClick);
      this._onTriggerClicks.push(onClick);

      // Hover-to-switch
      const onMouseenter = () => {
        if (this._barActive && this._openIndex !== i) {
          this._switchMenu(i);
        }
      };
      menu.trigger.addEventListener("mouseenter", onMouseenter);
      this._onTriggerMouseenters.push(onMouseenter);
    });

    // ── Trigger keyboard ────────────────────────────────────────────
    this._onTriggerKeydown = (e) => {
      const triggerIndex = this._menus.findIndex(
        (m) => m.trigger === e.currentTarget,
      );
      if (triggerIndex === -1) return;

      switch (e.key) {
        case "ArrowDown":
        case "Enter":
        case " ": {
          e.preventDefault();
          if (this._openIndex !== triggerIndex) {
            this._showMenu(triggerIndex);
            this._barActive = true;
          } else if (e.key === "ArrowDown") {
            // Already open, focus first item
            const items = getItems(this._menus[triggerIndex].content);
            if (items.length > 0) focusItem(items[0]);
          }
          break;
        }
        case "ArrowUp": {
          e.preventDefault();
          if (this._openIndex !== triggerIndex) {
            this._showMenu(triggerIndex, true);
            this._barActive = true;
          }
          break;
        }
        case "ArrowRight": {
          e.preventDefault();
          const next = (triggerIndex + 1) % this._menus.length;
          this._focusTrigger(next);
          if (this._barActive) this._switchMenu(next);
          break;
        }
        case "ArrowLeft": {
          e.preventDefault();
          const prev =
            (triggerIndex - 1 + this._menus.length) % this._menus.length;
          this._focusTrigger(prev);
          if (this._barActive) this._switchMenu(prev);
          break;
        }
        case "Escape": {
          e.preventDefault();
          if (this._openIndex >= 0) {
            this._hideMenu();
          }
          this._barActive = false;
          break;
        }
        case "Tab": {
          // Let tab leave the menubar
          if (this._openIndex >= 0) {
            this._hideMenu();
          }
          this._barActive = false;
          break;
        }
      }
    };
    this._menus.forEach((menu) => {
      menu.trigger.addEventListener("keydown", this._onTriggerKeydown);
    });

    // ── Click outside ───────────────────────────────────────────────
    this._onDocumentClick = (e) => {
      if (this._openIndex >= 0 && !this.el.contains(e.target)) {
        this._hideMenu();
        this._barActive = false;
      }
    };
    document.addEventListener("click", this._onDocumentClick, true);

    // ── Menu content keyboard navigation ────────────────────────────
    this._onMenuKeydowns = [];
    this._onContentClicks = [];
    this._onContentMouseovers = [];
    this._onContentMouseoverSubs = [];

    this._menus.forEach((menu, menuIndex) => {
      const onKeydown = (e) => {
        if (this._openIndex !== menuIndex) return;

        const activeEl = document.activeElement;
        const inSub =
          this._openSub && this._openSub.content.contains(activeEl);
        const activeMenu = inSub ? this._openSub.content : menu.content;
        const items = getItems(activeMenu);
        const currentItemIndex = items.indexOf(activeEl);

        switch (e.key) {
          case "ArrowDown": {
            e.preventDefault();
            const next =
              currentItemIndex < items.length - 1 ? currentItemIndex + 1 : 0;
            focusItem(items[next]);
            break;
          }
          case "ArrowUp": {
            e.preventDefault();
            const prev =
              currentItemIndex > 0
                ? currentItemIndex - 1
                : items.length - 1;
            focusItem(items[prev]);
            break;
          }
          case "ArrowRight": {
            e.preventDefault();
            // If focused item is a sub-trigger, open sub
            if (
              activeEl &&
              activeEl.hasAttribute("data-menubar-sub-trigger")
            ) {
              const sub = activeEl.closest("[data-menubar-sub]");
              if (sub) this._showSub(sub);
            } else if (!inSub) {
              // Close current menu, open next
              const next = (menuIndex + 1) % this._menus.length;
              this._switchMenu(next, false); // focus first item
            } else {
              // In sub but not on sub-trigger — close sub, open next menu
              this._hideSub();
              const next = (menuIndex + 1) % this._menus.length;
              this._switchMenu(next, false);
            }
            break;
          }
          case "ArrowLeft": {
            e.preventDefault();
            if (inSub && this._openSub) {
              // Close sub, focus sub-trigger
              const trigger = this._openSub.trigger;
              this._hideSub();
              focusItem(trigger);
            } else {
              // Close current menu, open previous
              const prev =
                (menuIndex - 1 + this._menus.length) % this._menus.length;
              this._switchMenu(prev, false);
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
              if (activeEl.hasAttribute("data-menubar-sub-trigger")) {
                const sub = activeEl.closest("[data-menubar-sub]");
                if (sub) this._showSub(sub);
              } else {
                activeEl.click();
                if (!activeEl.hasAttribute("data-keep-open")) {
                  this._hideMenu();
                  this._barActive = false;
                }
              }
            }
            break;
          }
          case "Tab": {
            e.preventDefault();
            this._hideMenu();
            this._barActive = false;
            // Return focus to trigger
            this._focusTrigger(menuIndex);
            break;
          }
          case "Escape": {
            e.preventDefault();
            e.stopPropagation();
            if (inSub && this._openSub) {
              const trigger = this._openSub.trigger;
              this._hideSub();
              focusItem(trigger);
            } else {
              this._hideMenu();
              this._focusTrigger(menuIndex);
            }
            break;
          }
          default: {
            // Typeahead
            if (e.key.length === 1 && !e.ctrlKey && !e.metaKey && !e.altKey) {
              e.preventDefault();
              this._handleTypeahead(e.key, items);
            }
          }
        }
      };
      menu.content.addEventListener("keydown", onKeydown);
      this._onMenuKeydowns.push(onKeydown);

      // ── Item click — close menu unless data-keep-open ───────────
      const onContentClick = (e) => {
        const item = e.target.closest("[data-roving-item]");
        if (!item) return;
        if (item.hasAttribute("data-disabled")) {
          e.preventDefault();
          e.stopPropagation();
          return;
        }
        if (item.hasAttribute("data-menubar-sub-trigger")) {
          const sub = item.closest("[data-menubar-sub]");
          if (sub) this._showSub(sub);
          return;
        }
        if (!item.hasAttribute("data-keep-open")) {
          requestAnimationFrame(() => {
            this._hideMenu();
            this._barActive = false;
          });
        }
      };
      menu.content.addEventListener("click", onContentClick);
      this._onContentClicks.push(onContentClick);

      // ── Sub-menu hover ──────────────────────────────────────────
      const onContentMouseover = (e) => {
        const subTrigger = e.target.closest("[data-menubar-sub-trigger]");
        if (subTrigger) {
          clearTimeout(this._subHoverTimer);
          const sub = subTrigger.closest("[data-menubar-sub]");
          if (sub && (!this._openSub || this._openSub.sub !== sub)) {
            this._subHoverTimer = setTimeout(() => this._showSub(sub), 100);
          }
        } else if (
          e.target.closest("[data-menubar-content]") === menu.content &&
          !e.target.closest("[data-menubar-sub-content]")
        ) {
          clearTimeout(this._subHoverTimer);
          if (this._openSub) {
            this._subHoverTimer = setTimeout(() => this._hideSub(), 150);
          }
        }
      };
      menu.content.addEventListener("mouseover", onContentMouseover);
      this._onContentMouseovers.push(onContentMouseover);

      // Cancel sub-close when hovering into sub-content
      const onContentMouseoverSub = (e) => {
        if (this._openSub && this._openSub.content.contains(e.target)) {
          clearTimeout(this._subHoverTimer);
        }
      };
      menu.content.addEventListener("mouseover", onContentMouseoverSub);
      this._onContentMouseoverSubs.push(onContentMouseoverSub);
    });
  },

  _readConfig() {
    this._animationDuration =
      parseInt(this.el.dataset.animationDuration, 10) || 150;
  },

  _scanMenus() {
    const menuEls = this.el.querySelectorAll("[data-menubar-menu]");
    this._menus = Array.from(menuEls).map((el) => ({
      el,
      trigger: el.querySelector("[data-menubar-trigger]"),
      content: el.querySelector("[data-menubar-content]"),
    }));
  },

  _setupBarRoving() {
    // Set initial tabindex: first trigger gets 0, rest get -1
    this._menus.forEach((menu, i) => {
      menu.trigger.setAttribute(
        "tabindex",
        i === this._focusedTriggerIndex ? "0" : "-1",
      );
    });
  },

  _focusTrigger(index) {
    this._menus.forEach((menu, i) => {
      menu.trigger.setAttribute("tabindex", i === index ? "0" : "-1");
    });
    this._focusedTriggerIndex = index;
    this._menus[index].trigger.focus();
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

  // ── Show / Hide / Switch ──────────────────────────────────────────

  _showMenu(index, focusLast) {
    if (this._openIndex === index) return;

    // Close currently open menu without animation
    if (this._openIndex >= 0) {
      this._hideMenuImmediate();
    }

    this._openIndex = index;
    const menu = this._menus[index];

    // ARIA
    menu.trigger.setAttribute("aria-expanded", "true");
    menu.trigger.dataset.state = "open";

    // Unhide content
    menu.content.removeAttribute("hidden");

    // Position and start transitions
    this._positionMenu(index).then(() => {
      this._cleanupAutoUpdate = autoUpdate(
        menu.trigger,
        menu.content,
        () => this._positionMenu(index),
        { animationFrame: true },
      );

      void getComputedStyle(menu.content).opacity;

      requestAnimationFrame(() => {
        menu.content.dataset.state = "open";

        requestAnimationFrame(() => {
          const items = getItems(menu.content);
          if (items.length > 0) {
            focusItem(focusLast ? items[items.length - 1] : items[0]);
          }
        });
      });
    });

    this._focusedTriggerIndex = index;
    this._menus.forEach((m, i) => {
      m.trigger.setAttribute("tabindex", i === index ? "0" : "-1");
    });
  },

  _hideMenu() {
    if (this._openIndex < 0) return;
    const menu = this._menus[this._openIndex];
    const savedIndex = this._openIndex;

    // Close any open sub-menu
    this._hideSub();

    // ARIA
    menu.trigger.setAttribute("aria-expanded", "false");
    delete menu.trigger.dataset.state;

    // Trigger exit transition
    menu.content.dataset.state = "closing";

    const cleanup = () => {
      clearTimeout(this._hideTimer);

      menu.content.setAttribute("hidden", "");
      delete menu.content.dataset.state;

      if (this._cleanupAutoUpdate) {
        this._cleanupAutoUpdate();
        this._cleanupAutoUpdate = null;
      }
    };

    menu.content.addEventListener("transitionend", cleanup, { once: true });
    this._hideTimer = setTimeout(cleanup, this._animationDuration + 50);

    this._openIndex = -1;
  },

  _hideMenuImmediate() {
    if (this._openIndex < 0) return;
    const menu = this._menus[this._openIndex];

    this._hideSub();

    clearTimeout(this._hideTimer);

    menu.trigger.setAttribute("aria-expanded", "false");
    delete menu.trigger.dataset.state;

    menu.content.setAttribute("hidden", "");
    delete menu.content.dataset.state;

    if (this._cleanupAutoUpdate) {
      this._cleanupAutoUpdate();
      this._cleanupAutoUpdate = null;
    }

    this._openIndex = -1;
  },

  _switchMenu(newIndex, focusFirstItem = true) {
    if (this._openIndex === newIndex) return;
    this._hideMenuImmediate();
    if (focusFirstItem) {
      this._showMenu(newIndex);
    } else {
      this._showMenu(newIndex);
    }
  },

  // ── Sub-menu management ────────────────────────────────────────────

  _showSub(sub) {
    if (this._openSub && this._openSub.sub !== sub) {
      this._hideSub();
    }
    if (this._openSub && this._openSub.sub === sub) return;

    const trigger = sub.querySelector("[data-menubar-sub-trigger]");
    const content = sub.querySelector("[data-menubar-sub-content]");
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

  async _positionMenu(index) {
    const menu = this._menus[index];
    const content = menu.content;
    const side = content.dataset.side || "bottom";
    const align = content.dataset.align || "start";
    const sideOffset = parseInt(content.dataset.sideOffset, 10) || 8;
    const alignOffset = parseInt(content.dataset.alignOffset, 10) || -4;

    const placement = toPlacement(side, align);

    const { x, y, placement: actualPlacement } = await computePosition(
      menu.trigger,
      content,
      {
        strategy: "fixed",
        placement,
        middleware: [
          offset({ mainAxis: sideOffset, crossAxis: alignOffset }),
          flip(),
          shift({ padding: 8 }),
        ],
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
  },

  // ── Lifecycle ──────────────────────────────────────────────────────

  updated() {
    this._readConfig();

    // Re-scan menus in case LiveView patched the DOM
    const oldMenuCount = this._menus.length;
    this._scanMenus();

    if (this._openIndex >= 0 && this._openIndex < this._menus.length) {
      const menu = this._menus[this._openIndex];
      menu.content.removeAttribute("hidden");
      menu.content.dataset.state = "open";
      menu.trigger.setAttribute("aria-expanded", "true");
      menu.trigger.dataset.state = "open";
      this._positionMenu(this._openIndex);

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

    this._menus.forEach((menu, i) => {
      if (this._onTriggerClicks[i]) {
        menu.trigger.removeEventListener("click", this._onTriggerClicks[i]);
      }
      if (this._onTriggerMouseenters[i]) {
        menu.trigger.removeEventListener(
          "mouseenter",
          this._onTriggerMouseenters[i],
        );
      }
      menu.trigger.removeEventListener("keydown", this._onTriggerKeydown);
      if (this._onMenuKeydowns[i]) {
        menu.content.removeEventListener("keydown", this._onMenuKeydowns[i]);
      }
      if (this._onContentClicks[i]) {
        menu.content.removeEventListener("click", this._onContentClicks[i]);
      }
      if (this._onContentMouseovers[i]) {
        menu.content.removeEventListener(
          "mouseover",
          this._onContentMouseovers[i],
        );
      }
      if (this._onContentMouseoverSubs[i]) {
        menu.content.removeEventListener(
          "mouseover",
          this._onContentMouseoverSubs[i],
        );
      }
    });

    document.removeEventListener("click", this._onDocumentClick, true);
  },
};

export { Menubar as PhxShadcnMenubar };
export default Menubar;
