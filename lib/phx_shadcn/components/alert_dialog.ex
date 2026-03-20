defmodule PhxShadcn.Components.AlertDialog do
  @moduledoc """
  AlertDialog component mirroring shadcn/ui AlertDialog.

  A forced-choice modal — identical to Dialog but: (1) no backdrop click dismiss,
  (2) no X close button by default, (3) `role="alertdialog"` on the content div.
  The user must explicitly choose an action or cancel.

  Reuses the existing `Dialog` JS hook with `data-no-backdrop-dismiss="true"`.

  Sub-components: `alert_dialog/1`, `alert_dialog_header/1`, `alert_dialog_footer/1`,
  `alert_dialog_title/1`, `alert_dialog_description/1`, `alert_dialog_cancel/1`,
  `alert_dialog_action/1`.

  ## Usage Patterns

  **Client-only**:

      <.button phx-click={show_alert_dialog("confirm")}>Delete</.button>
      <.alert_dialog id="confirm" on_cancel={hide_alert_dialog("confirm")}>
        <.alert_dialog_header>
          <.alert_dialog_title id="confirm-title">Are you sure?</.alert_dialog_title>
          <.alert_dialog_description id="confirm-description">
            This action cannot be undone.
          </.alert_dialog_description>
        </.alert_dialog_header>
        <.alert_dialog_footer>
          <.alert_dialog_cancel on_cancel={hide_alert_dialog("confirm")}>
            <.button variant="outline">Cancel</.button>
          </.alert_dialog_cancel>
          <.alert_dialog_action>
            <.button phx-click={hide_alert_dialog("confirm")}>Continue</.button>
          </.alert_dialog_action>
        </.alert_dialog_footer>
      </.alert_dialog>

  **Server-controlled**:

      <.alert_dialog :if={@show_confirm} id="confirm" show on_cancel={JS.push("cancel")}>
        ...
        <.alert_dialog_cancel on_cancel={JS.push("cancel")}>
          <.button variant="outline">Cancel</.button>
        </.alert_dialog_cancel>
        <.alert_dialog_action>
          <.button phx-click="confirm">Delete</.button>
        </.alert_dialog_action>
      </.alert_dialog>
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  alias Phoenix.LiveView.JS

  # ── show/hide helpers ──────────────────────────────────────────────

  @doc """
  Returns a `%JS{}` that opens an alert dialog by id.
  """
  def show_alert_dialog(js \\ %JS{}, id) do
    JS.dispatch(js, "phx-shadcn:show", to: "##{id}")
  end

  @doc """
  Returns a `%JS{}` that closes an alert dialog by id.
  """
  def hide_alert_dialog(js \\ %JS{}, id) do
    JS.dispatch(js, "phx-shadcn:hide", to: "##{id}")
  end

  # ── alert_dialog (root) ─────────────────────────────────────────────

  @doc """
  Renders a forced-choice modal using the native `<dialog>` element.

  Same as `dialog/1` but with `data-no-backdrop-dismiss="true"`,
  `show_close` defaulting to `false`, and `role="alertdialog"` on the
  content div.

  ## Attributes

  - `id` (required) — unique identifier
  - `show` — when true, calls `showModal()` on mount (for `:if` pattern)
  - `on_cancel` — JS command executed on dismiss (Escape only — backdrop clicks blocked)
  - `show_close` — render the X close button (default: false)
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
  attr :show_close, :boolean, default: false
  attr :class, :any, default: []
  attr :overlay_class, :any, default: []
  attr :close_class, :any, default: []
  attr :animation_duration, :integer, default: 200
  attr :rest, :global

  slot :inner_block, required: true
  slot :close

  def alert_dialog(assigns) do
    duration_style =
      if assigns.animation_duration != 200 do
        "--dialog-duration: #{assigns.animation_duration}ms"
      end

    assigns = assign(assigns, :duration_style, duration_style)

    ~H"""
    <dialog
      id={@id}
      data-slot="alert-dialog"
      data-auto-open={to_string(@show)}
      data-on-cancel={@on_cancel}
      data-animation-duration={@animation_duration}
      data-no-backdrop-dismiss="true"
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
        data-slot="alert-dialog-content"
        role="alertdialog"
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
          data-slot="alert-dialog-close"
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

  # ── alert_dialog_header ─────────────────────────────────────────────

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def alert_dialog_header(assigns) do
    ~H"""
    <div data-slot="alert-dialog-header" class={cn(["flex flex-col gap-2 text-center sm:text-left", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── alert_dialog_footer ─────────────────────────────────────────────

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def alert_dialog_footer(assigns) do
    ~H"""
    <div data-slot="alert-dialog-footer" class={cn(["flex flex-col-reverse gap-2 sm:flex-row sm:justify-end", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── alert_dialog_title ──────────────────────────────────────────────

  attr :id, :string, default: nil
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def alert_dialog_title(assigns) do
    ~H"""
    <h2 data-slot="alert-dialog-title" id={@id} class={cn(["text-lg leading-none font-semibold tracking-tight", @class])} {@rest}>
      {render_slot(@inner_block)}
    </h2>
    """
  end

  # ── alert_dialog_description ────────────────────────────────────────

  attr :id, :string, default: nil
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def alert_dialog_description(assigns) do
    ~H"""
    <p data-slot="alert-dialog-description" id={@id} class={cn(["text-muted-foreground text-sm", @class])} {@rest}>
      {render_slot(@inner_block)}
    </p>
    """
  end

  # ── alert_dialog_cancel ─────────────────────────────────────────────

  @doc """
  Wraps children that should trigger alert dialog dismissal on click.

  Pass the same `on_cancel` value as the parent alert dialog.
  """

  attr :class, :any, default: []
  attr :on_cancel, :any, default: nil, doc: "JS command chain to execute on click"
  attr :rest, :global

  slot :inner_block, required: true

  def alert_dialog_cancel(assigns) do
    ~H"""
    <div data-slot="alert-dialog-cancel" class={cn(["contents", @class])} phx-click={@on_cancel} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── alert_dialog_action ─────────────────────────────────────────────

  @doc """
  Wraps action children. The user adds their own `phx-click` to the child button.
  """

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def alert_dialog_action(assigns) do
    ~H"""
    <div data-slot="alert-dialog-action" class={cn(["contents", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
