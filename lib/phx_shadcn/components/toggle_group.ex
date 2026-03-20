defmodule PhxShadcn.Components.ToggleGroup do
  @moduledoc """
  ToggleGroup component mirroring shadcn/ui ToggleGroup.

  Manages single or multiple selection across a set of toggle buttons.
  Supports 3 state modes: client-only, hybrid, and server-controlled.

  Sub-components: `toggle_group/1`, `toggle_group_item/1`.

  ## State Modes

  - **Client-only** — no `value` or `on_value_change`. Pure JS, server unaware.
  - **Hybrid** — `on_value_change` set, no `value`. JS toggles instantly + pushes event.
  - **Server-controlled** — `value` set. Server owns the state.

  ## Examples

      <.toggle_group id="text-format" type="multiple">
        <.toggle_group_item value="bold">B</.toggle_group_item>
        <.toggle_group_item value="italic">I</.toggle_group_item>
        <.toggle_group_item value="underline">U</.toggle_group_item>
      </.toggle_group>

      <.toggle_group id="align" type="single" variant="outline">
        <.toggle_group_item value="left">Left</.toggle_group_item>
        <.toggle_group_item value="center">Center</.toggle_group_item>
        <.toggle_group_item value="right">Right</.toggle_group_item>
      </.toggle_group>
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  # ── ToggleGroup (root) ──────────────────────────────────────────────

  @group_base_classes [
    "group/toggle-group flex items-center gap-1"
  ]

  attr :id, :string, required: true
  attr :type, :string, default: "single", values: ~w(single multiple)
  attr :value, :any, default: nil
  attr :default_value, :any, default: nil
  attr :on_value_change, :any, default: nil
  attr :variant, :string, default: "default", values: ~w(default outline)
  attr :size, :string, default: "default", values: ~w(default sm lg)
  attr :spacing, :integer, default: 0
  attr :name, :string, default: nil
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def toggle_group(assigns) do
    state_mode =
      cond do
        assigns.value != nil -> "server"
        assigns.on_value_change != nil -> "hybrid"
        true -> "client"
      end

    value_str =
      case assigns.value do
        nil -> nil
        v when is_list(v) -> Enum.join(v, ",")
        v -> to_string(v)
      end

    default_value_str =
      case assigns.default_value do
        nil -> nil
        v when is_list(v) -> Enum.join(v, ",")
        v -> to_string(v)
      end

    spacing_gap =
      if assigns.spacing == 0 do
        "gap-0"
      else
        "gap-1"
      end

    hidden_value =
      case {value_str, default_value_str} do
        {nil, nil} -> ""
        {nil, dv} -> dv || ""
        {v, _} -> v || ""
      end

    assigns =
      assigns
      |> assign(:state_mode, state_mode)
      |> assign(:value_str, value_str)
      |> assign(:default_value_str, default_value_str)
      |> assign(:hidden_value, hidden_value)
      |> assign(
        :computed_class,
        cn([@group_base_classes, spacing_gap, assigns.class])
      )

    ~H"""
    <div
      id={@id}
      role="group"
      data-slot="toggle-group"
      data-type={@type}
      data-variant={@variant}
      data-size={@size}
      data-spacing={@spacing}
      data-state-mode={@state_mode}
      data-value={@value_str}
      data-default-value={@default_value_str}
      data-on-value-change={@on_value_change}
      class={@computed_class}
      phx-hook="PhxShadcnToggleGroup"
      {@rest}
    >
      {render_slot(@inner_block)}
      <input :if={@name} type="hidden" name={@name} value={@hidden_value} />
    </div>
    """
  end

  # ── ToggleGroupItem ─────────────────────────────────────────────────

  @item_base_classes [
    "inline-flex items-center justify-center gap-2 rounded-md text-sm font-medium",
    "transition-colors hover:bg-muted hover:text-muted-foreground",
    "focus-visible:outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]",
    "disabled:pointer-events-none disabled:opacity-50",
    "[&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4",
    "data-[state=on]:bg-accent data-[state=on]:text-accent-foreground",
    "phx-click-loading:opacity-70 phx-click-loading:pointer-events-none"
  ]

  @item_variant_classes %{
    "default" => "bg-transparent",
    "outline" =>
      "border border-input bg-transparent shadow-xs hover:bg-accent hover:text-accent-foreground group-data-[spacing=0]/toggle-group:first:rounded-r-none group-data-[spacing=0]/toggle-group:last:rounded-l-none group-data-[spacing=0]/toggle-group:[&:not(:first-child):not(:last-child)]:rounded-none group-data-[spacing=0]/toggle-group:[&:not(:first-child)]:-ml-px"
  }

  @item_size_classes %{
    "default" => "h-9 px-2 min-w-9",
    "sm" => "h-8 px-1.5 min-w-8",
    "lg" => "h-10 px-2.5 min-w-10"
  }

  attr :value, :string, required: true
  attr :variant, :string, default: "default", values: ~w(default outline)
  attr :size, :string, default: "default", values: ~w(default sm lg)
  attr :disabled, :boolean, default: false
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def toggle_group_item(assigns) do
    assigns =
      assign(
        assigns,
        :computed_class,
        cn([
          @item_base_classes,
          Map.fetch!(@item_variant_classes, assigns.variant),
          Map.fetch!(@item_size_classes, assigns.size),
          assigns.class
        ])
      )

    ~H"""
    <button
      type="button"
      data-slot="toggle-group-item"
      data-value={@value}
      data-variant={@variant}
      data-size={@size}
      data-state="off"
      data-disabled={@disabled && "true"}
      aria-pressed="false"
      disabled={@disabled}
      class={@computed_class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end
end
