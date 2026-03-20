defmodule PhxShadcn.Components.ContextMenu do
  @moduledoc """
  ContextMenu component mirroring shadcn/ui ContextMenu.

  Uses a dedicated `ContextMenu` JS hook — a right-click triggered floating menu
  with cursor-anchored positioning, roving focus, typeahead, and ARIA menu semantics.

  Sub-components: `context_menu/1`, `context_menu_trigger/1`,
  `context_menu_content/1`, `context_menu_item/1`,
  `context_menu_checkbox_item/1`, `context_menu_radio_group/1`,
  `context_menu_radio_item/1`, `context_menu_label/1`,
  `context_menu_separator/1`, `context_menu_shortcut/1`,
  `context_menu_group/1`, `context_menu_sub/1`,
  `context_menu_sub_trigger/1`, `context_menu_sub_content/1`.

  ## Usage

  **Client-only** (no server round-trip):

      <.context_menu id="ctx">
        <.context_menu_trigger>
          <div class="flex h-[150px] w-[300px] items-center justify-center rounded-md border border-dashed text-sm">
            Right click here
          </div>
        </.context_menu_trigger>
        <.context_menu_content>
          <.context_menu_item>Back</.context_menu_item>
          <.context_menu_item>Forward</.context_menu_item>
          <.context_menu_item>Reload</.context_menu_item>
        </.context_menu_content>
      </.context_menu>
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  alias Phoenix.LiveView.JS

  # ── show/hide helpers ──────────────────────────────────────────────

  @doc """
  Returns a `%JS{}` that opens a context menu by id.
  """
  def show_context_menu(js \\ %JS{}, id) do
    JS.dispatch(js, "phx-shadcn:show", to: "##{id}")
  end

  @doc """
  Returns a `%JS{}` that closes a context menu by id.
  """
  def hide_context_menu(js \\ %JS{}, id) do
    JS.dispatch(js, "phx-shadcn:hide", to: "##{id}")
  end

  # ── context_menu (root) ─────────────────────────────────────────────

  @doc """
  Renders a context menu wrapper with the ContextMenu hook.

  ## Attributes

  - `id` (required) — unique identifier
  - `show` — when true, opens on mount
  - `on_open_change` — JS command or event name on dismiss
  - `class` — additional classes
  - `animation_duration` — transition duration in ms (default: 150)
  """

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_open_change, :any, default: nil
  attr :class, :any, default: []
  attr :animation_duration, :integer, default: 150
  attr :rest, :global

  slot :inner_block, required: true

  def context_menu(assigns) do
    ~H"""
    <div
      id={@id}
      data-slot="context-menu"
      data-auto-open={to_string(@show)}
      data-on-open-change={@on_open_change}
      data-animation-duration={@animation_duration}
      class={cn(["relative inline-block", @class])}
      phx-hook="PhxShadcnContextMenu"
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── context_menu_trigger ──────────────────────────────────────────

  @doc """
  Wraps the trigger region where right-clicking opens the menu.
  Unlike DropdownMenu's trigger, this is a plain region (no button wrapper).
  """

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def context_menu_trigger(assigns) do
    ~H"""
    <div
      data-slot="context-menu-trigger"
      data-context-trigger
      tabindex="0"
      class={cn([@class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── context_menu_content ──────────────────────────────────────────

  @doc """
  The floating menu panel, positioned at the cursor.

  ## Attributes

  - `side` — preferred side: `"top"`, `"right"`, `"bottom"` (default), `"left"`
  - `align` — alignment: `"start"` (default), `"center"`, `"end"`
  - `side_offset` — gap from cursor in px (default: 2)
  - `class` — additional classes
  """

  attr :side, :string, default: "bottom"
  attr :align, :string, default: "start"
  attr :side_offset, :integer, default: 2
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def context_menu_content(assigns) do
    ~H"""
    <div
      data-slot="context-menu-content"
      data-context-content
      data-side={@side}
      data-align={@align}
      data-side-offset={@side_offset}
      role="menu"
      aria-orientation="vertical"
      hidden
      class={
        cn([
          "bg-popover text-popover-foreground z-50 min-w-[8rem] overflow-visible rounded-md border p-1 shadow-md outline-hidden",
          "opacity-0 scale-95",
          "data-[side=bottom]:translate-y-1 data-[side=top]:-translate-y-1 data-[side=left]:-translate-x-1 data-[side=right]:translate-x-1",
          "data-[state=open]:opacity-100 data-[state=open]:scale-100 data-[state=open]:translate-x-0 data-[state=open]:translate-y-0",
          "data-[state=closing]:ease-in",
          "transition-[opacity,transform,translate] duration-150 ease-out",
          "data-[side=bottom]:origin-top data-[side=top]:origin-bottom data-[side=left]:origin-right data-[side=right]:origin-left",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── context_menu_item ─────────────────────────────────────────────

  @doc """
  A menu item with `role="menuitem"`.

  ## Attributes

  - `variant` — `"default"` or `"destructive"`
  - `inset` — adds left padding (for alignment with items that have indicators)
  - `disabled` — disables the item
  """

  attr :variant, :string, default: "default"
  attr :inset, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def context_menu_item(assigns) do
    ~H"""
    <div
      data-slot="context-menu-item"
      data-roving-item
      data-variant={@variant}
      data-inset={@inset}
      data-disabled={@disabled}
      role="menuitem"
      tabindex="-1"
      class={
        cn([
          "focus:bg-accent focus:text-accent-foreground hover:bg-accent hover:text-accent-foreground",
          "data-[variant=destructive]:text-destructive data-[variant=destructive]:focus:bg-destructive/10 data-[variant=destructive]:hover:bg-destructive/10 dark:data-[variant=destructive]:focus:bg-destructive/20 dark:data-[variant=destructive]:hover:bg-destructive/20 data-[variant=destructive]:focus:text-destructive data-[variant=destructive]:hover:text-destructive data-[variant=destructive]:*:[svg]:!text-destructive",
          "[&_svg:not([class*='text-'])]:text-muted-foreground",
          "relative flex cursor-default items-center gap-2 rounded-sm px-2 py-1.5 text-sm outline-hidden select-none",
          "data-[disabled]:pointer-events-none data-[disabled]:opacity-50",
          "data-[inset]:pl-8",
          "[&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── context_menu_checkbox_item ────────────────────────────────────

  @doc """
  A toggleable menu item with `role="menuitemcheckbox"`.

  ## Attributes

  - `checked` — boolean, whether the item is checked
  - `disabled` — disables the item
  """

  attr :checked, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def context_menu_checkbox_item(assigns) do
    ~H"""
    <div
      data-slot="context-menu-checkbox-item"
      data-roving-item
      data-keep-open
      data-disabled={@disabled}
      role="menuitemcheckbox"
      aria-checked={to_string(@checked)}
      tabindex="-1"
      class={
        cn([
          "focus:bg-accent focus:text-accent-foreground hover:bg-accent hover:text-accent-foreground",
          "relative flex cursor-default items-center gap-2 rounded-sm py-1.5 pr-2 pl-8 text-sm outline-hidden select-none",
          "data-[disabled]:pointer-events-none data-[disabled]:opacity-50",
          "[&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4",
          @class
        ])
      }
      {@rest}
    >
      <span class="pointer-events-none absolute left-2 flex size-3.5 items-center justify-center opacity-0 [[aria-checked=true]>&]:opacity-100">
        <.check_icon />
      </span>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── context_menu_radio_group ──────────────────────────────────────

  @doc """
  Wraps radio items as a semantic group.
  """

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def context_menu_radio_group(assigns) do
    ~H"""
    <div
      data-slot="context-menu-radio-group"
      role="group"
      class={cn([@class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── context_menu_radio_item ───────────────────────────────────────

  @doc """
  A selectable radio menu item with `role="menuitemradio"`.

  ## Attributes

  - `checked` — boolean, whether the item is selected
  - `disabled` — disables the item
  """

  attr :checked, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def context_menu_radio_item(assigns) do
    ~H"""
    <div
      data-slot="context-menu-radio-item"
      data-roving-item
      data-keep-open
      data-disabled={@disabled}
      role="menuitemradio"
      aria-checked={to_string(@checked)}
      tabindex="-1"
      class={
        cn([
          "focus:bg-accent focus:text-accent-foreground hover:bg-accent hover:text-accent-foreground",
          "relative flex cursor-default items-center gap-2 rounded-sm py-1.5 pr-2 pl-8 text-sm outline-hidden select-none",
          "data-[disabled]:pointer-events-none data-[disabled]:opacity-50",
          "[&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4",
          @class
        ])
      }
      {@rest}
    >
      <span class="pointer-events-none absolute left-2 flex size-3.5 items-center justify-center opacity-0 [[aria-checked=true]>&]:opacity-100">
        <.circle_icon />
      </span>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── context_menu_label ────────────────────────────────────────────

  @doc """
  A non-interactive label for a section of menu items.
  """

  attr :inset, :boolean, default: false
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def context_menu_label(assigns) do
    ~H"""
    <div
      data-slot="context-menu-label"
      data-inset={@inset}
      class={cn(["text-foreground px-2 py-1.5 text-sm font-medium data-[inset]:pl-8", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── context_menu_separator ────────────────────────────────────────

  @doc """
  A visual divider between menu sections.
  """

  attr :class, :any, default: []
  attr :rest, :global

  def context_menu_separator(assigns) do
    ~H"""
    <div
      data-slot="context-menu-separator"
      role="separator"
      class={cn(["bg-border -mx-1 my-1 h-px", @class])}
      {@rest}
    />
    """
  end

  # ── context_menu_shortcut ─────────────────────────────────────────

  @doc """
  A visual hint for a keyboard shortcut, positioned at the end of a menu item.
  """

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def context_menu_shortcut(assigns) do
    ~H"""
    <span
      data-slot="context-menu-shortcut"
      class={cn(["text-muted-foreground ml-auto text-xs tracking-widest", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  # ── context_menu_group ────────────────────────────────────────────

  @doc """
  A semantic grouping of menu items.
  """

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def context_menu_group(assigns) do
    ~H"""
    <div
      data-slot="context-menu-group"
      role="group"
      class={cn([@class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── context_menu_sub ───────────────────────────────────────────────

  @doc """
  Wrapper for a sub-menu. Contains a sub-trigger and sub-content.
  """

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def context_menu_sub(assigns) do
    ~H"""
    <div
      data-slot="context-menu-sub"
      data-context-sub
      class={cn(["relative", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── context_menu_sub_trigger ──────────────────────────────────────

  @doc """
  A menu item that opens a nested sub-menu on hover or ArrowRight.
  Renders a chevron icon on the right.

  ## Attributes

  - `inset` — adds left padding
  - `disabled` — disables the item
  """

  attr :inset, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def context_menu_sub_trigger(assigns) do
    ~H"""
    <div
      data-slot="context-menu-sub-trigger"
      data-roving-item
      data-context-sub-trigger
      data-inset={@inset}
      data-disabled={@disabled}
      role="menuitem"
      aria-haspopup="menu"
      aria-expanded="false"
      tabindex="-1"
      class={
        cn([
          "focus:bg-accent focus:text-accent-foreground hover:bg-accent hover:text-accent-foreground",
          "data-[state=open]:bg-accent data-[state=open]:text-accent-foreground",
          "[&_svg:not([class*='text-'])]:text-muted-foreground",
          "flex cursor-default items-center gap-2 rounded-sm px-2 py-1.5 text-sm outline-hidden select-none",
          "data-[disabled]:pointer-events-none data-[disabled]:opacity-50",
          "data-[inset]:pl-8",
          "[&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
      <.chevron_right_icon />
    </div>
    """
  end

  # ── context_menu_sub_content ──────────────────────────────────────

  @doc """
  The floating panel for a sub-menu. Positioned to the right of its sub-trigger.

  ## Attributes

  - `side` — preferred side (default: `"right"`)
  - `align` — alignment (default: `"start"`)
  - `side_offset` — gap in px (default: -4, overlaps slightly like shadcn)
  - `class` — additional classes
  """

  attr :side, :string, default: "right"
  attr :align, :string, default: "start"
  attr :side_offset, :integer, default: -4
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def context_menu_sub_content(assigns) do
    ~H"""
    <div
      data-slot="context-menu-sub-content"
      data-context-sub-content
      data-side={@side}
      data-align={@align}
      data-side-offset={@side_offset}
      role="menu"
      aria-orientation="vertical"
      hidden
      class={
        cn([
          "bg-popover text-popover-foreground z-50 min-w-[8rem] overflow-hidden rounded-md border p-1 shadow-lg outline-hidden",
          "opacity-0 scale-95",
          "data-[side=bottom]:translate-y-1 data-[side=top]:-translate-y-1 data-[side=left]:-translate-x-1 data-[side=right]:translate-x-1",
          "data-[state=open]:opacity-100 data-[state=open]:scale-100 data-[state=open]:translate-x-0 data-[state=open]:translate-y-0",
          "transition-[opacity,transform,translate] duration-150 ease-out",
          "data-[side=bottom]:origin-top data-[side=top]:origin-bottom data-[side=left]:origin-right data-[side=right]:origin-left",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── Icons (inline SVG) ─────────────────────────────────────────────

  defp check_icon(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="16"
      height="16"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      class="size-4"
    >
      <path d="M20 6 9 17l-5-5" />
    </svg>
    """
  end

  defp chevron_right_icon(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="16"
      height="16"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      class="ml-auto size-4"
    >
      <path d="m9 18 6-6-6-6" />
    </svg>
    """
  end

  defp circle_icon(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="8"
      height="8"
      viewBox="0 0 24 24"
      fill="currentColor"
      stroke="currentColor"
      stroke-width="2"
      class="size-2"
    >
      <circle cx="12" cy="12" r="10" />
    </svg>
    """
  end
end
