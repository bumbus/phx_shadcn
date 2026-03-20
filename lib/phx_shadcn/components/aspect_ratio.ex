defmodule PhxShadcn.Components.AspectRatio do
  @moduledoc """
  AspectRatio component mirroring shadcn/ui AspectRatio.

  Wraps content in a container that maintains a given aspect ratio
  using the native CSS `aspect-ratio` property.

  ## Examples

      <.aspect_ratio ratio={16 / 9}>
        <img src="/image.jpg" class="size-full object-cover" />
      </.aspect_ratio>

      <.aspect_ratio ratio={1.0}>
        <img src="/avatar.jpg" class="size-full object-cover rounded-md" />
      </.aspect_ratio>
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  attr :ratio, :float, default: 1.0
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def aspect_ratio(assigns) do
    assigns =
      assign(assigns, :computed_class, cn(["relative w-full", assigns.class]))

    ~H"""
    <div data-slot="aspect-ratio" style={"aspect-ratio: #{@ratio}"} class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
