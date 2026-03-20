defmodule PhxShadcn.Components.Slider do
  @moduledoc """
  Slider component mirroring shadcn/ui Slider.

  A draggable range input for selecting numeric values. Supports single-thumb
  and multi-thumb (range) modes. Supports 3 state modes: client-only, hybrid,
  and server-controlled.

  ## Multi-Thumb / Range

  Pass a list to `default_value` or `value` for multiple thumbs:

      <.slider id="range" default_value={[25, 50]} />
      <.slider id="multi" default_value={[10, 20, 70]} />

  Single integer values still work (wrapped to a single-element list internally).

  ## State Modes

  - **Client-only** — no `value` or `on_value_change`. Pure JS, server unaware.
  - **Hybrid** — `on_value_change` set, no `value`. JS updates instantly + pushes event.
  - **Server-controlled** — `value` set. Server owns the state.

  ## Examples

      <.slider id="volume" default_value={50} />

      <.slider id="brightness" value={@brightness} on_value_change="brightness:change" />

      <.slider id="range" default_value={[25, 50]} step={5} />

      <.slider id="vertical-slider" orientation="vertical" default_value={50} class="h-44" />
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  @root_classes [
    "relative flex w-full touch-none items-center select-none",
    "data-[disabled]:opacity-50 data-[disabled]:pointer-events-none",
    "data-[orientation=vertical]:h-full data-[orientation=vertical]:min-h-44",
    "data-[orientation=vertical]:w-auto data-[orientation=vertical]:flex-col"
  ]

  @track_classes [
    "bg-muted relative grow overflow-hidden rounded-full",
    "data-[orientation=horizontal]:h-1.5 data-[orientation=horizontal]:w-full",
    "data-[orientation=vertical]:h-full data-[orientation=vertical]:w-1.5"
  ]

  @range_classes [
    "bg-primary absolute",
    "data-[orientation=horizontal]:h-full",
    "data-[orientation=vertical]:w-full"
  ]

  @thumb_classes [
    "border-primary ring-ring/50 block size-4 shrink-0 rounded-full border",
    "bg-white shadow-sm transition-[color,box-shadow,left,bottom] duration-150",
    "data-[dragging]:transition-none",
    "hover:ring-4 focus-visible:ring-4 focus-visible:outline-hidden",
    "disabled:pointer-events-none disabled:opacity-50"
  ]

  attr :id, :string, required: true
  attr :value, :any, default: nil, doc: "number | [number] | nil — server-controlled value(s)"
  attr :default_value, :any, default: 0, doc: "number | [number] — initial value(s)"
  attr :min, :any, default: 0, doc: "integer | float — minimum value"
  attr :max, :any, default: 100, doc: "integer | float — maximum value"
  attr :step, :any, default: 1, doc: "integer | float — step increment"
  attr :orientation, :string, default: "horizontal", values: ~w(horizontal vertical)
  attr :disabled, :boolean, default: false
  attr :on_value_change, :any, default: nil
  attr :name, :string, default: nil
  attr :class, :any, default: []
  attr :track_class, :any, default: []
  attr :range_class, :any, default: []
  attr :thumb_class, :any, default: []
  attr :rest, :global

  def slider(assigns) do
    state_mode =
      cond do
        assigns.value != nil -> "server"
        assigns.on_value_change != nil -> "hybrid"
        true -> "client"
      end

    values = normalize_values(assigns.value || assigns.default_value)
    default_values = normalize_values(assigns.default_value)

    min_val = to_number(assigns.min)
    max_val = to_number(assigns.max)
    range = max_val - min_val

    percentages =
      Enum.map(values, fn v ->
        if range > 0, do: min(max((v - min_val) / range * 100, 0), 100), else: 0
      end)

    min_pct = Enum.min(percentages)
    max_pct = Enum.max(percentages)

    multi = match?([_, _ | _], values)

    assigns =
      assigns
      |> assign(:state_mode, state_mode)
      |> assign(:multi, multi)
      |> assign(:values, values)
      |> assign(:default_values, default_values)
      |> assign(:percentages, percentages)
      |> assign(:min_pct, min_pct)
      |> assign(:max_pct, max_pct)
      |> assign(:root_class, cn([@root_classes, assigns.class]))
      |> assign(:track_class_merged, cn([@track_classes, assigns.track_class]))
      |> assign(:range_class_merged, cn([@range_classes, assigns.range_class]))
      |> assign(:thumb_class_merged, cn([@thumb_classes, assigns.thumb_class]))

    ~H"""
    <div
      id={@id}
      role="group"
      data-slot="slider"
      data-state-mode={@state_mode}
      data-values={Enum.join(@values, ",")}
      data-default-values={Enum.join(@default_values, ",")}
      data-value={hd(@values)}
      data-default-value={hd(@default_values)}
      data-min={@min}
      data-max={@max}
      data-step={@step}
      data-orientation={@orientation}
      data-on-value-change={@on_value_change}
      data-disabled={@disabled || nil}
      aria-orientation={@orientation}
      aria-disabled={if @disabled, do: "true", else: nil}
      class={@root_class}
      phx-hook="PhxShadcnSlider"
      {@rest}
    >
      <div
        data-slot="slider-track"
        data-orientation={@orientation}
        class={@track_class_merged}
      >
        <div
          data-slot="slider-range"
          data-orientation={@orientation}
          class={@range_class_merged}
          style={range_style(@orientation, @min_pct, @max_pct)}
        />
      </div>
      <div
        :for={{value, index} <- Enum.with_index(@values)}
        data-slot="slider-thumb"
        role="slider"
        tabindex={if @disabled, do: nil, else: "0"}
        aria-valuenow={value}
        aria-valuemin={@min}
        aria-valuemax={@max}
        data-thumb-index={index}
        class={@thumb_class_merged}
        style={thumb_style(@orientation, Enum.at(@percentages, index))}
      />
      <%= if @name do %>
        <input :if={!@multi} type="hidden" name={@name} value={hd(@values)} />
        <input :for={value <- if(@multi, do: @values, else: [])} type="hidden" name={@name <> "[]"} value={value} />
      <% end %>
    </div>
    """
  end

  defp normalize_values(val) when is_list(val), do: Enum.map(val, &to_number/1)
  defp normalize_values(val) when is_number(val), do: [val]
  defp normalize_values(val) when is_binary(val), do: [to_number(val)]
  defp normalize_values(_), do: [0]

  defp to_number(v) when is_number(v), do: v

  defp to_number(v) when is_binary(v) do
    case Integer.parse(v) do
      {int, ""} -> int
      _ -> String.to_float(v)
    end
  end

  defp range_style("vertical", min_pct, max_pct),
    do: "bottom:#{min_pct}%;top:#{100 - max_pct}%"

  defp range_style(_horizontal, min_pct, max_pct),
    do: "left:#{min_pct}%;right:#{100 - max_pct}%"

  defp thumb_style("vertical", pct),
    do: "bottom:#{pct}%;transform:translateY(50%);left:50%;margin-left:-8px;position:absolute"

  defp thumb_style(_horizontal, pct),
    do: "left:#{pct}%;transform:translateX(-50%);top:50%;margin-top:-8px;position:absolute"
end
