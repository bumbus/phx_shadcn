defmodule PhxShadcn.Components.Separator do
  @moduledoc """
  Separator component mirroring shadcn/ui Separator.

  A visual divider between content sections. Renders as a horizontal
  or vertical line using `role="separator"` (or `role="none"` when decorative).

  Uses `data-slot="separator"` and `data-orientation` conventions from shadcn v4.

  ## Examples

      <.separator />
      <.separator orientation="vertical" />
      <.separator decorative={false} />
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  @base_classes "bg-border shrink-0"

  @orientation_classes %{
    "horizontal" => "h-px w-full",
    "vertical" => "h-full w-px"
  }

  attr :orientation, :string, default: "horizontal", values: ~w(horizontal vertical)
  attr :decorative, :boolean, default: true
  attr :class, :any, default: []
  attr :rest, :global

  def separator(assigns) do
    assigns =
      assign(assigns, :computed_class,
        cn([
          @base_classes,
          Map.fetch!(@orientation_classes, assigns.orientation),
          assigns.class
        ])
      )

    ~H"""
    <div
      role={if @decorative, do: "none", else: "separator"}
      aria-orientation={if !@decorative, do: @orientation}
      data-slot="separator"
      data-orientation={@orientation}
      class={@computed_class}
      {@rest}
    />
    """
  end
end
