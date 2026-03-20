defmodule PhxShadcn.Components.Menubar do
  @moduledoc """
  Menubar component mirroring shadcn/ui Menubar.

  A horizontal menu bar (File/Edit/View pattern) with multi-menu coordination,
  hover-to-switch, cross-menu keyboard navigation, sub-menus, checkbox/radio
  items, and full ARIA menubar semantics.

  Sub-components: `menubar/1`, `menubar_menu/1`, `menubar_trigger/1`,
  `menubar_content/1`, `menubar_item/1`, `menubar_checkbox_item/1`,
  `menubar_radio_group/1`, `menubar_radio_item/1`, `menubar_label/1`,
  `menubar_separator/1`, `menubar_shortcut/1`, `menubar_group/1`,
  `menubar_sub/1`, `menubar_sub_trigger/1`, `menubar_sub_content/1`.

  ## Usage

      <.menubar id="main-menubar">
        <.menubar_menu>
          <.menubar_trigger>File</.menubar_trigger>
          <.menubar_content>
            <.menubar_item>New Tab <.menubar_shortcut>⌘T</.menubar_shortcut></.menubar_item>
            <.menubar_item>New Window <.menubar_shortcut>⌘N</.menubar_shortcut></.menubar_item>
            <.menubar_separator />
            <.menubar_item>Print... <.menubar_shortcut>⌘P</.menubar_shortcut></.menubar_item>
          </.menubar_content>
        </.menubar_menu>

        <.menubar_menu>
          <.menubar_trigger>Edit</.menubar_trigger>
          <.menubar_content>
            <.menubar_item>Undo <.menubar_shortcut>⌘Z</.menubar_shortcut></.menubar_item>
            <.menubar_item>Redo <.menubar_shortcut>⇧⌘Z</.menubar_shortcut></.menubar_item>
          </.menubar_content>
        </.menubar_menu>
      </.menubar>
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  # ── menubar (root) ──────────────────────────────────────────────────

  @doc """
  Renders the menubar root with `role="menubar"` and the Menubar JS hook.

  ## Attributes

  - `id` (required) — unique identifier
  - `class` — additional classes
  - `animation_duration` — transition duration in ms (default: 150)
  """

  attr :id, :string, required: true
  attr :class, :any, default: []
  attr :animation_duration, :integer, default: 150
  attr :rest, :global

  slot :inner_block, required: true

  def menubar(assigns) do
    ~H"""
    <div
      id={@id}
      data-slot="menubar"
      data-animation-duration={@animation_duration}
      role="menubar"
      class={
        cn([
          "flex h-9 items-center gap-1 rounded-md border bg-background p-1 shadow-xs",
          @class
        ])
      }
      phx-hook="PhxShadcnMenubar"
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── menubar_menu ────────────────────────────────────────────────────

  @doc """
  Wrapper for each trigger+content pair inside the menubar.
  """

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def menubar_menu(assigns) do
    ~H"""
    <div
      data-slot="menubar-menu"
      data-menubar-menu
      class={cn(["relative", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── menubar_trigger ─────────────────────────────────────────────────

  @doc """
  A trigger button for a menubar menu. Renders a `<button>` with
  `role="menuitem"` and menubar-appropriate styling.
  """

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def menubar_trigger(assigns) do
    ~H"""
    <button
      data-slot="menubar-trigger"
      data-menubar-trigger
      type="button"
      role="menuitem"
      aria-haspopup="menu"
      aria-expanded="false"
      class={
        cn([
          "flex items-center rounded-sm px-3 py-1 text-sm font-medium outline-hidden select-none cursor-default",
          "focus:bg-accent focus:text-accent-foreground",
          "data-[state=open]:bg-accent data-[state=open]:text-accent-foreground",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  # ── menubar_content ─────────────────────────────────────────────────

  @doc """
  The floating menu panel for a menubar menu.

  ## Attributes

  - `side` — preferred side (default: `"bottom"`)
  - `align` — alignment (default: `"start"`)
  - `side_offset` — gap between trigger and content in px (default: 8)
  - `align_offset` — cross-axis offset in px (default: -4)
  - `class` — additional classes
  """

  attr :side, :string, default: "bottom"
  attr :align, :string, default: "start"
  attr :side_offset, :integer, default: 8
  attr :align_offset, :integer, default: -4
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def menubar_content(assigns) do
    ~H"""
    <div
      data-slot="menubar-content"
      data-menubar-content
      data-side={@side}
      data-align={@align}
      data-side-offset={@side_offset}
      data-align-offset={@align_offset}
      role="menu"
      aria-orientation="vertical"
      hidden
      class={
        cn([
          "bg-popover text-popover-foreground z-50 min-w-[12rem] overflow-visible rounded-md border p-1 shadow-md outline-hidden",
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

  # ── menubar_item ────────────────────────────────────────────────────

  @doc """
  A menu item with `role="menuitem"`.

  ## Attributes

  - `variant` — `"default"` or `"destructive"`
  - `inset` — adds left padding
  - `disabled` — disables the item
  """

  attr :variant, :string, default: "default"
  attr :inset, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def menubar_item(assigns) do
    ~H"""
    <div
      data-slot="menubar-item"
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

  # ── menubar_checkbox_item ───────────────────────────────────────────

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

  def menubar_checkbox_item(assigns) do
    ~H"""
    <div
      data-slot="menubar-checkbox-item"
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

  # ── menubar_radio_group ─────────────────────────────────────────────

  @doc """
  Wraps radio items as a semantic group.
  """

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def menubar_radio_group(assigns) do
    ~H"""
    <div
      data-slot="menubar-radio-group"
      role="group"
      class={cn([@class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── menubar_radio_item ──────────────────────────────────────────────

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

  def menubar_radio_item(assigns) do
    ~H"""
    <div
      data-slot="menubar-radio-item"
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

  # ── menubar_label ───────────────────────────────────────────────────

  @doc """
  A non-interactive label for a section of menu items.
  """

  attr :inset, :boolean, default: false
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def menubar_label(assigns) do
    ~H"""
    <div
      data-slot="menubar-label"
      data-inset={@inset}
      class={cn(["text-foreground px-2 py-1.5 text-sm font-medium data-[inset]:pl-8", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── menubar_separator ──────────────────────────────────────────────

  @doc """
  A visual divider between menu sections.
  """

  attr :class, :any, default: []
  attr :rest, :global

  def menubar_separator(assigns) do
    ~H"""
    <div
      data-slot="menubar-separator"
      role="separator"
      class={cn(["bg-border -mx-1 my-1 h-px", @class])}
      {@rest}
    />
    """
  end

  # ── menubar_shortcut ───────────────────────────────────────────────

  @doc """
  A visual hint for a keyboard shortcut, positioned at the end of a menu item.
  """

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def menubar_shortcut(assigns) do
    ~H"""
    <span
      data-slot="menubar-shortcut"
      class={cn(["text-muted-foreground ml-auto text-xs tracking-widest", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  # ── menubar_group ──────────────────────────────────────────────────

  @doc """
  A semantic grouping of menu items.
  """

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def menubar_group(assigns) do
    ~H"""
    <div
      data-slot="menubar-group"
      role="group"
      class={cn([@class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── menubar_sub ────────────────────────────────────────────────────

  @doc """
  Wrapper for a sub-menu. Contains a sub-trigger and sub-content.
  """

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def menubar_sub(assigns) do
    ~H"""
    <div
      data-slot="menubar-sub"
      data-menubar-sub
      class={cn(["relative", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── menubar_sub_trigger ────────────────────────────────────────────

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

  def menubar_sub_trigger(assigns) do
    ~H"""
    <div
      data-slot="menubar-sub-trigger"
      data-roving-item
      data-menubar-sub-trigger
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

  # ── menubar_sub_content ────────────────────────────────────────────

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

  def menubar_sub_content(assigns) do
    ~H"""
    <div
      data-slot="menubar-sub-content"
      data-menubar-sub-content
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
