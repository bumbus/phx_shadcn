defmodule PhxShadcn.Components.Tooltip do
  @moduledoc """
  Tooltip component mirroring shadcn/ui Tooltip.

  Uses the `Floating` JS hook with hover/focus triggers for anchor-based
  positioning. Content appears on hover after a delay and on focus immediately.

  Sub-components: `tooltip/1`, `tooltip_trigger/1`, `tooltip_content/1`.

  ## Usage

      <.tooltip id="tt">
        <.tooltip_trigger>
          <.button variant="outline">Hover me</.button>
        </.tooltip_trigger>
        <.tooltip_content>
          Add to library
        </.tooltip_content>
      </.tooltip>
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  alias Phoenix.LiveView.JS

  # ── show/hide helpers ──────────────────────────────────────────────

  @doc """
  Returns a `%JS{}` that opens a tooltip by id.
  """
  def show_tooltip(js \\ %JS{}, id) do
    JS.dispatch(js, "phx-shadcn:show", to: "##{id}")
  end

  @doc """
  Returns a `%JS{}` that closes a tooltip by id.
  """
  def hide_tooltip(js \\ %JS{}, id) do
    JS.dispatch(js, "phx-shadcn:hide", to: "##{id}")
  end

  # ── tooltip (root) ─────────────────────────────────────────────────

  @doc """
  Renders a tooltip wrapper with the Floating hook in hover mode.

  ## Attributes

  - `id` (required) — unique identifier
  - `open_delay` — ms before showing on hover (default: 200)
  - `close_delay` — ms before hiding on mouseleave (default: 100)
  - `class` — additional classes for the wrapper
  """

  attr :id, :string, required: true
  attr :open_delay, :integer, default: 200
  attr :close_delay, :integer, default: 100
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def tooltip(assigns) do
    ~H"""
    <div
      id={@id}
      data-slot="tooltip"
      data-trigger-type="hover"
      data-open-delay={@open_delay}
      data-close-delay={@close_delay}
      data-animation-duration="150"
      class={cn(["relative inline-block", @class])}
      phx-hook="PhxShadcnFloating"
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── tooltip_trigger ────────────────────────────────────────────────

  @doc """
  Wraps the trigger element that shows the tooltip on hover/focus.
  """

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def tooltip_trigger(assigns) do
    ~H"""
    <div data-slot="tooltip-trigger" data-floating-trigger class={cn(["inline-flex", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── tooltip_content ────────────────────────────────────────────────

  @doc """
  The floating content panel of the tooltip.

  ## Attributes

  - `side` — preferred side: `"top"` (default), `"right"`, `"bottom"`, `"left"`
  - `align` — alignment: `"start"`, `"center"` (default), `"end"`
  - `side_offset` — gap between trigger and content in px (default: 4)
  - `class` — additional classes
  """

  attr :side, :string, default: "top"
  attr :align, :string, default: "center"
  attr :side_offset, :integer, default: 10
  attr :arrow, :boolean, default: true
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def tooltip_content(assigns) do
    ~H"""
    <div
      data-slot="tooltip-content"
      data-floating-content
      data-side={@side}
      data-align={@align}
      data-side-offset={@side_offset}
      role="tooltip"
      hidden
      class={
        cn([
          "bg-primary text-primary-foreground z-50 w-fit rounded-md px-3 py-1.5 text-xs text-balance outline-hidden",
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
      <span
        :if={@arrow}
        data-slot="tooltip-arrow"
        class={
          cn([
            "bg-primary z-50 size-2.5 rotate-45 rounded-[2px]",
            "absolute",
            "data-[side=bottom]:-top-1 data-[side=bottom]:left-1/2 data-[side=bottom]:-translate-x-1/2",
            "data-[side=top]:-bottom-1 data-[side=top]:left-1/2 data-[side=top]:-translate-x-1/2",
            "data-[side=left]:-right-1 data-[side=left]:top-1/2 data-[side=left]:-translate-y-1/2",
            "data-[side=right]:-left-1 data-[side=right]:top-1/2 data-[side=right]:-translate-y-1/2"
          ])
        }
      />
    </div>
    """
  end
end
