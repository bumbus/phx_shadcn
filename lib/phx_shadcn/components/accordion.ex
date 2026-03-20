defmodule PhxShadcn.Components.Accordion do
  @moduledoc """
  Accordion component mirroring shadcn/ui Accordion.

  Interactive disclosure component supporting 3 state modes:
  client-only, hybrid, and server-controlled.

  Sub-components: `accordion/1`, `accordion_item/1`, `accordion_trigger/1`,
  `accordion_content/1`.

  ## State Modes

  - **Client-only** — no `value` or `on_value_change`. Pure JS, server unaware.
  - **Hybrid** — `on_value_change` set, no `value`. JS toggles instantly + pushes event.
  - **Server-controlled** — `value` set. Server owns the state.

  ## Examples

      <.accordion id="faq" type="single" collapsible>
        <.accordion_item value="q1">
          <.accordion_trigger>Question?</.accordion_trigger>
          <.accordion_content>Answer.</.accordion_content>
        </.accordion_item>
      </.accordion>
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  # --- Accordion (root) ---

  attr :id, :string, required: true
  attr :type, :string, default: "single", values: ~w(single multiple)
  attr :collapsible, :boolean, default: false
  attr :value, :any, default: nil
  attr :default_value, :any, default: nil
  attr :on_value_change, :any, default: nil
  attr :animation_duration, :integer, default: 200
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def accordion(assigns) do
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
      |> assign(:computed_class, cn(["w-full", assigns.class]))

    ~H"""
    <div
      id={@id}
      data-slot="accordion"
      data-type={@type}
      data-collapsible={to_string(@collapsible)}
      data-state-mode={@state_mode}
      data-value={@value_str}
      data-default-value={@default_value_str}
      data-on-value-change={@on_value_change}
      data-item-selector="[data-slot=accordion-item]"
      data-trigger-selector="[data-slot=accordion-trigger]"
      data-content-selector="[data-slot=accordion-content]"
      style={@duration_style}
      class={@computed_class}
      phx-hook="PhxShadcnCollapsible"
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # --- AccordionItem ---

  attr :value, :string, required: true
  attr :disabled, :boolean, default: false
  attr :disabled_class, :any, default: ["opacity-50 pointer-events-none"]
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def accordion_item(assigns) do
    assigns =
      assign(assigns, :computed_class,
        cn([
          "border-b last:border-b-0",
          assigns.disabled && assigns.disabled_class,
          assigns.class
        ])
      )

    ~H"""
    <div
      data-slot="accordion-item"
      data-value={@value}
      data-state="closed"
      data-disabled={@disabled && "true"}
      class={@computed_class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # --- AccordionTrigger ---

  attr :hide_icon, :boolean, default: false
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true
  slot :icon

  def accordion_trigger(assigns) do
    assigns =
      assign(assigns, :computed_class,
        cn([
          "group/trigger flex flex-1 items-center justify-between py-4 text-left text-sm font-medium",
          "transition-all hover:underline",
          "focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:outline-ring",
          "focus-visible:ring-[3px]",
          "disabled:pointer-events-none disabled:opacity-50",
          assigns.class
        ])
      )

    ~H"""
    <h3 class="flex">
      <button
        type="button"
        data-slot="accordion-trigger"
        data-state="closed"
        class={@computed_class}
        {@rest}
      >
        {render_slot(@inner_block)}
        <%= cond do %>
          <% @hide_icon -> %>
          <% @icon != [] -> %>
            {render_slot(@icon)}
          <% true -> %>
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="shrink-0 text-muted-foreground transition-transform group-data-[state=open]/trigger:rotate-180"
              style="transition-duration: var(--accordion-duration, 200ms)"
            >
              <path d="m6 9 6 6 6-6" />
            </svg>
        <% end %>
      </button>
    </h3>
    """
  end

  # --- AccordionContent ---

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def accordion_content(assigns) do
    assigns =
      assign(assigns, :computed_class,
        cn(["pt-0 pb-4", assigns.class])
      )

    ~H"""
    <div
      data-slot="accordion-content"
      data-state="closed"
      class="overflow-hidden text-sm data-[state=open]:animate-accordion-down data-[state=closed]:animate-accordion-up"
      style="display:none"
    >
      <div class={@computed_class} {@rest}>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end
end
