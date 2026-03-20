defmodule PhxShadcn.Components.Progress do
  @moduledoc """
  Progress component mirroring shadcn/ui Progress.

  Displays an indicator showing the completion progress of a task.
  Supports 3 state modes: client-only, hybrid, and server-controlled.
  When no value is set, renders an indeterminate animation.

  ## State Modes

  - **Client-only** — no `value` or `on_value_change`. Pure JS, server unaware.
  - **Hybrid** — `on_value_change` set, no `value`. JS updates instantly + pushes event.
  - **Server-controlled** — `value` set. Server owns the state.

  ## Examples

      <.progress id="upload" value={45} />

      <.progress id="loading" />

      <.progress id="download" default_value={0} on_value_change="progress:change" />
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  @root_classes [
    "bg-primary/20 relative h-2 w-full overflow-hidden rounded-full"
  ]

  @indicator_classes [
    "bg-primary h-full w-full flex-1 transition-all"
  ]

  @indeterminate_classes [
    "animate-progress-indeterminate"
  ]

  attr :id, :string, required: true
  attr :value, :integer, default: nil
  attr :default_value, :integer, default: nil
  attr :max, :integer, default: 100
  attr :on_value_change, :any, default: nil
  attr :class, :any, default: []
  attr :indicator_class, :any, default: []
  attr :rest, :global

  def progress(assigns) do
    state_mode =
      cond do
        assigns.value != nil -> "server"
        assigns.on_value_change != nil -> "hybrid"
        true -> "client"
      end

    data_state =
      cond do
        assigns.value == nil -> "indeterminate"
        assigns.value >= assigns.max -> "complete"
        true -> "loading"
      end

    indeterminate? = data_state == "indeterminate"

    percentage =
      if assigns.value != nil do
        min(div(assigns.value * 100, assigns.max), 100)
      else
        nil
      end

    assigns =
      assigns
      |> assign(:state_mode, state_mode)
      |> assign(:data_state, data_state)
      |> assign(:indeterminate?, indeterminate?)
      |> assign(:percentage, percentage)
      |> assign(
        :root_class,
        cn([
          @root_classes,
          assigns.class
        ])
      )
      |> assign(
        :indicator_class_merged,
        cn([
          @indicator_classes,
          indeterminate? && @indeterminate_classes,
          assigns.indicator_class
        ])
      )

    ~H"""
    <div
      id={@id}
      role="progressbar"
      data-slot="progress"
      data-state={@data_state}
      data-state-mode={@state_mode}
      data-value={@value}
      data-max={@max}
      data-default-value={@default_value}
      data-on-value-change={@on_value_change}
      aria-valuemin={0}
      aria-valuemax={@max}
      aria-valuenow={@value}
      class={@root_class}
      phx-hook="PhxShadcnProgress"
      {@rest}
    >
      <div
        data-slot="progress-indicator"
        data-state={@data_state}
        class={@indicator_class_merged}
        style={indicator_style(@percentage)}
      />
    </div>
    """
  end

  defp indicator_style(nil), do: "transform: translateX(-100%)"
  defp indicator_style(percentage), do: "transform: translateX(-#{100 - percentage}%)"
end
