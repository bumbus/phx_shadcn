defmodule PhxShadcn.Components.Alert do
  @moduledoc """
  Alert component mirroring shadcn/ui Alert.

  Displays a callout with optional icon, title, and description.
  Uses CSS grid to align icon and text — when an SVG icon is present
  as a direct child it automatically gets its own column.

  ## Examples

      <.alert>
        <.alert_title>Heads up!</.alert_title>
        <.alert_description>You can add components to your app using the CLI.</.alert_description>
      </.alert>

      <.alert variant="destructive">
        <.alert_title>Error</.alert_title>
        <.alert_description>Something went wrong.</.alert_description>
      </.alert>
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  @base_classes [
    "relative w-full rounded-lg border px-4 py-3 text-sm",
    "grid has-[>svg]:grid-cols-[calc(var(--spacing)*4)_1fr] grid-cols-[0_1fr]",
    "has-[>svg]:gap-x-3 gap-y-0.5 items-start",
    "[&>svg]:size-4 [&>svg]:translate-y-0.5 [&>svg]:text-current"
  ]

  @variant_classes %{
    "default" => "bg-card text-card-foreground",
    "destructive" =>
      "text-destructive bg-card [&>svg]:text-current *:data-[slot=alert-description]:text-destructive/90"
  }

  # -- Alert --

  attr :variant, :string, default: "default", values: ~w(default destructive)
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def alert(assigns) do
    assigns =
      assign(assigns, :computed_class,
        cn([
          @base_classes,
          Map.fetch!(@variant_classes, assigns.variant),
          assigns.class
        ])
      )

    ~H"""
    <div role="alert" data-slot="alert" data-variant={@variant} class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # -- AlertTitle --

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def alert_title(assigns) do
    assigns =
      assign(assigns, :computed_class,
        cn(["col-start-2 line-clamp-1 min-h-4 font-medium tracking-tight", assigns.class])
      )

    ~H"""
    <div data-slot="alert-title" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # -- AlertDescription --

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def alert_description(assigns) do
    assigns =
      assign(assigns, :computed_class,
        cn([
          "text-muted-foreground col-start-2 grid justify-items-start gap-1 text-sm [&_p]:leading-relaxed",
          assigns.class
        ])
      )

    ~H"""
    <div data-slot="alert-description" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
