/**
 * Toast hook — Sonner-style auto-dismissing, stacking, swipeable toasts.
 *
 * JS owns ALL positioning: stacking transforms, enter/exit animations,
 * opacity, z-index — set via inline styles. No CSS specificity issues.
 *
 * CSS owns: base look (border, bg, padding, border-radius), swipe
 * during drag (data-swiping), and swipe-out keyframes (data-swipe-out).
 *
 * Per-toast pointer handlers with setPointerCapture on the <li>.
 * Central _swipe state ensures one gesture at a time.
 */
import { listenForCommands } from "./event-bridge.js";

const VISIBLE_TOASTS = 3;
const GAP = 8;
const TOAST_WIDTH = 356;
const SWIPE_THRESHOLD = 45;
const SWIPE_VELOCITY = 0.11; // px/ms

let toastCounter = 0;

const FALLBACK_ICONS = {
  success: `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/></svg>`,
  info: `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/></svg>`,
  warning: `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/><path d="M12 9v4"/><path d="M12 17h.01"/></svg>`,
  error: `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="7.86 2 16.14 2 22 7.86 22 16.14 16.14 22 7.86 22 2 16.14 2 7.86 7.86 2"/><path d="m15 9-6 6"/><path d="m9 9 6 6"/></svg>`,
};

const ICON_CLASSES = {
  success: "text-muted-foreground",
  info: "text-muted-foreground",
  warning: "text-muted-foreground",
  error: "text-muted-foreground",
};

