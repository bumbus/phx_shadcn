defmodule PhxShadcn.Components.Sheet do
  @moduledoc """
  Sheet component mirroring shadcn/ui Sheet + Drawer (unified).

  A panel that slides in from an edge of the screen. Uses the native `<dialog>`
  element with `showModal()` — reuses the existing `Dialog` JS hook with zero
  new JavaScript.

  The optional `handle` attribute renders a visual drag handle bar (pure CSS,
  no drag-to-dismiss). This covers the Drawer use case for bottom/top sheets.

  Sub-components: `sheet/1`, `sheet_header/1`, `sheet_footer/1`,
  `sheet_title/1`, `sheet_description/1`, `sheet_close/1`.

  ## Usage Patterns

  **Client-only**:

      <.button phx-click={show_sheet("settings")}>Settings</.button>
      <.sheet id="settings" on_cancel={hide_sheet("settings")}>
        <.sheet_header>
          <.sheet_title>Settings</.sheet_title>
          <.sheet_description>Manage your preferences.</.sheet_description>
        </.sheet_header>
        <p>Content here</p>
        <.sheet_footer>
          <.button phx-click={hide_sheet("settings")}>Save</.button>
        </.sheet_footer>
      </.sheet>

  **Server-controlled**:

      <.sheet :if={@show_sheet} id="sheet" show on_cancel={JS.push("close_sheet")}>
        ...
      </.sheet>

  **Bottom drawer with handle**:

      <.sheet id="drawer" side={:bottom} handle on_cancel={hide_sheet("drawer")}>
        ...
      </.sheet>
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  alias Phoenix.LiveView.JS

  # ── show/hide helpers ──────────────────────────────────────────────

  @doc """
  Returns a `%JS{}` that opens a sheet by id.

  Dispatches `phx-shadcn:show` to the dialog element, which the hook
  handles by calling `showModal()`.
  """
  def show_sheet(js \\ %JS{}, id) do
    JS.dispatch(js, "phx-shadcn:show", to: "##{id}")
  end

  @doc """
  Returns a `%JS{}` that closes a sheet by id.

  Dispatches `phx-shadcn:hide` to the dialog element, which the hook
  handles by calling `close()`.
  """
  def hide_sheet(js \\ %JS{}, id) do
    JS.dispatch(js, "phx-shadcn:hide", to: "##{id}")
  end

  # ── sheet (root) ──────────────────────────────────────────────────

  @doc """
  Renders a sheet (slide-in panel) using the native `<dialog>` element.

  The `<dialog>` is full-viewport and acts as the overlay (with `bg-black/50`).
  An inner `<div data-slot="sheet-content">` holds the edge-anchored panel.

  ## Attributes

  - `id` (required) — unique identifier
  - `side` — edge to anchor to: `:right` (default), `:left`, `:top`, `:bottom`
  - `show` — when true, calls `showModal()` on mount (for `:if` pattern)
  - `on_cancel` — JS command executed on dismiss (Escape, backdrop click, close button).
    Default `nil` — set explicitly to enable dismissal.
  - `show_close` — render the X close button (default: true)
  - `handle` — render a visual drag handle bar (default: false). Only for top/bottom.
  - `class` — additional classes for the content panel
  - `overlay_class` — additional classes for the dialog overlay
  - `close_class` — additional classes for the close button
  - `handle_class` — additional classes for the handle bar
  - `animation_duration` — transition duration in ms (default: 300)

  ## Slots

  - `:close` — optional slot to replace the default X close button icon
  """

  attr :id, :string, required: true
  attr :side, :atom, default: :right, values: [:top, :right, :bottom, :left]
  attr :show, :boolean, default: false
  attr :on_cancel, :any, default: nil
  attr :show_close, :boolean, default: true
  attr :handle, :boolean, default: false
  attr :class, :any, default: []
  attr :overlay_class, :any, default: []
  attr :close_class, :any, default: []
  attr :handle_class, :any, default: []
  attr :animation_duration, :integer, default: 300
  attr :rest, :global

  slot :inner_block, required: true
  slot :close

  def sheet(assigns) do
    duration_style =
      if assigns.animation_duration != 300 do
        "--dialog-duration: #{assigns.animation_duration}ms"
      end

    assigns = assign(assigns, :duration_style, duration_style)

    ~H"""
    <dialog
      id={@id}
      data-slot="sheet"
      data-auto-open={to_string(@show)}
      data-on-cancel={@on_cancel}
      data-animation-duration={@animation_duration}
      style={@duration_style}
      class={
        cn([
          "fixed inset-0 m-0 h-dvh w-screen max-h-none max-w-none border-0 bg-black/50 p-0 outline-none open:block backdrop:bg-transparent opacity-0 ease-out data-[state=open]:opacity-100 data-[state=closing]:ease-in",
          "transition-opacity duration-[var(--dialog-duration,300ms)]",
          @overlay_class
        ])
      }
      phx-hook="PhxShadcnDialog"
      phx-mounted={JS.ignore_attributes(["open"])}
      {@rest}
    >
      <div
        data-slot="sheet-content"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        class={
          cn([
            "bg-background fixed z-50 flex flex-col gap-4 shadow-lg ease-out data-[state=closing]:ease-in",
            "transition-transform duration-[var(--dialog-duration,300ms)]",
            side_classes(@side),
            @class
          ])
        }
      >
        <div
          :if={@handle && @side == :bottom}
          data-slot="sheet-handle"
          class={cn(["mx-auto mt-4 h-2 w-[100px] shrink-0 rounded-full bg-muted", @handle_class])}
        />
        {render_slot(@inner_block)}
        <div
          :if={@handle && @side == :top}
          data-slot="sheet-handle"
          class={cn(["mx-auto mb-4 h-2 w-[100px] shrink-0 rounded-full bg-muted", @handle_class])}
        />
        <button
          :if={@show_close}
          type="button"
          data-slot="sheet-close"
          class={
            cn([
              "ring-offset-background focus:ring-ring absolute top-4 right-4 rounded-xs opacity-70 transition-opacity hover:opacity-100 focus:ring-2 focus:ring-offset-2 focus:outline-hidden disabled:pointer-events-none [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4",
              @close_class
            ])
          }
          aria-label="Close"
          phx-click={@on_cancel}
        >
          <%= if @close != [] do %>
            {render_slot(@close)}
          <% else %>
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
            >
              <path d="M18 6 6 18" /><path d="m6 6 12 12" />
            </svg>
          <% end %>
          <span class="sr-only">Close</span>
        </button>
      </div>
    </dialog>
    """
  end

  defp side_classes(:right),
    do:
      "inset-y-0 right-0 h-full w-3/4 sm:max-w-sm border-l translate-x-full data-[state=open]:translate-x-0"

  defp side_classes(:left),
    do:
      "inset-y-0 left-0 h-full w-3/4 sm:max-w-sm border-r -translate-x-full data-[state=open]:translate-x-0"

  defp side_classes(:top),
    do:
      "inset-x-0 top-0 h-auto max-h-[80vh] border-b rounded-b-lg -translate-y-full data-[state=open]:translate-y-0"

  defp side_classes(:bottom),
    do:
      "inset-x-0 bottom-0 h-auto max-h-[80vh] border-t rounded-t-lg translate-y-full data-[state=open]:translate-y-0"

  # ── sheet_header ──────────────────────────────────────────────────

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def sheet_header(assigns) do
    ~H"""
    <div data-slot="sheet-header" class={cn(["flex flex-col gap-1.5 p-4", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── sheet_footer ──────────────────────────────────────────────────

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def sheet_footer(assigns) do
    ~H"""
    <div data-slot="sheet-footer" class={cn(["mt-auto flex flex-col gap-2 p-4", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── sheet_title ───────────────────────────────────────────────────

  attr :id, :string, default: nil
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def sheet_title(assigns) do
    ~H"""
    <h2 data-slot="sheet-title" id={@id} class={cn(["text-foreground font-semibold", @class])} {@rest}>
      {render_slot(@inner_block)}
    </h2>
    """
  end

  # ── sheet_description ─────────────────────────────────────────────

  attr :id, :string, default: nil
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def sheet_description(assigns) do
    ~H"""
    <p data-slot="sheet-description" id={@id} class={cn(["text-muted-foreground text-sm", @class])} {@rest}>
      {render_slot(@inner_block)}
    </p>
    """
  end

  # ── sheet_close ───────────────────────────────────────────────────

  @doc """
  Wraps children that should trigger sheet dismissal on click.

  Pass the same `on_cancel` value as the parent sheet.
  """

  attr :class, :any, default: []
  attr :on_cancel, :any, default: nil, doc: "JS command chain to execute on click"
  attr :rest, :global

  slot :inner_block, required: true

  def sheet_close(assigns) do
    ~H"""
    <div data-slot="sheet-close" class={cn(["contents", @class])} phx-click={@on_cancel} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
