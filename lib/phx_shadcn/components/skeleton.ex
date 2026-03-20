defmodule PhxShadcn.Components.Skeleton do
  @moduledoc """
  Skeleton component mirroring shadcn/ui Skeleton.

  A loading placeholder that pulses to indicate content is loading.
  Control shape and size via class overrides.

  ## Examples

      <.skeleton class={["h-4 w-48"]} />
      <.skeleton class={["h-12 w-12 rounded-full"]} />
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  @base_classes "animate-pulse rounded-md bg-accent"

  attr :class, :any, default: []
  attr :rest, :global

  def skeleton(assigns) do
    assigns =
      assign(assigns, :computed_class, cn([@base_classes, assigns.class]))

    ~H"""
    <div data-slot="skeleton" class={@computed_class} {@rest} />
    """
  end
end
