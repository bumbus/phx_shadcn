defmodule PhxShadcn.JS do
  @moduledoc """
  Chainable JS commands for controlling PhxShadcn components.

  Every function returns a `%Phoenix.LiveView.JS{}` struct, so commands
  compose with LiveView's built-in `JS` module:

      alias PhxShadcn.JS, as: SJS

      <button phx-click={SJS.open("my-accordion", "q1")}>Open Q1</button>
      <button phx-click={JS.push("track") |> SJS.press("my-toggle")}>Track & Press</button>

  Under the hood each function calls `JS.dispatch/3` with the appropriate
  `phx-shadcn:*` CustomEvent — the same events the hooks already listen for.
  No new client-side code is needed.

  ## Commands

  ### Collapsible / Accordion

  | Function | Event | Components |
  |----------|-------|------------|
  | `open/3` | `phx-shadcn:open` | Accordion, Collapsible |
  | `close/3` | `phx-shadcn:close` | Accordion, Collapsible |

  For Collapsible, pass any value (e.g. `"_"`). For Accordion, pass the item value.

  ### Toggle / Switch

  | Function | Event | Components |
  |----------|-------|------------|
  | `press/2` | `phx-shadcn:press` | Toggle |
  | `unpress/2` | `phx-shadcn:unpress` | Toggle |
  | `check/2` | `phx-shadcn:check` | Switch |
  | `uncheck/2` | `phx-shadcn:uncheck` | Switch |
  | `toggle/2` | `phx-shadcn:toggle` | Toggle, Switch, Collapsible |

  ### Selection

  | Function | Event | Components |
  |----------|-------|------------|
  | `select/3` | `phx-shadcn:select` | ToggleGroup, RadioGroup |
  | `deselect/3` | `phx-shadcn:deselect` | ToggleGroup |
  | `activate/3` | `phx-shadcn:activate` | Tabs |
  | `set/3` | `phx-shadcn:set` | Progress, Slider, ToggleGroup |

  ### Overlay

  | Function | Event | Components |
  |----------|-------|------------|
  | `show/2` | `phx-shadcn:show` | Dialog, Popover, Tooltip, HoverCard, Sheet, DropdownMenu |
  | `hide/2` | `phx-shadcn:hide` | Dialog, Popover, Tooltip, HoverCard, Sheet, DropdownMenu |

  ## Compared to component-specific helpers

  Component modules export convenience helpers like `show_dialog/2` and
  `hide_popover/2`. Those still work and are auto-imported via `use PhxShadcn`.
  This module provides a **unified** API when you prefer a single namespace:

      # These are equivalent:
      show_dialog("confirm")
      PhxShadcn.JS.show("confirm")

  ## Usage with `alias`

  The module name is intentionally kept as `PhxShadcn.JS` so you can alias it
  to something short:

      alias PhxShadcn.JS, as: SJS

      <button phx-click={SJS.open("faq", "q1")}>Open Q1</button>
      <button phx-click={SJS.show("my-dialog")}>Open Dialog</button>
      <button phx-click={SJS.select("theme-group", "dark")}>Dark Mode</button>
  """

  alias Phoenix.LiveView.JS

  # ── Collapsible / Accordion ───────────────────────────────────────

  @doc """
  Opens an item. Dispatches `phx-shadcn:open`.

  - **Accordion**: pass the item value (e.g. `"q1"`)
  - **Collapsible**: pass any value (e.g. `"_"`)

  ## Examples

      PhxShadcn.JS.open("my-accordion", "q1")
      JS.push("track") |> PhxShadcn.JS.open("my-accordion", "q1")
  """
  def open(id, value) when is_binary(id), do: open(%JS{}, id, value)

  def open(%JS{} = js, id, value) when is_binary(id) do
    JS.dispatch(js, "phx-shadcn:open", to: "##{id}", detail: %{value: value})
  end

  @doc """
  Closes an item. Dispatches `phx-shadcn:close`.

  - **Accordion**: pass the item value to close
  - **Collapsible**: pass any value (e.g. `"_"`)

  ## Examples

      PhxShadcn.JS.close("my-accordion", "q1")
  """
  def close(id, value) when is_binary(id), do: close(%JS{}, id, value)

  def close(%JS{} = js, id, value) when is_binary(id) do
    JS.dispatch(js, "phx-shadcn:close", to: "##{id}", detail: %{value: value})
  end

  # ── Toggle / Switch / binary state ───────────────────────────────

  @doc """
  Toggles a binary-state component. Dispatches `phx-shadcn:toggle`.

  Works with Toggle, Switch, and Collapsible (flip current state).
  For Accordion/ToggleGroup with a specific value, use `open/3`/`close/3`
  or `select/3`/`deselect/3` instead.

  ## Examples

      PhxShadcn.JS.toggle("my-switch")
      JS.push("track") |> PhxShadcn.JS.toggle("my-toggle")
  """
  def toggle(js \\ %JS{}, id) when is_binary(id) do
    JS.dispatch(js, "phx-shadcn:toggle", to: "##{id}")
  end

  @doc """
  Presses a Toggle. Dispatches `phx-shadcn:press`.

  ## Examples

      PhxShadcn.JS.press("bold-toggle")
  """
  def press(js \\ %JS{}, id) when is_binary(id) do
    JS.dispatch(js, "phx-shadcn:press", to: "##{id}")
  end

  @doc """
  Unpresses a Toggle. Dispatches `phx-shadcn:unpress`.

  ## Examples

      PhxShadcn.JS.unpress("bold-toggle")
  """
  def unpress(js \\ %JS{}, id) when is_binary(id) do
    JS.dispatch(js, "phx-shadcn:unpress", to: "##{id}")
  end

  @doc """
  Checks a Switch. Dispatches `phx-shadcn:check`.

  ## Examples

      PhxShadcn.JS.check("notifications-switch")
  """
  def check(js \\ %JS{}, id) when is_binary(id) do
    JS.dispatch(js, "phx-shadcn:check", to: "##{id}")
  end

  @doc """
  Unchecks a Switch. Dispatches `phx-shadcn:uncheck`.

  ## Examples

      PhxShadcn.JS.uncheck("notifications-switch")
  """
  def uncheck(js \\ %JS{}, id) when is_binary(id) do
    JS.dispatch(js, "phx-shadcn:uncheck", to: "##{id}")
  end

  # ── Selection ─────────────────────────────────────────────────────

  @doc """
  Selects an item. Dispatches `phx-shadcn:select`.

  Works with ToggleGroup and RadioGroup.

  ## Examples

      PhxShadcn.JS.select("theme-group", "dark")
  """
  def select(id, value) when is_binary(id), do: select(%JS{}, id, value)

  def select(%JS{} = js, id, value) when is_binary(id) do
    JS.dispatch(js, "phx-shadcn:select", to: "##{id}", detail: %{value: value})
  end

  @doc """
  Deselects an item. Dispatches `phx-shadcn:deselect`.

  Works with ToggleGroup.

  ## Examples

      PhxShadcn.JS.deselect("theme-group", "dark")
  """
  def deselect(id, value) when is_binary(id), do: deselect(%JS{}, id, value)

  def deselect(%JS{} = js, id, value) when is_binary(id) do
    JS.dispatch(js, "phx-shadcn:deselect", to: "##{id}", detail: %{value: value})
  end

  @doc """
  Activates a tab. Dispatches `phx-shadcn:activate`.

  ## Examples

      PhxShadcn.JS.activate("my-tabs", "settings")
  """
  def activate(id, value) when is_binary(id), do: activate(%JS{}, id, value)

  def activate(%JS{} = js, id, value) when is_binary(id) do
    JS.dispatch(js, "phx-shadcn:activate", to: "##{id}", detail: %{value: value})
  end

  @doc """
  Sets a value directly. Dispatches `phx-shadcn:set`.

  Works with Progress (number), Slider (number or list), and
  ToggleGroup (list for full state replacement).

  ## Examples

      PhxShadcn.JS.set("my-progress", 75)
      PhxShadcn.JS.set("my-slider", 50)
      PhxShadcn.JS.set("my-group", ["A", "C"])
  """
  def set(id, value) when is_binary(id), do: set(%JS{}, id, value)

  def set(%JS{} = js, id, value) when is_binary(id) do
    JS.dispatch(js, "phx-shadcn:set", to: "##{id}", detail: %{value: value})
  end

  # ── Overlay ───────────────────────────────────────────────────────

  @doc """
  Shows an overlay component. Dispatches `phx-shadcn:show`.

  Works with Dialog, Popover, Tooltip, HoverCard, Sheet, DropdownMenu.

  ## Examples

      PhxShadcn.JS.show("my-dialog")
      PhxShadcn.JS.show("my-popover")
  """
  def show(js \\ %JS{}, id) when is_binary(id) do
    JS.dispatch(js, "phx-shadcn:show", to: "##{id}")
  end

  @doc """
  Hides an overlay component. Dispatches `phx-shadcn:hide`.

  Works with Dialog, Popover, Tooltip, HoverCard, Sheet, DropdownMenu.

  ## Examples

      PhxShadcn.JS.hide("my-dialog")
      PhxShadcn.JS.hide("my-popover")
  """
  def hide(js \\ %JS{}, id) when is_binary(id) do
    JS.dispatch(js, "phx-shadcn:hide", to: "##{id}")
  end
end
