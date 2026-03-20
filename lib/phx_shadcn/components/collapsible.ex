defmodule PhxShadcn.Components.Collapsible do
  @moduledoc """
  Collapsible component mirroring shadcn/ui Collapsible.

  A single expandable/collapsible section. Simpler cousin of Accordion — no items,
  no single/multiple modes, just one trigger and one content area.

  Reuses the same `Collapsible` JS hook as Accordion.

  Sub-components: `collapsible/1`, `collapsible_trigger/1`, `collapsible_content/1`.

  ## State Modes

  - **Client-only** — no `open` or `on_open_change`. Pure JS, server unaware.
  - **Hybrid** — `on_open_change` set, no `open`. JS toggles instantly + pushes event.
  - **Server-controlled** — `open` set. Server owns the state.

  ## Examples

      <.collapsible id="details">
        <.collapsible_trigger>
          <.button variant="ghost" size="sm">Toggle</.button>
        </.collapsible_trigger>
        <.collapsible_content>
          <p>Hidden content revealed on click.</p>
        </.collapsible_content>
      </.collapsible>
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  # --- Collapsible (root) ---

  attr :id, :string, required: true
  attr :open, :boolean, default: nil
  attr :default_open, :boolean, default: false
  attr :on_open_change, :any, default: nil
  attr :animation_duration, :integer, default: 200
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def collapsible(assigns) do
    state_mode =
      cond do
        assigns.open != nil -> "server"
        assigns.on_open_change != nil -> "hybrid"
        true -> "client"
      end

    # The hook expects comma-separated values in data-value/data-default-value.
    # For Collapsible we use a single synthetic value "_" to represent the one item.
    value_str =
      case assigns.open do
        true -> "_"
        false -> ""
        nil -> nil
      end

    default_value_str = if assigns.default_open, do: "_", else: nil

    duration_style =
      if assigns.animation_duration != 200 do
        "--accordion-duration: #{assigns.animation_duration}ms"
      end

    assigns =
      assigns
      |> assign(:state_mode, state_mode)
      |> assign(:value_str, value_str)
      |> assign(:default_value_str, default_value_str)
      |> assign(:duration_style, duration_style)
      |> assign(:computed_class, cn(assigns.class))

    ~H"""
    <div
      id={@id}
      data-slot="collapsible"
      data-type="single"
      data-collapsible="true"
      data-state-mode={@state_mode}
      data-value={@value_str}
      data-default-value={@default_value_str}
      data-on-value-change={@on_open_change}
      data-item-selector="[data-slot=collapsible-item]"
      data-trigger-selector="[data-slot=collapsible-trigger]"
      data-content-selector="[data-slot=collapsible-content]"
      style={@duration_style}
      class={@computed_class}
      phx-hook="PhxShadcnCollapsible"
      {@rest}
    >
      <div data-slot="collapsible-item" data-value="_" data-state="closed">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  # --- CollapsibleTrigger ---

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def collapsible_trigger(assigns) do
    assigns = assign(assigns, :computed_class, cn(assigns.class))

    ~H"""
    <div data-slot="collapsible-trigger" data-state="closed" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # --- CollapsibleContent ---

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def collapsible_content(assigns) do
    assigns = assign(assigns, :computed_class, cn(assigns.class))

    ~H"""
    <div
      data-slot="collapsible-content"
      data-state="closed"
      class={["overflow-hidden data-[state=open]:animate-accordion-down data-[state=closed]:animate-accordion-up", @computed_class]}
      style="display:none"
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
