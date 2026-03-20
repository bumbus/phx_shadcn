defmodule PhxShadcn.Components.ScrollArea do
  @moduledoc """
  ScrollArea component mirroring shadcn/ui ScrollArea.

  Replaces native scrollbars with custom-styled thin scrollbar overlays.
  Pure client-side — no server interaction needed for scroll state.

  ## Examples

      <.scroll_area id="tags" class="h-72 w-48 rounded-md border">
        <div class="p-4">
          <h4 class="mb-4 text-sm font-medium leading-none">Tags</h4>
          <div :for={tag <- @tags} class="text-sm">
            <%= tag %>
            <.separator class="my-2" />
          </div>
        </div>
      </.scroll_area>

      <.scroll_area id="gallery" scrollbars="horizontal" class="w-96 whitespace-nowrap rounded-md border">
        <div class="flex w-max space-x-4 p-4">
          <div :for={img <- @images} class="shrink-0">
            <img src={img} class="h-40 w-60 rounded-md object-cover" />
          </div>
        </div>
      </.scroll_area>

      <.scroll_area id="both" scrollbars="both" class="h-72 w-72 rounded-md border">
        <div class="w-[600px] p-4">Large content here...</div>
      </.scroll_area>
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  @scrollbar_v_classes [
    "flex touch-none select-none p-px transition-opacity duration-150",
    "absolute right-0 top-0 h-full w-2.5 border-l border-l-transparent",
    "data-[state=hidden]:opacity-0 data-[state=visible]:opacity-100"
  ]

  @scrollbar_h_classes [
    "flex touch-none select-none p-px transition-opacity duration-150 flex-col",
    "absolute bottom-0 left-0 h-2.5 w-full border-t border-t-transparent",
    "data-[state=hidden]:opacity-0 data-[state=visible]:opacity-100"
  ]

  attr :id, :string, required: true
  attr :scrollbars, :string, default: "vertical", values: ~w(vertical horizontal both)
  attr :class, :any, default: []
  attr :viewport_class, :any, default: []
  attr :rest, :global
  slot :inner_block, required: true

  def scroll_area(assigns) do
    has_v = assigns.scrollbars in ["vertical", "both"]
    has_h = assigns.scrollbars in ["horizontal", "both"]
    has_corner = has_v and has_h

    overflow_class =
      case assigns.scrollbars do
        "vertical" -> "overflow-y-auto overflow-x-hidden"
        "horizontal" -> "overflow-x-auto overflow-y-hidden"
        "both" -> "overflow-auto"
      end

    assigns =
      assigns
      |> assign(:has_v, has_v)
      |> assign(:has_h, has_h)
      |> assign(:has_corner, has_corner)
      |> assign(:overflow_class, overflow_class)
      |> assign(:root_class, cn(["relative overflow-hidden", assigns.class]))
      |> assign(
        :viewport_class_merged,
        cn([
          "size-full rounded-[inherit] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden",
          "focus-visible:ring-ring/50 focus-visible:ring-[3px] focus-visible:outline-1 outline-none transition-[color,box-shadow]",
          overflow_class,
          assigns.viewport_class
        ])
      )

    ~H"""
    <div
      id={@id}
      data-slot="scroll-area"
      class={@root_class}
      phx-hook="PhxShadcnScrollArea"
      {@rest}
    >
      <div data-slot="scroll-area-viewport" class={@viewport_class_merged} tabindex="0">
        {render_slot(@inner_block)}
      </div>
      <.scroll_bar :if={@has_v} orientation="vertical" />
      <.scroll_bar :if={@has_h} orientation="horizontal" />
      <div :if={@has_corner} data-slot="scroll-area-corner" class="bg-muted absolute bottom-0 right-0 w-2.5 h-2.5" />
    </div>
    """
  end

  attr :orientation, :string, default: "vertical", values: ~w(vertical horizontal)
  attr :class, :any, default: []
  attr :rest, :global

  def scroll_bar(assigns) do
    bar_classes =
      if assigns.orientation == "vertical",
        do: @scrollbar_v_classes,
        else: @scrollbar_h_classes

    assigns = assign(assigns, :bar_class, cn([bar_classes, assigns.class]))

    ~H"""
    <div
      data-slot="scroll-area-scrollbar"
      data-orientation={@orientation}
      data-state="hidden"
      class={@bar_class}
      {@rest}
    >
      <div data-slot="scroll-area-thumb" class="bg-border relative rounded-full flex-1" />
    </div>
    """
  end
end
