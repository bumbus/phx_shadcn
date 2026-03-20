defmodule PhxShadcn.Components.Badge do
  @moduledoc """
  Badge component mirroring shadcn/ui Badge.

  Supports variants: default, secondary, destructive, outline, ghost, link.
  Renders as a `<span>` by default. Pass `navigate`, `patch`, or `href` to
  render as a link — hover styles (`[a&]:hover:`) activate automatically.

  Uses `data-slot="badge"` and `data-variant` conventions from shadcn v4.

  ## Examples

      <.badge>New</.badge>
      <.badge variant="destructive">Error</.badge>
      <.badge variant="outline" navigate={~p"/tags/v1"}>v1.0</.badge>
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  @base_classes [
    "inline-flex items-center justify-center rounded-full border border-transparent",
    "px-2 py-0.5 text-xs font-medium w-fit whitespace-nowrap shrink-0",
    "[&>svg]:size-3 gap-1 [&>svg]:pointer-events-none",
    "focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]",
    "aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive",
    "transition-[color,box-shadow] overflow-hidden"
  ]

  @variant_classes %{
    "default" => "bg-primary text-primary-foreground [a&]:hover:bg-primary/90",
    "secondary" => "bg-secondary text-secondary-foreground [a&]:hover:bg-secondary/90",
    "destructive" =>
      "bg-destructive text-white [a&]:hover:bg-destructive/90 focus-visible:ring-destructive/20 dark:focus-visible:ring-destructive/40 dark:bg-destructive/60",
    "outline" =>
      "border-border text-foreground [a&]:hover:bg-accent [a&]:hover:text-accent-foreground",
    "ghost" => "[a&]:hover:bg-accent [a&]:hover:text-accent-foreground",
    "link" => "text-primary underline-offset-4 [a&]:hover:underline"
  }

  attr :variant, :string,
    default: "default",
    values: ~w(default secondary destructive outline ghost link)

  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  attr :href, :string, default: nil
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def badge(assigns) do
    assigns =
      assigns
      |> assign(:computed_class,
        cn([
          @base_classes,
          Map.fetch!(@variant_classes, assigns.variant),
          assigns.class
        ])
      )
      |> assign(:is_link, assigns.navigate != nil || assigns.patch != nil || assigns.href != nil)

    ~H"""
    <.link
      :if={@is_link}
      navigate={@navigate}
      patch={@patch}
      href={@href}
      data-slot="badge"
      data-variant={@variant}
      class={@computed_class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    <span :if={!@is_link} data-slot="badge" data-variant={@variant} class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end
end
