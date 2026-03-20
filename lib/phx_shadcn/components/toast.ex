defmodule PhxShadcn.Components.Toast do
  @moduledoc """
  Toast component — auto-dismissing, stackable, swipeable notifications.

  Drop `<.toaster>` into your layout and it automatically consumes `@flash`
  as auto-dismissing toasts. Rich toasts are sent via `push_event` using the
  `toast/4` helper.

  ## Usage

  In your layout:

      <.toaster flash={@flash} />

  Existing `put_flash/3` calls render as toasts with zero code changes.

  For rich toasts from a LiveView:

      socket
      |> PhxShadcn.Components.Toast.toast(:success, "Record created",
        description: "The item was saved successfully.",
        action: %{label: "Undo", event: "undo-create"}
      )

  ## Positions

  `"bottom-right"` (default), `"bottom-left"`, `"bottom-center"`,
  `"top-right"`, `"top-left"`, `"top-center"`.
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  # ── toaster/1 ──────────────────────────────────────────────────────

  @doc """
  Renders the toast container.

  Consumes `@flash` automatically — `:info` flashes become success toasts,
  `:error` flashes become error toasts.

  ## Attributes

    * `id` — container id (default `"toaster"`)
    * `flash` — the flash map (required)
    * `position` — toast position (default `"bottom-right"`)
    * `duration` — default auto-dismiss ms (default `4000`)
    * `expand` — start with toasts expanded (default `false`)
    * `class` — additional CSS classes
  """
  attr :id, :string, default: "toaster"
  attr :flash, :map, required: true
  attr :position, :string, default: "bottom-right"
  attr :duration, :integer, default: 4000
  attr :expand, :boolean, default: false
  attr :offset, :string, default: "16px", doc: "Gutter from screen edges (CSS value, e.g. \"32px\", \"1rem\")"
  attr :class, :string, default: nil

  slot :icon_success, doc: "Custom icon for success toasts. Receives no assigns."
  slot :icon_info, doc: "Custom icon for info toasts."
  slot :icon_warning, doc: "Custom icon for warning toasts."
  slot :icon_error, doc: "Custom icon for error toasts."

  def toaster(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="PhxShadcnToast"
      phx-update="ignore"
      data-position={@position}
      data-duration={@duration}
      data-expand={to_string(@expand)}
      data-offset={@offset}
      data-flash-info={Phoenix.Flash.get(@flash, :info)}
      data-flash-error={Phoenix.Flash.get(@flash, :error)}
      class={cn(["fixed inset-0 pointer-events-none z-[100]", @class])}
      aria-live="polite"
    >
      <%!-- Icon templates — JS clones these for each toast.
           Override with slots: <:icon_success><.icon name="hero-check" /></:icon_success> --%>
      <template data-toast-icon="success">
        <%= if @icon_success != [] do %>
          {render_slot(@icon_success)}
        <% else %>
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/></svg>
        <% end %>
      </template>
      <template data-toast-icon="info">
        <%= if @icon_info != [] do %>
          {render_slot(@icon_info)}
        <% else %>
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/></svg>
        <% end %>
      </template>
      <template data-toast-icon="warning">
        <%= if @icon_warning != [] do %>
          {render_slot(@icon_warning)}
        <% else %>
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/><path d="M12 9v4"/><path d="M12 17h.01"/></svg>
        <% end %>
      </template>
      <template data-toast-icon="error">
        <%= if @icon_error != [] do %>
          {render_slot(@icon_error)}
        <% else %>
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="7.86 2 16.14 2 22 7.86 22 16.14 16.14 22 7.86 22 2 16.14 2 7.86 7.86 2"/><path d="m15 9-6 6"/><path d="m9 9 6 6"/></svg>
        <% end %>
      </template>

      <%!-- Reconnection toasts — work even when hook isn't running --%>
      <div
        class="fixed bottom-4 right-4 z-[101] pointer-events-auto"
        phx-disconnected={
          Phoenix.LiveView.JS.show(to: "##{@id}-reconnect")
          |> Phoenix.LiveView.JS.remove_attribute("hidden", to: "##{@id}-reconnect")
        }
        phx-connected={
          Phoenix.LiveView.JS.hide(to: "##{@id}-reconnect")
          |> Phoenix.LiveView.JS.set_attribute({"hidden", ""}, to: "##{@id}-reconnect")
        }
      >
        <div
          id={"#{@id}-reconnect"}
          hidden
          class="rounded-lg border border-border bg-background text-foreground shadow-lg p-4 text-sm flex items-center gap-2"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="size-4 animate-spin text-muted-foreground"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
          >
            <path d="M21 12a9 9 0 1 1-6.219-8.56" />
          </svg>
          Attempting to reconnect...
        </div>
      </div>
    </div>
    """
  end

  # ── toast/4 helper ─────────────────────────────────────────────────

  @doc """
  Pushes a rich toast to the client via `push_event`.

  Returns the socket with the event pushed.

  ## Options

    * `:description` — secondary text below the title
    * `:action` — `%{label: "Undo", event: "undo-create", payload: %{}}` — action button
    * `:duration` — override default auto-dismiss ms (0 = persistent)
    * `:dismissible` — whether the toast can be dismissed (default `true`)
    * `:id` — custom toast id (auto-generated if omitted)
    * `:target` — toaster element id (default `"toaster"`)

  ## Examples

      toast(socket, :success, "Created!")
      toast(socket, :error, "Failed", description: "Please try again")
      toast(socket, :info, "Uploaded", action: %{label: "View", event: "view-upload"})
  """
  def toast(socket, type, title, opts \\ []) do
    payload =
      %{
        id: opts[:target] || "toaster",
        command: "toast",
        type: to_string(type),
        title: title
      }
      |> maybe_put(:description, opts[:description])
      |> maybe_put(:action, opts[:action])
      |> maybe_put(:duration, opts[:duration])
      |> maybe_put(:dismissible, opts[:dismissible])
      |> maybe_put(:toast_id, opts[:id])

    Phoenix.LiveView.push_event(socket, "phx_shadcn:command", payload)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, val), do: Map.put(map, key, val)
end
