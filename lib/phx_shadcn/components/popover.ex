defmodule PhxShadcn.Components.Popover do
  @moduledoc """
  Popover component mirroring shadcn/ui Popover.

  Uses the `Floating` JS hook with Floating UI for anchor-based positioning.
  Content is positioned relative to the trigger with flip/shift middleware.

  Sub-components: `popover/1`, `popover_trigger/1`, `popover_content/1`,
  `popover_header/1`, `popover_title/1`, `popover_description/1`, `popover_close/1`.

  ## Usage Patterns

  **Client-only** (no server round-trip):

      <.popover id="pop">
        <.popover_trigger>
          <.button>Open</.button>
        </.popover_trigger>
        <.popover_content>
          <.popover_header>
            <.popover_title>Dimensions</.popover_title>
            <.popover_description>Set the dimensions.</.popover_description>
          </.popover_header>
          <p>Content here</p>
        </.popover_content>
      </.popover>

  **Server-controlled** (`:if` + `show` pattern):

      <.popover :if={@show_pop} id="pop" show on_open_change={JS.push("close_pop")}>
        <.popover_trigger>
          <.button>Open</.button>
        </.popover_trigger>
        <.popover_content>
          <p>Content here</p>
        </.popover_content>
      </.popover>
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  alias Phoenix.LiveView.JS

  # ── show/hide helpers ──────────────────────────────────────────────

  @doc """
  Returns a `%JS{}` that opens a popover by id.

  Dispatches `phx-shadcn:show` to the popover element, which the hook
  handles by positioning and showing the content.
  """
  def show_popover(js \\ %JS{}, id) do
    JS.dispatch(js, "phx-shadcn:show", to: "##{id}")
  end

  @doc """
  Returns a `%JS{}` that closes a popover by id.

  Dispatches `phx-shadcn:hide` to the popover element, which the hook
  handles by animating out and hiding the content.
  """
  def hide_popover(js \\ %JS{}, id) do
    JS.dispatch(js, "phx-shadcn:hide", to: "##{id}")
  end

  # ── popover (root) ─────────────────────────────────────────────────

  @doc """
  Renders a popover wrapper with the Floating hook.

  ## Attributes

  - `id` (required) — unique identifier
  - `show` — when true, opens on mount (for `:if` pattern)
  - `on_open_change` — JS command or event name on dismiss (Escape, click outside, close button)
  - `class` — additional classes for the wrapper
  - `animation_duration` — transition duration in ms (default: 150)
  """

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_open_change, :any, default: nil
  attr :class, :any, default: []
  attr :animation_duration, :integer, default: 200
  attr :rest, :global

  slot :inner_block, required: true

  def popover(assigns) do
    duration_style =
      if assigns.animation_duration != 200 do
        "--popover-duration: #{assigns.animation_duration}ms"
      end

    assigns = assign(assigns, :duration_style, duration_style)

    ~H"""
    <div
      id={@id}
      data-slot="popover"
      data-trigger-type="click"
      data-auto-open={to_string(@show)}
      data-on-open-change={@on_open_change}
      data-animation-duration={@animation_duration}
      style={@duration_style}
      class={cn(["relative inline-block", @class])}
      phx-hook="PhxShadcnFloating"
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── popover_trigger ────────────────────────────────────────────────

  @doc """
  Wraps the trigger element that opens/closes the popover on click.
  """

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def popover_trigger(assigns) do
    ~H"""
    <div data-slot="popover-trigger" data-floating-trigger class={cn(["inline-flex", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── popover_content ────────────────────────────────────────────────

  @doc """
  The floating content panel of the popover.

  ## Attributes

  - `side` — preferred side: `"top"`, `"right"`, `"bottom"` (default), `"left"`
  - `align` — alignment: `"start"`, `"center"` (default), `"end"`
  - `side_offset` — gap between trigger and content in px (default: 4)
  - `class` — additional classes
  """

  attr :side, :string, default: "bottom"
  attr :align, :string, default: "center"
  attr :side_offset, :integer, default: 4
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def popover_content(assigns) do
    ~H"""
    <div
      data-slot="popover-content"
      data-floating-content
      data-side={@side}
      data-align={@align}
      data-side-offset={@side_offset}
      hidden
      class={
        cn([
          "bg-popover text-popover-foreground z-50 w-72 rounded-md border p-4 shadow-md outline-hidden",
          "opacity-0 scale-95",
          "data-[side=bottom]:translate-y-1 data-[side=top]:-translate-y-1 data-[side=left]:-translate-x-1 data-[side=right]:translate-x-1",
          "data-[state=open]:opacity-100 data-[state=open]:scale-100 data-[state=open]:translate-x-0 data-[state=open]:translate-y-0",
          "data-[state=closing]:ease-in",
          "transition-[opacity,transform,translate] duration-[var(--popover-duration,200ms)] ease-out",
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

  # ── popover_header ─────────────────────────────────────────────────

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def popover_header(assigns) do
    ~H"""
    <div data-slot="popover-header" class={cn(["flex flex-col gap-1 text-sm", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── popover_title ──────────────────────────────────────────────────

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def popover_title(assigns) do
    ~H"""
    <div data-slot="popover-title" class={cn(["font-medium", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── popover_description ────────────────────────────────────────────

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def popover_description(assigns) do
    ~H"""
    <p data-slot="popover-description" class={cn(["text-muted-foreground", @class])} {@rest}>
      {render_slot(@inner_block)}
    </p>
    """
  end

  # ── popover_close ──────────────────────────────────────────────────

  @doc """
  Wraps children that should dismiss the popover on click.

  Pass the same `on_open_change` value as the parent popover.
  """

  attr :class, :any, default: []
  attr :on_open_change, :any, default: nil, doc: "JS command chain to execute on click"
  attr :rest, :global

  slot :inner_block, required: true

  def popover_close(assigns) do
    ~H"""
    <div data-slot="popover-close" class={cn(["contents", @class])} phx-click={@on_open_change} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
