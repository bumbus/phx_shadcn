defmodule PhxShadcn.Components.Switch do
  @moduledoc """
  Switch component mirroring shadcn/ui Switch.

  A control that allows the user to toggle between checked and unchecked.
  Renders as a sliding track + thumb. Supports 3 state modes:
  client-only, hybrid, and server-controlled.

  ## State Modes

  - **Client-only** — no `checked` or `on_checked_change`. Pure JS, server unaware.
  - **Hybrid** — `on_checked_change` set, no `checked`. JS toggles instantly + pushes event.
  - **Server-controlled** — `checked` set. Server owns the state.

  ## Examples

      <.switch id="airplane-mode" />

      <.switch id="notifications" default_checked size="sm" />
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  @track_classes [
    "peer inline-flex shrink-0 items-center rounded-full border border-transparent",
    "shadow-xs transition-all outline-none",
    "focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]",
    "disabled:cursor-not-allowed disabled:opacity-50",
    "data-[state=checked]:bg-primary data-[state=unchecked]:bg-input",
    "dark:data-[state=unchecked]:bg-input/80",
    "phx-click-loading:opacity-70 phx-click-loading:pointer-events-none"
  ]

  @track_size_classes %{
    "default" => "h-[1.15rem] w-8",
    "sm" => "h-3.5 w-6"
  }

  @thumb_classes [
    "bg-background pointer-events-none block rounded-full ring-0 transition-transform",
    "dark:data-[state=unchecked]:bg-foreground dark:data-[state=checked]:bg-primary-foreground",
    "data-[state=checked]:translate-x-[calc(100%-2px)] data-[state=unchecked]:translate-x-0"
  ]

  @thumb_size_classes %{
    "default" => "size-4",
    "sm" => "size-3"
  }

  attr :id, :string, required: true
  attr :checked, :boolean, default: nil
  attr :default_checked, :boolean, default: false
  attr :on_checked_change, :any, default: nil
  attr :size, :string, default: "default", values: ~w(default sm)
  attr :disabled, :boolean, default: false
  attr :name, :string, default: nil
  attr :value, :string, default: "on"
  attr :class, :any, default: []
  attr :rest, :global

  def switch(assigns) do
    state_mode =
      cond do
        assigns.checked != nil -> "server"
        assigns.on_checked_change != nil -> "hybrid"
        true -> "client"
      end

    data_state =
      case assigns.checked do
        true -> "checked"
        false -> "unchecked"
        nil -> if assigns.default_checked, do: "checked", else: "unchecked"
      end

    assigns =
      assigns
      |> assign(:state_mode, state_mode)
      |> assign(:data_state, data_state)
      |> assign(
        :track_class,
        cn([
          @track_classes,
          Map.fetch!(@track_size_classes, assigns.size),
          assigns.class
        ])
      )
      |> assign(
        :thumb_class,
        cn([
          @thumb_classes,
          Map.fetch!(@thumb_size_classes, assigns.size)
        ])
      )

    ~H"""
    <button
      id={@id}
      type="button"
      role="switch"
      data-slot="switch"
      data-size={@size}
      data-state={@data_state}
      data-state-mode={@state_mode}
      data-default-checked={to_string(@default_checked)}
      data-on-checked-change={@on_checked_change}
      data-checked-value={@name && @value}
      aria-checked={to_string(@data_state == "checked")}
      disabled={@disabled}
      class={@track_class}
      phx-hook="PhxShadcnSwitch"
      {@rest}
    >
      <span data-slot="switch-thumb" data-state={@data_state} class={@thumb_class} />
      <input
        :if={@name}
        type="hidden"
        name={@name}
        value={if @data_state == "checked", do: @value, else: ""}
      />
    </button>
    """
  end
end
