defmodule PhxShadcn.Components.Tabs do
  @moduledoc """
  Tabs component mirroring shadcn/ui Tabs.

  A set of trigger buttons showing one content panel at a time.
  Supports 3 state modes: client-only, hybrid, and server-controlled,
  plus patch mode for URL-driven tabs.

  Sub-components: `tabs/1`, `tabs_list/1`, `tabs_trigger/1`, `tabs_content/1`.

  ## State Modes

  - **Client-only** — no `value` or `on_value_change`. Pure JS, server unaware.
  - **Hybrid** — `on_value_change` set, no `value`. JS switches instantly + pushes event.
  - **Server-controlled** — `value` set. Server owns the state.
  - **Patch** — triggers render as `<.link patch>`. Active tab from URL via `handle_params`.

  ## Examples

      <.tabs id="my-tabs" default_value="account">
        <.tabs_list>
          <.tabs_trigger value="account">Account</.tabs_trigger>
          <.tabs_trigger value="password">Password</.tabs_trigger>
        </.tabs_list>
        <.tabs_content value="account">Account settings here.</.tabs_content>
        <.tabs_content value="password">Password settings here.</.tabs_content>
      </.tabs>
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  # ── Tabs (root) ──────────────────────────────────────────────────

  @tabs_base_classes [
    "group/tabs flex gap-2"
  ]

  attr :id, :string, required: true
  attr :value, :string, default: nil
  attr :default_value, :string, default: nil
  attr :on_value_change, :any, default: nil
  attr :orientation, :string, default: "horizontal", values: ~w(horizontal vertical)
  attr :activation_mode, :string, default: "automatic", values: ~w(automatic manual)
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def tabs(assigns) do
    state_mode =
      cond do
        assigns.value != nil -> "server"
        assigns.on_value_change != nil -> "hybrid"
        true -> "client"
      end

    orientation_class =
      case assigns.orientation do
        "vertical" -> "flex-row"
        _ -> "flex-col"
      end

    assigns =
      assigns
      |> assign(:state_mode, state_mode)
      |> assign(
        :computed_class,
        cn([@tabs_base_classes, orientation_class, assigns.class])
      )

    ~H"""
    <div
      id={@id}
      data-slot="tabs"
      data-orientation={@orientation}
      data-state-mode={@state_mode}
      data-value={@value}
      data-default-value={@default_value}
      data-on-value-change={@on_value_change}
      data-activation-mode={@activation_mode}
      class={@computed_class}
      phx-hook="PhxShadcnTabs"
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── TabsList ─────────────────────────────────────────────────────

  @list_base_classes [
    "rounded-lg p-[3px] group-data-[orientation=horizontal]/tabs:h-9",
    "group/tabs-list text-muted-foreground inline-flex w-fit items-center justify-center",
    "group-data-[orientation=vertical]/tabs:h-fit group-data-[orientation=vertical]/tabs:flex-col"
  ]

  @list_variant_classes %{
    "default" => "bg-muted",
    "line" => "gap-1 bg-transparent rounded-none"
  }

  attr :variant, :string, default: "default", values: ~w(default line)
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def tabs_list(assigns) do
    assigns =
      assign(
        assigns,
        :computed_class,
        cn([
          @list_base_classes,
          Map.fetch!(@list_variant_classes, assigns.variant),
          assigns.class
        ])
      )

    ~H"""
    <div
      role="tablist"
      data-slot="tabs-list"
      data-variant={@variant}
      class={@computed_class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── TabsTrigger ──────────────────────────────────────────────────

  @trigger_base_classes [
    "focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:outline-ring",
    "text-foreground/60 hover:text-foreground dark:text-muted-foreground dark:hover:text-foreground",
    "relative inline-flex h-[calc(100%-1px)] flex-1 items-center justify-center gap-1.5",
    "rounded-md border border-transparent px-2 py-1 text-sm font-medium whitespace-nowrap",
    "transition-all cursor-pointer",
    "group-data-[orientation=vertical]/tabs:w-full group-data-[orientation=vertical]/tabs:justify-start",
    "focus-visible:ring-[3px] focus-visible:outline-1",
    "disabled:pointer-events-none disabled:opacity-50",
    "group-data-[variant=default]/tabs-list:data-[state=active]:shadow-sm",
    "group-data-[variant=line]/tabs-list:data-[state=active]:shadow-none",
    "[&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4",
    # Default variant active state
    "data-[state=active]:bg-background dark:data-[state=active]:text-foreground",
    "dark:data-[state=active]:border-input dark:data-[state=active]:bg-input/30",
    "data-[state=active]:text-foreground",
    # Line variant: transparent backgrounds
    "group-data-[variant=line]/tabs-list:bg-transparent",
    "group-data-[variant=line]/tabs-list:data-[state=active]:bg-transparent",
    "dark:group-data-[variant=line]/tabs-list:data-[state=active]:border-transparent",
    "dark:group-data-[variant=line]/tabs-list:data-[state=active]:bg-transparent",
    # After pseudo-element for line variant underline indicator
    "after:bg-foreground after:absolute after:opacity-0 after:transition-opacity",
    "group-data-[orientation=horizontal]/tabs:after:inset-x-0",
    "group-data-[orientation=horizontal]/tabs:after:bottom-[-5px]",
    "group-data-[orientation=horizontal]/tabs:after:h-0.5",
    "group-data-[orientation=vertical]/tabs:after:inset-y-0",
    "group-data-[orientation=vertical]/tabs:after:-right-1",
    "group-data-[orientation=vertical]/tabs:after:w-0.5",
    "group-data-[variant=line]/tabs-list:data-[state=active]:after:opacity-100",
    # Loading state
    "phx-click-loading:opacity-70 phx-click-loading:pointer-events-none"
  ]

  attr :value, :string, required: true
  attr :disabled, :boolean, default: false
  attr :patch, :string, default: nil
  attr :navigate, :string, default: nil
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def tabs_trigger(assigns) do
    assigns =
      assign(
        assigns,
        :computed_class,
        cn([@trigger_base_classes, assigns.class])
      )

    ~H"""
    <.link
      :if={@patch != nil}
      patch={@patch}
      role="tab"
      data-slot="tabs-trigger"
      data-value={@value}
      data-state="inactive"
      data-disabled={@disabled && "true"}
      aria-selected="false"
      tabindex="-1"
      class={@computed_class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    <.link
      :if={@navigate != nil && @patch == nil}
      navigate={@navigate}
      role="tab"
      data-slot="tabs-trigger"
      data-value={@value}
      data-state="inactive"
      data-disabled={@disabled && "true"}
      aria-selected="false"
      tabindex="-1"
      class={@computed_class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    <button
      :if={@patch == nil && @navigate == nil}
      type="button"
      role="tab"
      data-slot="tabs-trigger"
      data-value={@value}
      data-state="inactive"
      data-disabled={@disabled && "true"}
      aria-selected="false"
      tabindex="-1"
      disabled={@disabled}
      class={@computed_class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  # ── TabsContent ──────────────────────────────────────────────────

  @content_base_classes [
    "flex-1 outline-none"
  ]

  attr :value, :string, required: true
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def tabs_content(assigns) do
    assigns =
      assign(
        assigns,
        :computed_class,
        cn([@content_base_classes, assigns.class])
      )

    ~H"""
    <div
      role="tabpanel"
      data-slot="tabs-content"
      data-value={@value}
      data-state="inactive"
      tabindex="0"
      hidden
      class={@computed_class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
