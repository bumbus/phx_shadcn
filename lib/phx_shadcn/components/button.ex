defmodule PhxShadcn.Components.Button do
  @moduledoc """
  Button component mirroring shadcn/ui Button.

  Supports all shadcn variants (default, destructive, outline, secondary, ghost, link)
  and sizes (default, xs, sm, lg, icon, icon-xs, icon-sm, icon-lg).

  Renders as a `<button>` by default. Pass `navigate`, `patch`, or `href` to
  render as a link with button styling.

  Uses `data-slot="button"`, `data-variant`, `data-size` conventions from shadcn v4.
  Includes phx-click-loading and phx-submit-loading styles out of the box.

  ## Examples

      <.button>Click me</.button>
      <.button variant="destructive">Delete</.button>
      <.button variant="outline" size="sm">Small outlined</.button>
      <.button variant="ghost" size="icon"><.icon name="hero-x-mark" /></.button>
      <.button navigate={~p"/about"}>About</.button>
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  @base_classes [
    "inline-flex items-center justify-center gap-2 whitespace-nowrap",
    "rounded-md text-sm font-medium transition-all shrink-0",
    "disabled:pointer-events-none disabled:opacity-50",
    "[&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4",
    "outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]",
    "aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive",
    "phx-click-loading:opacity-70 phx-click-loading:pointer-events-none",
    "phx-submit-loading:opacity-70 phx-submit-loading:pointer-events-none"
  ]

  @variant_classes %{
    "default" => "bg-primary text-primary-foreground hover:bg-primary/90",
    "destructive" =>
      "bg-destructive text-white hover:bg-destructive/90 focus-visible:ring-destructive/20 dark:focus-visible:ring-destructive/40 dark:bg-destructive/60",
    "outline" =>
      "border bg-background shadow-xs hover:bg-accent hover:text-accent-foreground dark:bg-input/30 dark:border-input dark:hover:bg-input/50",
    "secondary" => "bg-secondary text-secondary-foreground hover:bg-secondary/80",
    "ghost" => "hover:bg-accent hover:text-accent-foreground dark:hover:bg-accent/50",
    "link" => "text-primary underline-offset-4 hover:underline"
  }

  @size_classes %{
    "default" => "h-9 px-4 py-2 has-[>svg]:px-3",
    "xs" =>
      "h-6 gap-1 rounded-md px-2 text-xs has-[>svg]:px-1.5 [&_svg:not([class*='size-'])]:size-3",
    "sm" => "h-8 rounded-md gap-1.5 px-3 has-[>svg]:px-2.5",
    "lg" => "h-10 rounded-md px-6 has-[>svg]:px-4",
    "icon" => "size-9",
    "icon-xs" => "size-6 rounded-md [&_svg:not([class*='size-'])]:size-3",
    "icon-sm" => "size-8",
    "icon-lg" => "size-10"
  }

  attr :variant, :string,
    default: "default",
    values: ~w(default destructive outline secondary ghost link)

  attr :size, :string,
    default: "default",
    values: ~w(default xs sm lg icon icon-xs icon-sm icon-lg)

  attr :type, :string, default: "button"
  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  attr :href, :string, default: nil
  attr :class, :any, default: []
  attr :disabled, :boolean, default: false
  attr :rest, :global

  slot :inner_block, required: true

  def button(assigns) do
    assigns =
      assigns
      |> assign(:computed_class,
        cn([
          @base_classes,
          Map.fetch!(@variant_classes, assigns.variant),
          Map.fetch!(@size_classes, assigns.size),
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
      data-slot="button"
      data-variant={@variant}
      data-size={@size}
      class={@computed_class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    <button
      :if={!@is_link}
      type={@type}
      disabled={@disabled}
      data-slot="button"
      data-variant={@variant}
      data-size={@size}
      class={@computed_class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end
end
