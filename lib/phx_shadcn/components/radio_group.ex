defmodule PhxShadcn.Components.RadioGroup do
  @moduledoc """
  RadioGroup component mirroring shadcn/ui RadioGroup.

  Manages single selection across a set of radio buttons with keyboard navigation.
  Supports 3 state modes: client-only, hybrid, and server-controlled.

  Sub-components: `radio_group/1`, `radio_group_item/1`.

  ## State Modes

  - **Client-only** — no `value` or `on_value_change`. Pure JS, server unaware.
  - **Hybrid** — `on_value_change` set, no `value`. JS selects instantly + pushes event.
  - **Server-controlled** — `value` set. Server owns the state.

  ## Examples

      <.radio_group id="plan" default_value="comfort">
        <div class="flex items-center space-x-2">
          <.radio_group_item value="default" id="r1" />
          <.label for="r1">Default</.label>
        </div>
        <div class="flex items-center space-x-2">
          <.radio_group_item value="comfort" id="r2" />
          <.label for="r2">Comfortable</.label>
        </div>
        <div class="flex items-center space-x-2">
          <.radio_group_item value="compact" id="r3" />
          <.label for="r3">Compact</.label>
        </div>
      </.radio_group>
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  # ── RadioGroup (root) ──────────────────────────────────────────────

  @group_base_classes [
    "grid gap-3"
  ]

  attr :id, :string, required: true
  attr :value, :string, default: nil
  attr :default_value, :string, default: nil
  attr :on_value_change, :any, default: nil
  attr :orientation, :string, default: "vertical", values: ~w(vertical horizontal)
  attr :disabled, :boolean, default: false
  attr :name, :string, default: nil
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def radio_group(assigns) do
    state_mode =
      cond do
        assigns.value != nil -> "server"
        assigns.on_value_change != nil -> "hybrid"
        true -> "client"
      end

    hidden_value =
      case {assigns.value, assigns.default_value} do
        {nil, nil} -> ""
        {nil, dv} -> dv || ""
        {v, _} -> v || ""
      end

    orientation_class =
      if assigns.orientation == "horizontal" do
        "flex flex-row gap-3"
      else
        nil
      end

    assigns =
      assigns
      |> assign(:state_mode, state_mode)
      |> assign(:hidden_value, hidden_value)
      |> assign(
        :computed_class,
        cn([@group_base_classes, orientation_class, assigns.class])
      )

    ~H"""
    <div
      id={@id}
      role="radiogroup"
      data-slot="radio-group"
      data-state-mode={@state_mode}
      data-value={@value}
      data-default-value={@default_value}
      data-on-value-change={@on_value_change}
      data-orientation={@orientation}
      data-disabled={@disabled && "true"}
      aria-orientation={@orientation}
      class={@computed_class}
      phx-hook="PhxShadcnRadioGroup"
      {@rest}
    >
      {render_slot(@inner_block)}
      <input :if={@name} type="hidden" name={@name} value={@hidden_value} />
    </div>
    """
  end

  # ── RadioGroupItem ─────────────────────────────────────────────────

  @item_base_classes [
    "border-input text-primary focus-visible:border-ring focus-visible:ring-ring/50",
    "aspect-square size-4 shrink-0 rounded-full border shadow-xs",
    "transition-[color,box-shadow] outline-none focus-visible:ring-[3px]",
    "disabled:cursor-not-allowed disabled:opacity-50"
  ]

  @indicator_classes "relative flex items-center justify-center"

  attr :value, :string, required: true
  attr :id, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :class, :any, default: []
  attr :rest, :global

  def radio_group_item(assigns) do
    assigns =
      assigns
      |> assign(:computed_class, cn([@item_base_classes, assigns.class]))
      |> assign(:indicator_classes, @indicator_classes)

    ~H"""
    <button
      type="button"
      role="radio"
      id={@id}
      data-slot="radio-group-item"
      data-roving-item
      data-value={@value}
      data-state="unchecked"
      data-disabled={@disabled && "true"}
      aria-checked="false"
      tabindex="-1"
      disabled={@disabled}
      class={@computed_class}
      {@rest}
    >
      <span data-slot="radio-group-indicator" class={@indicator_classes}>
        <svg
          class="fill-primary size-2"
          viewBox="0 0 8 8"
          xmlns="http://www.w3.org/2000/svg"
          style="display: none;"
          data-radio-circle
        >
          <circle cx="4" cy="4" r="4" />
        </svg>
      </span>
    </button>
    """
  end
end
