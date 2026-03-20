/**
 * PhxShadcn — vanilla JS helpers for controlling components.
 *
 * Use from plain JavaScript, Alpine, Stimulus, or any other JS library.
 * Each method dispatches the same CustomEvent that the component hooks
 * already listen for — no LiveView dependency required.
 *
 * Setup (pick one):
 *
 *   // ESM import
 *   import { PhxShadcn } from "phx_shadcn/priv/static/phx-shadcn.js";
 *
 *   // Or attach to window for inline onclick handlers
 *   import { PhxShadcn } from "phx_shadcn";
 *   PhxShadcn.init();
 *
 * Usage:
 *
 *   PhxShadcn.open("my-accordion", "q1")
 *   PhxShadcn.press("my-toggle")
 *   PhxShadcn.show("my-dialog")
 *   PhxShadcn.select("theme-group", "dark")
 *   PhxShadcn.set("my-progress", 75)
 */

function dispatch(id, event, detail) {
  const el = document.getElementById(id);
  if (!el) {
    console.warn(`[PhxShadcn] Element #${id} not found`);
    return;
  }
  el.dispatchEvent(new CustomEvent(event, detail ? { detail } : undefined));
}

export const PhxShadcn = {
  /** Open an Accordion item or Collapsible. */
  open(id, value) { dispatch(id, "phx-shadcn:open", { value }); },

  /** Close an Accordion item or Collapsible. */
  close(id, value) { dispatch(id, "phx-shadcn:close", { value }); },

  /** Toggle binary state (Toggle, Switch, Collapsible). */
  toggle(id, value) { dispatch(id, "phx-shadcn:toggle", value != null ? { value } : undefined); },

  /** Press a Toggle. */
  press(id) { dispatch(id, "phx-shadcn:press"); },

  /** Unpress a Toggle. */
  unpress(id) { dispatch(id, "phx-shadcn:unpress"); },

  /** Check a Switch. */
  check(id) { dispatch(id, "phx-shadcn:check"); },

  /** Uncheck a Switch. */
  uncheck(id) { dispatch(id, "phx-shadcn:uncheck"); },

  /** Select an item in ToggleGroup or RadioGroup. */
  select(id, value) { dispatch(id, "phx-shadcn:select", { value }); },

  /** Deselect an item in ToggleGroup. */
  deselect(id, value) { dispatch(id, "phx-shadcn:deselect", { value }); },

  /** Activate a tab in Tabs. */
  activate(id, value) { dispatch(id, "phx-shadcn:activate", { value }); },

  /** Set a value (Progress, Slider, ToggleGroup). */
  set(id, value) { dispatch(id, "phx-shadcn:set", { value }); },

  /** Show an overlay (Dialog, Popover, Tooltip, HoverCard, Sheet, DropdownMenu). */
  show(id) { dispatch(id, "phx-shadcn:show"); },

  /** Hide an overlay (Dialog, Popover, Tooltip, HoverCard, Sheet, DropdownMenu). */
  hide(id) { dispatch(id, "phx-shadcn:hide"); },

  /** Create a toast on the given toaster element. */
  toast(id, opts) { dispatch(id || "toaster", "phx-shadcn:toast", opts); },

  /** Attach PhxShadcn to window for use in inline onclick handlers. */
  init() { window.PhxShadcn = PhxShadcn; },
};
