defmodule PhxShadcn.Components.Card do
  @moduledoc """
  Card component mirroring shadcn/ui Card.

  Pure layout containers with no interactivity. Uses `data-slot` conventions from shadcn v4.

  Sub-components: `card/1`, `card_header/1`, `card_title/1`, `card_description/1`,
  `card_action/1`, `card_content/1`, `card_footer/1`.

  ## Examples

      <.card>
        <.card_header>
          <.card_title>Title</.card_title>
          <.card_description>Description</.card_description>
        </.card_header>
        <.card_content>
          <p>Content goes here.</p>
        </.card_content>
        <.card_footer>
          <.button>Save</.button>
        </.card_footer>
      </.card>
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  # --- Card ---

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def card(assigns) do
    assigns =
      assign(assigns, :computed_class,
        cn([
          "bg-card text-card-foreground flex flex-col gap-6 rounded-xl border py-6 shadow-sm",
          assigns.class
        ])
      )

    ~H"""
    <div data-slot="card" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # --- CardHeader ---

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def card_header(assigns) do
    assigns =
      assign(assigns, :computed_class,
        cn([
          "@container/card-header grid auto-rows-min grid-rows-[auto_auto] items-start gap-2 px-6",
          "has-data-[slot=card-action]:grid-cols-[1fr_auto] [.border-b]:pb-6",
          assigns.class
        ])
      )

    ~H"""
    <div data-slot="card-header" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # --- CardTitle ---

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def card_title(assigns) do
    assigns =
      assign(assigns, :computed_class,
        cn(["leading-none font-semibold", assigns.class])
      )

    ~H"""
    <div data-slot="card-title" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # --- CardDescription ---

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def card_description(assigns) do
    assigns =
      assign(assigns, :computed_class,
        cn(["text-muted-foreground text-sm", assigns.class])
      )

    ~H"""
    <div data-slot="card-description" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # --- CardAction ---

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def card_action(assigns) do
    assigns =
      assign(assigns, :computed_class,
        cn([
          "col-start-2 row-span-2 row-start-1 self-start justify-self-end",
          assigns.class
        ])
      )

    ~H"""
    <div data-slot="card-action" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # --- CardContent ---

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def card_content(assigns) do
    assigns =
      assign(assigns, :computed_class,
        cn(["px-6", assigns.class])
      )

    ~H"""
    <div data-slot="card-content" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # --- CardFooter ---

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def card_footer(assigns) do
    assigns =
      assign(assigns, :computed_class,
        cn(["flex items-center px-6 [.border-t]:pt-6", assigns.class])
      )

    ~H"""
    <div data-slot="card-footer" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