const Toast = {
  mounted() {
    this._toasts = [];
    this._position = this.el.dataset.position || "bottom-right";
    this._defaultDuration = parseInt(this.el.dataset.duration, 10) || 4000;
    this._offset = this.el.dataset.offset || "16px";
    this._expanded = this.el.dataset.expand === "true";
    this._hovering = false;
    this._swipe = null;

    const [y, x] = this._position.split("-");
    this._yPos = y; // "top" | "bottom"
    this._xPos = x; // "left" | "center" | "right"

    this._icons = {};
    for (const type of ["success", "info", "warning", "error"]) {
      const tpl = this.el.querySelector(`template[data-toast-icon="${type}"]`);
      const html = tpl ? tpl.innerHTML.trim() : "";
      this._icons[type] = html || FALLBACK_ICONS[type] || "";
    }

    this._createContainer();
    this._consumeFlash();

    listenForCommands(this, (payload) => {
      if (payload.command === "toast") {
        this._addToast({
          type: payload.type || "info",
          title: payload.title,
          description: payload.description,
          action: payload.action,
          duration: payload.duration,
          dismissible: payload.dismissible,
          id: payload.toast_id,
        });
      }
    });

    this._onToastEvent = (e) => {
      if (e.detail) this._addToast(e.detail);
    };
    this.el.addEventListener("phx-shadcn:toast", this._onToastEvent);
  },

  updated() {
    this._consumeFlash();
  },

  destroyed() {
    this.el.removeEventListener("phx-shadcn:toast", this._onToastEvent);
    this._toasts.forEach((t) => clearTimeout(t.timer));
  },

  // ── Container ──────────────────────────────────────────────────

  _createContainer() {
    const ol = document.createElement("ol");
    ol.setAttribute("data-sonner-toaster", "");

    // Position container via inline styles
    const offset = this._offset;
    if (this._yPos === "top") ol.style.top = offset;
    else ol.style.bottom = offset;
    if (this._xPos === "left") ol.style.left = offset;
    else if (this._xPos === "right") ol.style.right = offset;
    else { ol.style.left = "50%"; ol.style.transform = "translateX(-50%)"; }

    // Hover expand/collapse — use mouseover/mouseout (they bubble,
    // unlike mouseenter/mouseleave which don't fire on pointer-events:none parents)
    ol.addEventListener("mouseover", (e) => {
      if (!e.target.closest("[data-sonner-toast]")) return;
      if (this._hovering) return;
      this._hovering = true;
      this._expanded = true;
      this._toasts.forEach((t) => this._pauseTimer(t));
      this._updatePositions();
    });
    ol.addEventListener("mouseout", (e) => {
      if (ol.contains(e.relatedTarget)) return;
      if (this._swipe) return;
      this._hovering = false;
      this._expanded = this.el.dataset.expand === "true";
      this._toasts.forEach((t) => this._resumeTimer(t));
      this._updatePositions();
    });

    this._container = ol;
    this.el.appendChild(ol);
  },

  // ── Flash ──────────────────────────────────────────────────────

  _consumeFlash() {
    const info = this.el.dataset.flashInfo;
    const error = this.el.dataset.flashError;
    if (info) {
      this._addToast({ type: "success", title: info });
      this.pushEvent("lv:clear-flash", { key: "info" });
      delete this.el.dataset.flashInfo;
    }
    if (error) {
      this._addToast({ type: "error", title: error, duration: 6000 });
      this.pushEvent("lv:clear-flash", { key: "error" });
      delete this.el.dataset.flashError;
    }
  },

  // ── Toast lifecycle ────────────────────────────────────────────

  _addToast(opts) {
    const toast = {
      id: opts.id || `toast-${++toastCounter}`,
      type: opts.type || "info",
      title: opts.title || "",
      description: opts.description || null,
      action: opts.action || null,
      duration: opts.duration != null ? opts.duration : this._defaultDuration,
      dismissible: opts.dismissible !== false,
      el: null,
      timer: null,
      timerStart: 0,    // Date.now() when timer was last (re)started
      remaining: 0,     // ms remaining when paused
      removing: false,
      swiping: false,
      height: 0,
    };

    const li = this._renderToast(toast);
    toast.el = li;
    li._toast = toast;

    // Start offscreen (enter animation)
    const isBottom = this._yPos === "bottom";
    li.style.opacity = "0";
    li.style.transform = isBottom
      ? "translateY(100%)"
      : "translateY(-100%)";
    li.style.transition = "none";

    if (isBottom) li.style.bottom = "0";
    else li.style.top = "0";
    if (this._xPos === "left") li.style.left = "0";
    else if (this._xPos === "right") li.style.right = "0";
    else { li.style.left = "50%"; li.style.marginLeft = `-${TOAST_WIDTH / 2}px`; }

    this._container.appendChild(li);
    this._toasts.push(toast);

    // Measure, position, then animate in
    requestAnimationFrame(() => {
      toast.height = li.getBoundingClientRect().height;

      // Enable transitions, then update positions (which sets the final transform)
      requestAnimationFrame(() => {
        li.style.transition = "";
        this._updatePositions();
      });
    });

    if (toast.duration > 0) {
      this._startTimer(toast);
      // If already hovering, pause immediately (timer will resume on mouseout)
      if (this._hovering) this._pauseTimer(toast);
    }

    return toast;
  },

  _renderToast(toast) {
    const li = document.createElement("li");
    li.setAttribute("data-sonner-toast", "");
    li.setAttribute("data-type", toast.type);

    const content = document.createElement("div");
    content.className = "flex gap-3 items-start";

    const iconHtml = this._icons[toast.type];
    if (iconHtml) {
      const iconWrap = document.createElement("div");
      iconWrap.className = `shrink-0 mt-0.5 ${ICON_CLASSES[toast.type] || ""}`;
      iconWrap.innerHTML = iconHtml;
      content.appendChild(iconWrap);
    }

    const textWrap = document.createElement("div");
    textWrap.className = "flex-1 min-w-0";
    if (toast.title) {
      const title = document.createElement("div");
      title.className = "text-sm font-semibold";
      title.textContent = toast.title;
      textWrap.appendChild(title);
    }
    if (toast.description) {
      const desc = document.createElement("div");
      desc.className = "text-sm text-muted-foreground mt-1";
      desc.textContent = toast.description;
      textWrap.appendChild(desc);
    }
    content.appendChild(textWrap);

    if (toast.dismissible) {
      const close = document.createElement("button");
      close.className = [
        "shrink-0 inline-flex items-center justify-center",
        "size-5 rounded-md",
        "text-muted-foreground hover:text-foreground",
        "opacity-0 group-hover/toast:opacity-100 transition-opacity",
        "cursor-pointer",
      ].join(" ");
      close.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>`;
      close.addEventListener("click", (e) => {
        e.stopPropagation();
        this._removeToast(toast);
      });
      content.appendChild(close);
    }

    li.appendChild(content);

    if (toast.action) {
      const actionWrap = document.createElement("div");
      actionWrap.className = "mt-2 ml-7";
      const btn = document.createElement("button");
      btn.className = [
        "inline-flex items-center justify-center",
        "rounded-md text-xs font-medium h-7 px-3",
        "bg-primary text-primary-foreground",
        "hover:bg-primary/90 cursor-pointer",
      ].join(" ");
      btn.textContent = toast.action.label || "Action";
      btn.addEventListener("click", (e) => {
        e.stopPropagation();
        if (toast.action.event) {
          this.pushEvent(toast.action.event, toast.action.payload || {});
        }
        this._removeToast(toast);
      });
      actionWrap.appendChild(btn);
      li.appendChild(actionWrap);
    }

    li.classList.add("group/toast");

    if (toast.dismissible) {
      this._setupSwipe(li, toast);
    }

    return li;
  },

  // ── Stacking (all inline styles — no CSS specificity issues) ───

  _updatePositions() {
    const isBottom = this._yPos === "bottom";
    const expanded = this._expanded;
    const active = this._toasts.filter((t) => !t.removing);

    // Newest toast is last in array
    active.forEach((toast, i) => {
      const li = toast.el;
      if (!li || toast.swiping) return;

      const indexFromFront = active.length - 1 - i;
      const isFront = indexFromFront === 0;
      const visible = indexFromFront < VISIBLE_TOASTS || expanded;

      // Offset = sum of heights of all toasts in front of this one
      let heightOffset = 0;
      for (let j = i + 1; j < active.length; j++) {
        heightOffset += active[j].height;
      }

      const gapOffset = indexFromFront * GAP;
      const scale = expanded ? 1 : Math.max(1 - indexFromFront * 0.05, 0.85);

      let translateY;
      if (expanded) {
        translateY = isBottom
          ? -(heightOffset + gapOffset)
          : (heightOffset + gapOffset);
      } else {
        translateY = isBottom ? -gapOffset : gapOffset;
      }

      if (visible) {
        li.style.opacity = "1";
        li.style.pointerEvents = "auto";
        li.style.transform = expanded
          ? `translateY(${translateY}px)`
          : `translateY(${translateY}px) scale(${scale})`;
      } else {
        li.style.opacity = "0";
        li.style.pointerEvents = "none";
        li.style.transform = `translateY(${translateY}px) scale(0.85)`;
      }

      li.style.zIndex = `${active.length - indexFromFront}`;
    });
  },

  // ── Timers ─────────────────────────────────────────────────────

  _startTimer(toast) {
    if (toast.swiping || toast.duration <= 0) return;
    clearTimeout(toast.timer);
    toast.remaining = toast.duration;
    toast.timerStart = Date.now();
    toast.timer = setTimeout(() => this._removeToast(toast), toast.remaining);
  },

  _pauseTimer(toast) {
    if (!toast.timer || toast.duration <= 0) return;
    clearTimeout(toast.timer);
    toast.timer = null;
    const elapsed = Date.now() - toast.timerStart;
    toast.remaining = Math.max(0, toast.remaining - elapsed);
  },

  _resumeTimer(toast) {
    if (toast.duration <= 0 || toast.removing || toast.swiping) return;
    if (toast.remaining <= 0) {
      this._removeToast(toast);
      return;
    }
    clearTimeout(toast.timer);
    toast.timerStart = Date.now();
    toast.timer = setTimeout(() => this._removeToast(toast), toast.remaining);
  },

  _removeToast(toast) {
    if (toast.swiping || toast.removing) return;
    toast.removing = true;
    clearTimeout(toast.timer);

    const li = toast.el;
    if (!li) return;

    // Animate out via inline styles (no CSS specificity issues)
    const isBottom = this._yPos === "bottom";
    li.style.transition = "transform 400ms ease, opacity 400ms ease";
    li.style.opacity = "0";
    li.style.transform = isBottom ? "translateY(100%)" : "translateY(-100%)";
    li.style.pointerEvents = "none";

    setTimeout(() => {
      li.remove();
      this._toasts = this._toasts.filter((t) => t !== toast);
      this._updatePositions();
    }, 400);
  },

  // ── Swipe (per-toast, capture on <li>) ─────────────────────────

  _setupSwipe(li, toast) {
    const onPointerDown = (e) => {
      // Force-clear stale swipe state (safety valve)
      if (this._swipe) {
        const stale = this._swipe;
        if (stale.toast.removing || !this._toasts.includes(stale.toast)) {
          this._cancelSwipe(stale);
        } else {
          return; // legitimate active gesture
        }
      }

      if (e.button !== 0) return;
      if (e.target.closest("button")) return;
      if (toast.removing) return;

      li.setPointerCapture(e.pointerId);

      this._swipe = {
        toast,
        li,
        pointerId: e.pointerId,
        startX: e.clientX,
        startY: e.clientY,
        startTime: Date.now(),
        axis: null,
      };

      toast.swiping = true;
      clearTimeout(toast.timer);
      li.setAttribute("data-swiping", "true");
    };

    const onPointerMove = (e) => {
      const s = this._swipe;
      if (!s || s.toast !== toast || e.pointerId !== s.pointerId) return;

      const dx = e.clientX - s.startX;
      const dy = e.clientY - s.startY;

      if (!s.axis) {
        if (Math.abs(dx) < 3 && Math.abs(dy) < 3) return;
        s.axis = Math.abs(dx) >= Math.abs(dy) ? "x" : "y";
      }

      if (s.axis === "y") {
        this._cancelSwipe(s);
        return;
      }

      li.style.setProperty("--swipe-amount", `${dx}px`);
      li.style.opacity = `${Math.max(0, 1 - Math.abs(dx) / 200)}`;
    };

    const onPointerUp = (e) => {
      const s = this._swipe;
      if (!s || s.toast !== toast || e.pointerId !== s.pointerId) return;

      try { li.releasePointerCapture(s.pointerId); } catch (_) {}

      const swipeStr = li.style.getPropertyValue("--swipe-amount") || "0px";
      const swipeAmount = parseFloat(swipeStr) || 0;
      const elapsed = Date.now() - s.startTime;
      const velocity = Math.abs(swipeAmount) / Math.max(elapsed, 1);

      this._swipe = null;
      toast.swiping = false;

      const dismissed =
        s.axis === "x" &&
        (Math.abs(swipeAmount) >= SWIPE_THRESHOLD || velocity >= SWIPE_VELOCITY);

      if (dismissed) {
        // Keep --swipe-amount for CSS @keyframes from position
        li.removeAttribute("data-swiping");
        li.style.removeProperty("opacity");
        li.setAttribute("data-swipe-out", swipeAmount > 0 ? "right" : "left");
        li.style.pointerEvents = "none";
        toast.removing = true;
        clearTimeout(toast.timer);

        setTimeout(() => {
          li.remove();
          this._toasts = this._toasts.filter((t) => t !== toast);
          this._updatePositions();
        }, 200);
      } else {
        li.removeAttribute("data-swiping");
        li.style.removeProperty("--swipe-amount");
        li.style.removeProperty("opacity");
        this._updatePositions();
        if (toast.duration > 0 && !this._hovering) {
          this._resumeTimer(toast);
        }
      }
    };

    const onPointerCancel = (e) => {
      const s = this._swipe;
      if (!s || s.toast !== toast || e.pointerId !== s.pointerId) return;
      this._cancelSwipe(s);
    };

    li.addEventListener("pointerdown", onPointerDown);
    li.addEventListener("pointermove", onPointerMove);
    li.addEventListener("pointerup", onPointerUp);
    li.addEventListener("pointercancel", onPointerCancel);
  },

  _cancelSwipe(s) {
    try { s.li.releasePointerCapture(s.pointerId); } catch (_) {}
    s.li.removeAttribute("data-swiping");
    s.li.style.removeProperty("--swipe-amount");
    s.li.style.removeProperty("opacity");
    s.toast.swiping = false;
    this._swipe = null;
    this._updatePositions();
    if (s.toast.duration > 0 && !this._hovering && !s.toast.removing) {
      this._resumeTimer(s.toast);
    }
  },
};

export { Toast as PhxShadcnToast };
export default Toast;
