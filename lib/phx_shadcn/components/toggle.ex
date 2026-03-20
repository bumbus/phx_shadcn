defmodule PhxShadcn.Components.Toggle do
  @moduledoc """
  Toggle component mirroring shadcn/ui Toggle.

  A two-state button that can be toggled on or off. Supports 3 state modes:
  client-only, hybrid, and server-controlled.

  ## State Modes

  - **Client-only** — no `pressed` or `on_pressed_change`. Pure JS, server unaware.
  - **Hybrid** — `on_pressed_change` set, no `pressed`. JS toggles instantly + pushes event.
  - **Server-controlled** — `pressed` set. Server owns the state.

  ## Examples

      <.toggle id="bold-toggle">
        <svg>...</svg>
      </.toggle>

      <.toggle id="italic" variant="outline" size="sm" default_pressed>
        I
      </.toggle>
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  @base_classes [
    "inline-flex items-center justify-center gap-2 rounded-md text-sm font-medium",
    "transition-colors hover:bg-muted hover:text-muted-foreground",
    "focus-visible:outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]",
    "disabled:pointer-events-none disabled:opacity-50",
    "[&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4",
    "data-[state=on]:bg-accent data-[state=on]:text-accent-foreground",
    "phx-click-loading:opacity-70 phx-click-loading:pointer-events-none"
  ]

  @variant_classes %{
    "default" => "bg-transparent",
    "outline" =>
      "border border-input bg-transparent shadow-xs hover:bg-accent hover:text-accent-foreground"
  }

  @size_classes %{
    "default" => "h-9 px-2 min-w-9",
    "sm" => "h-8 px-1.5 min-w-8",
    "lg" => "h-10 px-2.5 min-w-10"
  }

  attr :id, :string, required: true
  attr :pressed, :boolean, default: nil
  attr :default_pressed, :boolean, default: false
  attr :on_pressed_change, :any, default: nil
  attr :variant, :string, default: "default", values: ~w(default outline)
  attr :size, :string, default: "default", values: ~w(default sm lg)
  attr :disabled, :boolean, default: false
  attr :name, :string, default: nil
  attr :value, :string, default: "on"
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def toggle(assigns) do
    state_mode =
      cond do
        assigns.pressed != nil -> "server"
        assigns.on_pressed_change != nil -> "hybrid"
        true -> "client"
      end

    data_state =
      case assigns.pressed do
        true -> "on"
        false -> "off"
        nil -> if assigns.default_pressed, do: "on", else: "off"
      end

    assigns =
      assigns
      |> assign(:state_mode, state_mode)
      |> assign(:data_state, data_state)
      |> assign(
        :computed_class,
        cn([
          @base_classes,
          Map.fetch!(@variant_classes, assigns.variant),
          Map.fetch!(@size_classes, assigns.size),
          assigns.class
        ])
      )

    assigns = assign(assigns, :hidden_value, if(data_state == "on", do: assigns.value, else: ""))

    ~H"""
    <button
      id={@id}
      type="button"
      data-slot="toggle"
      data-variant={@variant}
      data-size={@size}
      data-state={@data_state}
      data-state-mode={@state_mode}
      data-default-pressed={to_string(@default_pressed)}
      data-on-pressed-change={@on_pressed_change}
      data-pressed-value={@name && @value}
      aria-pressed={to_string(@data_state == "on")}
      disabled={@disabled}
      class={@computed_class}
      phx-hook="PhxShadcnToggle"
      {@rest}
    >
      {render_slot(@inner_block)}
      <input :if={@name} type="hidden" name={@name} value={@hidden_value} />
    </button>
    """
  end
end
