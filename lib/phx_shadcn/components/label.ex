defmodule PhxShadcn.Components.Label do
  @moduledoc """
  Label component mirroring shadcn/ui Label.

  A styled `<label>` element that pairs with form controls. Automatically
  adapts to disabled states via CSS peer/group selectors — no props needed.

  Pass `for` via the global attributes to link to an input.

  ## Examples

      <.label for="email">Email</.label>

      <.label>Username</.label>
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  @base_classes [
    "flex items-center gap-2 text-sm leading-none font-medium select-none",
    "group-data-[disabled=true]:pointer-events-none group-data-[disabled=true]:opacity-50",
    "peer-disabled:cursor-not-allowed peer-disabled:opacity-50"
  ]

  attr :class, :any, default: []
  attr :rest, :global, include: ~w(for)

  slot :inner_block, required: true

  def label(assigns) do
    assigns =
      assign(assigns, :computed_class, cn([@base_classes, assigns.class]))

    ~H"""
    <label data-slot="label" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </label>
    """
  end
end
