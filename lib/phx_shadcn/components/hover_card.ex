defmodule PhxShadcn.Components.HoverCard do
  @moduledoc """
  HoverCard component mirroring shadcn/ui HoverCard.

  Uses the `Floating` JS hook with hover/focus triggers. Like Tooltip's trigger
  behavior (hover/focus) with Popover's visual style (card-like: border, shadow,
  `bg-popover`, `w-64`). Content stays open while hovering it thanks to the
  Floating hook's grace period.

  Sub-components: `hover_card/1`, `hover_card_trigger/1`, `hover_card_content/1`.

  ## Usage

      <.hover_card id="hc">
        <.hover_card_trigger>
          <a href="#">@username</a>
        </.hover_card_trigger>
        <.hover_card_content>
          <p>User profile info here</p>
        </.hover_card_content>
      </.hover_card>
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  alias Phoenix.LiveView.JS

  # ── show/hide helpers ──────────────────────────────────────────────

  @doc """
  Returns a `%JS{}` that opens a hover card by id.
  """
  def show_hover_card(js \\ %JS{}, id) do
    JS.dispatch(js, "phx-shadcn:show", to: "##{id}")
  end

  @doc """
  Returns a `%JS{}` that closes a hover card by id.
  """
  def hide_hover_card(js \\ %JS{}, id) do
    JS.dispatch(js, "phx-shadcn:hide", to: "##{id}")
  end

  # ── hover_card (root) ─────────────────────────────────────────────

  @doc """
  Renders a hover card wrapper with the Floating hook in hover mode.

  ## Attributes

  - `id` (required) — unique identifier
  - `open_delay` — ms before showing on hover (default: 500)
  - `close_delay` — ms before hiding on mouseleave (default: 300)
  - `class` — additional classes for the wrapper
  """

  attr :id, :string, required: true
  attr :open_delay, :integer, default: 500
  attr :close_delay, :integer, default: 300
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def hover_card(assigns) do
    ~H"""
    <div
      id={@id}
      data-slot="hover-card"
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

  # ── hover_card_trigger ────────────────────────────────────────────

  @doc """
  Wraps the trigger element that shows the hover card on hover/focus.
  """

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def hover_card_trigger(assigns) do
    ~H"""
    <div data-slot="hover-card-trigger" data-floating-trigger class={cn(["inline-flex", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── hover_card_content ────────────────────────────────────────────

  @doc """
  The floating content panel of the hover card.

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

  def hover_card_content(assigns) do
    ~H"""
    <div
      data-slot="hover-card-content"
      data-floating-content
      data-side={@side}
      data-align={@align}
      data-side-offset={@side_offset}
      hidden
      class={
        cn([
          "bg-popover text-popover-foreground z-50 w-64 rounded-md border p-4 shadow-md outline-hidden",
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
end
