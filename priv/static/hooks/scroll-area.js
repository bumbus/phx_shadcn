/**
 * ScrollArea hook — custom scrollbar overlay for scroll containers.
 *
 * Replaces native scrollbars with thin, styled thumbs that track scroll
 * position, support drag, and auto-show/hide on hover and scroll activity.
 *
 * Pure client-side — no server interaction needed.
 */
const ScrollArea = {
  mounted() {
    this._viewport = this.el.querySelector('[data-slot="scroll-area-viewport"]');
    this._vTrack = this.el.querySelector('[data-slot="scroll-area-scrollbar"][data-orientation="vertical"]');
    this._hTrack = this.el.querySelector('[data-slot="scroll-area-scrollbar"][data-orientation="horizontal"]');
    this._vThumb = this._vTrack?.querySelector('[data-slot="scroll-area-thumb"]');
    this._hThumb = this._hTrack?.querySelector('[data-slot="scroll-area-thumb"]');

    if (!this._viewport) return;

    this._dragging = null; // { axis: "v"|"h", startPos, startScroll }
    this._hideTimers = { v: null, h: null };
    this._hovering = false;

    // Bind handlers
    this._onScroll = this._handleScroll.bind(this);
    this._onPointerDown = this._handlePointerDown.bind(this);
    this._onPointerMove = this._handlePointerMove.bind(this);
    this._onPointerUp = this._handlePointerUp.bind(this);
    this._onMouseEnter = () => { this._hovering = true; this._showBars(); };
    this._onMouseLeave = () => { this._hovering = false; this._scheduleHide(); };

    // Listen
    this._viewport.addEventListener("scroll", this._onScroll, { passive: true });
    this.el.addEventListener("pointerdown", this._onPointerDown);
    this.el.addEventListener("mouseenter", this._onMouseEnter);
    this.el.addEventListener("mouseleave", this._onMouseLeave);

    // ResizeObserver for content/viewport changes
    this._resizeObserver = new ResizeObserver(() => this._recalc());
    this._resizeObserver.observe(this._viewport);
    if (this._viewport.firstElementChild) {
      this._resizeObserver.observe(this._viewport.firstElementChild);
    }

    // Initial calculation
    this._recalc();
  },

  updated() {
    // Content may have changed — recalc
    this._recalc();
  },

  destroyed() {
    this._resizeObserver?.disconnect();
    this._viewport?.removeEventListener("scroll", this._onScroll);
    this.el.removeEventListener("pointerdown", this._onPointerDown);
    this.el.removeEventListener("mouseenter", this._onMouseEnter);
    this.el.removeEventListener("mouseleave", this._onMouseLeave);
    document.removeEventListener("pointermove", this._onPointerMove);
    document.removeEventListener("pointerup", this._onPointerUp);
    clearTimeout(this._hideTimers.v);
    clearTimeout(this._hideTimers.h);
  },

  // ── Recalculate thumb sizes and positions ─────────────────────────

  _recalc() {
    this._updateThumb("v");
    this._updateThumb("h");
  },

  _updateThumb(axis) {
    const isV = axis === "v";
    const track = isV ? this._vTrack : this._hTrack;
    const thumb = isV ? this._vThumb : this._hThumb;
    if (!track || !thumb) return;

    const vp = this._viewport;
    const viewportSize = isV ? vp.clientHeight : vp.clientWidth;
    const contentSize = isV ? vp.scrollHeight : vp.scrollWidth;

    // Hide scrollbar if content fits
    if (contentSize <= viewportSize + 1) {
      track.dataset.state = "hidden";
      track.style.display = "none";
      return;
    }

    track.style.display = "";

    const trackEl = track;
    const trackSize = isV ? trackEl.clientHeight : trackEl.clientWidth;
    const thumbRatio = viewportSize / contentSize;
    const thumbSize = Math.max(thumbRatio * trackSize, 18);
    const scrollPos = isV ? vp.scrollTop : vp.scrollLeft;
    const maxScroll = contentSize - viewportSize;
    const thumbOffset = maxScroll > 0
      ? (scrollPos / maxScroll) * (trackSize - thumbSize)
      : 0;

    if (isV) {
      thumb.style.height = `${thumbSize}px`;
      thumb.style.width = "";
      thumb.style.transform = `translateY(${thumbOffset}px)`;
    } else {
      thumb.style.width = `${thumbSize}px`;
      thumb.style.height = "";
      thumb.style.transform = `translateX(${thumbOffset}px)`;
    }
  },

  // ── Scroll event ──────────────────────────────────────────────────

  _handleScroll() {
    this._recalc();
    this._showBars();
    if (!this._dragging) this._scheduleHide();
  },

  // ── Show / hide scrollbars ────────────────────────────────────────

  _showBars() {
    this._showBar("v");
    this._showBar("h");
  },

  _showBar(axis) {
    const track = axis === "v" ? this._vTrack : this._hTrack;
    if (!track || track.style.display === "none") return;
    clearTimeout(this._hideTimers[axis]);
    track.dataset.state = "visible";
  },

  _scheduleHide() {
    this._scheduleHideBar("v");
    this._scheduleHideBar("h");
  },

  _scheduleHideBar(axis) {
    if (this._hovering || this._dragging) return;
    const track = axis === "v" ? this._vTrack : this._hTrack;
    if (!track) return;
    clearTimeout(this._hideTimers[axis]);
    this._hideTimers[axis] = setTimeout(() => {
      if (!this._hovering && !this._dragging) {
        track.dataset.state = "hidden";
      }
    }, 1000);
  },

  // ── Pointer interactions (thumb drag + track click) ───────────────

  _handlePointerDown(e) {
    // Check if clicked on a thumb or track
    const thumb = e.target.closest('[data-slot="scroll-area-thumb"]');
    const track = e.target.closest('[data-slot="scroll-area-scrollbar"]');
    if (!track) return;

    const orientation = track.dataset.orientation;
    const isV = orientation === "vertical";
    const axis = isV ? "v" : "h";

    if (thumb) {
      // Start drag
      e.preventDefault();
      const startPos = isV ? e.clientY : e.clientX;
      const startScroll = isV ? this._viewport.scrollTop : this._viewport.scrollLeft;
      this._dragging = { axis, startPos, startScroll };
      thumb.setPointerCapture(e.pointerId);
      document.addEventListener("pointermove", this._onPointerMove);
      document.addEventListener("pointerup", this._onPointerUp);
      this._showBars();
    } else {
      // Track click — jump to position
      e.preventDefault();
      const trackRect = track.getBoundingClientRect();
      const clickPos = isV
        ? (e.clientY - trackRect.top) / trackRect.height
        : (e.clientX - trackRect.left) / trackRect.width;

      const vp = this._viewport;
      const contentSize = isV ? vp.scrollHeight : vp.scrollWidth;
      const viewportSize = isV ? vp.clientHeight : vp.clientWidth;
      const maxScroll = contentSize - viewportSize;
      const targetScroll = clickPos * maxScroll;

      if (isV) {
        vp.scrollTop = targetScroll;
      } else {
        vp.scrollLeft = targetScroll;
      }
    }
  },

  _handlePointerMove(e) {
    if (!this._dragging) return;
    const { axis, startPos, startScroll } = this._dragging;
    const isV = axis === "v";
    const track = isV ? this._vTrack : this._hTrack;
    const vp = this._viewport;

    const trackSize = isV ? track.clientHeight : track.clientWidth;
    const viewportSize = isV ? vp.clientHeight : vp.clientWidth;
    const contentSize = isV ? vp.scrollHeight : vp.scrollWidth;
    const maxScroll = contentSize - viewportSize;

    const delta = (isV ? e.clientY : e.clientX) - startPos;
    // Convert thumb-pixel delta to scroll-pixel delta
    const scrollDelta = (delta / trackSize) * contentSize;

    if (isV) {
      vp.scrollTop = Math.min(Math.max(startScroll + scrollDelta, 0), maxScroll);
    } else {
      vp.scrollLeft = Math.min(Math.max(startScroll + scrollDelta, 0), maxScroll);
    }
  },

  _handlePointerUp(e) {
    if (!this._dragging) return;
    this._dragging = null;
    document.removeEventListener("pointermove", this._onPointerMove);
    document.removeEventListener("pointerup", this._onPointerUp);
    this._scheduleHide();
  }
};

export { ScrollArea as PhxShadcnScrollArea };
