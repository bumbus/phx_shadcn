defmodule PhxShadcn.Components.Dialog do
  @moduledoc """
  Dialog component mirroring shadcn/ui Dialog.

  Uses the native `<dialog>` element with `showModal()` for focus trapping,
  backdrop, scroll lock, and focus save/restore — all handled by the browser.
  A small JS hook (~45 lines) bridges LiveView events.

  Sub-components: `dialog/1`, `dialog_header/1`, `dialog_footer/1`,
  `dialog_title/1`, `dialog_description/1`, `dialog_close/1`.

  ## Usage Patterns

  **Server-controlled** (most common in LiveView):

      <.dialog :if={@show_dialog} id="confirm" show on_cancel={JS.push("close_dialog")}>
        <.dialog_header>
          <.dialog_title>Title</.dialog_title>
          <.dialog_description>Description</.dialog_description>
        </.dialog_header>
        <.dialog_footer>
          <.dialog_close on_cancel={JS.push("close_dialog")}>
            <.button variant="outline">Cancel</.button>
          </.dialog_close>
          <.button phx-click="confirm">OK</.button>
        </.dialog_footer>
      </.dialog>

  **Client-only** (no server round-trip):

      <.button phx-click={show_dialog("help")}>Help</.button>
      <.dialog id="help" on_cancel={hide_dialog("help")}>
        ...
      </.dialog>

  **Hybrid** (instant open, server notified):

      <.button phx-click={show_dialog("cart") |> JS.push("cart_opened")}>Cart</.button>
      <.dialog id="cart" on_cancel={hide_dialog("cart") |> JS.push("cart_closed")}>
        ...
      </.dialog>
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  alias Phoenix.LiveView.JS

  # ── show/hide helpers ──────────────────────────────────────────────

  @doc """
  Returns a `%JS{}` that opens a dialog by id.

  Dispatches `phx-shadcn:show` to the dialog element, which the hook
  handles by calling `showModal()`.
  """
  def show_dialog(js \\ %JS{}, id) do
    JS.dispatch(js, "phx-shadcn:show", to: "##{id}")
  end

  @doc """
  Returns a `%JS{}` that closes a dialog by id.

  Dispatches `phx-shadcn:hide` to the dialog element, which the hook
  handles by calling `close()`.
  """
  def hide_dialog(js \\ %JS{}, id) do
    JS.dispatch(js, "phx-shadcn:hide", to: "##{id}")
  end

  # ── dialog (root) ──────────────────────────────────────────────────

  @doc """
  Renders a modal dialog using the native `<dialog>` element.

  The `<dialog>` is full-viewport and acts as the overlay (with `bg-black/50`).
  An inner `<div data-slot="dialog-content">` holds the centered panel.

  ## Attributes

  - `id` (required) — unique identifier
  - `show` — when true, calls `showModal()` on mount (for `:if` pattern)
  - `on_cancel` — JS command or event name executed on dismiss (Escape, backdrop click, close button).
    Default `nil` — set explicitly to enable dismissal.
  - `show_close` — render the X close button in top-right corner (default: true)
  - `class` — additional classes for the content panel
  - `overlay_class` — additional classes for the dialog overlay
  - `close_class` — additional classes for the close button
  - `animation_duration` — transition duration in ms (default: 200)

  ## Slots

  - `:close` — optional slot to replace the default X close button icon
  """

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, :any, default: nil
  attr :show_close, :boolean, default: true
  attr :class, :any, default: []
  attr :overlay_class, :any, default: []
  attr :close_class, :any, default: []
  attr :animation_duration, :integer, default: 200
  attr :rest, :global

  slot :inner_block, required: true
  slot :close

  def dialog(assigns) do
    duration_style =
      if assigns.animation_duration != 200 do
        "--dialog-duration: #{assigns.animation_duration}ms"
      end

    assigns = assign(assigns, :duration_style, duration_style)

    ~H"""
    <dialog
      id={@id}
      data-slot="dialog"
      data-auto-open={to_string(@show)}
      data-on-cancel={@on_cancel}
      data-animation-duration={@animation_duration}
      style={@duration_style}
      class={
        cn([
          "fixed inset-0 m-0 h-dvh w-screen max-h-none max-w-none border-0 bg-black/50 p-0 outline-none open:grid place-items-center backdrop:bg-transparent opacity-0 ease-out data-[state=open]:opacity-100 data-[state=closing]:ease-in",
          "transition-opacity duration-[var(--dialog-duration,200ms)]",
          @overlay_class
        ])
      }
      phx-hook="PhxShadcnDialog"
      phx-mounted={JS.ignore_attributes(["open"])}
      {@rest}
    >
      <div
        data-slot="dialog-content"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        class={
          cn([
            "bg-background relative grid w-full max-w-[calc(100%-2rem)] gap-4 rounded-lg border p-6 shadow-lg sm:max-w-lg opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95 ease-out data-[state=open]:opacity-100 data-[state=open]:translate-y-0 data-[state=open]:sm:scale-100 data-[state=closing]:ease-in",
            "transition-[opacity,translate,scale] duration-[var(--dialog-duration,200ms)]",
            @class
          ])
        }
      >
        {render_slot(@inner_block)}
        <button
          :if={@show_close}
          type="button"
          data-slot="dialog-close"
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

  # ── dialog_header ──────────────────────────────────────────────────

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def dialog_header(assigns) do
    ~H"""
    <div data-slot="dialog-header" class={cn(["flex flex-col gap-2 text-center sm:text-left", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── dialog_footer ──────────────────────────────────────────────────

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def dialog_footer(assigns) do
    ~H"""
    <div data-slot="dialog-footer" class={cn(["flex flex-col-reverse gap-2 sm:flex-row sm:justify-end", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── dialog_title ───────────────────────────────────────────────────

  attr :id, :string, default: nil
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def dialog_title(assigns) do
    ~H"""
    <h2 data-slot="dialog-title" id={@id} class={cn(["text-lg leading-none font-semibold tracking-tight", @class])} {@rest}>
      {render_slot(@inner_block)}
    </h2>
    """
  end

  # ── dialog_description ─────────────────────────────────────────────

  attr :id, :string, default: nil
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def dialog_description(assigns) do
    ~H"""
    <p data-slot="dialog-description" id={@id} class={cn(["text-muted-foreground text-sm", @class])} {@rest}>
      {render_slot(@inner_block)}
    </p>
    """
  end

  # ── dialog_close ───────────────────────────────────────────────────

  @doc """
  Wraps children that should trigger dialog dismissal on click.

  Pass the same `on_cancel` value as the parent dialog.
  """

  attr :class, :any, default: []
  attr :on_cancel, :any, default: nil, doc: "JS command chain to execute on click"
  attr :rest, :global

  slot :inner_block, required: true

  def dialog_close(assigns) do
    ~H"""
    <div data-slot="dialog-close" class={cn(["contents", @class])} phx-click={@on_cancel} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
