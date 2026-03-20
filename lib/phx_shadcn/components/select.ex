defmodule PhxShadcn.Components.Select do
  @moduledoc """
  Select component mirroring shadcn/ui Select.

  A custom styled dropdown that replaces the native `<select>` with a floating
  popup, styled items with checkmarks, keyboard navigation, and typeahead.

  Sub-components: `select/1`, `select_trigger/1`, `select_value/1`,
  `select_content/1`, `select_item/1`, `select_group/1`, `select_label/1`,
  `select_separator/1`.

  ## State Modes

  - **Client-only** — no `value` or `on_value_change`. Pure JS, server unaware.
  - **Hybrid** — `on_value_change` set, no `value`. JS selects instantly + pushes event.
  - **Server-controlled** — `value` set. Server owns the state.

  ## Usage

  ### Client-only

      <.select id="fruit" default_value="apple">
        <.select_trigger>
          <.select_value placeholder="Pick a fruit" />
        </.select_trigger>
        <.select_content>
          <.select_item value="apple">Apple</.select_item>
          <.select_item value="banana">Banana</.select_item>
          <.select_item value="cherry">Cherry</.select_item>
        </.select_content>
      </.select>

  ### Form integration

      <.select id="lang" field={@form[:language]} default_value={@form[:language].value}>
        <.select_trigger>
          <.select_value placeholder="Select a language" />
        </.select_trigger>
        <.select_content>
          <.select_item value="en">English</.select_item>
          <.select_item value="de">Deutsch</.select_item>
        </.select_content>
      </.select>
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  alias Phoenix.LiveView.JS

  # ── show/hide helpers ──────────────────────────────────────────────

  @doc """
  Returns a `%JS{}` that opens a select by id.
  """
  def show_select(js \\ %JS{}, id) do
    JS.dispatch(js, "phx-shadcn:show", to: "##{id}")
  end

  @doc """
  Returns a `%JS{}` that closes a select by id.
  """
  def hide_select(js \\ %JS{}, id) do
    JS.dispatch(js, "phx-shadcn:hide", to: "##{id}")
  end

  # ── select (root) ──────────────────────────────────────────────────

  @doc """
  Renders a select wrapper with the Select hook.

  ## Attributes

  - `id` (required) — unique identifier
  - `value` — server-controlled value (enables server mode)
  - `default_value` — initial value for client/hybrid mode
  - `on_value_change` — JS command or event name on selection (enables hybrid mode)
  - `on_open_change` — JS command or event name on dismiss
  - `name` — form input name
  - `field` — Phoenix form field (extracts name, id, value)
  - `show` — when true, opens on mount (for `:if` pattern)
  - `animation_duration` — transition duration in ms (default: 150)
  - `class` — additional classes
  """

  attr :id, :string, required: true
  attr :value, :string, default: nil
  attr :default_value, :string, default: nil
  attr :on_value_change, :any, default: nil
  attr :on_open_change, :any, default: nil
  attr :name, :string, default: nil
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :show, :boolean, default: false
  attr :animation_duration, :integer, default: 150
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def select(assigns) do
    state_mode =
      cond do
        assigns.value != nil -> "server"
        assigns.on_value_change != nil -> "hybrid"
        true -> "client"
      end

    # Extract name from field if provided
    name = assigns.name || (assigns.field && assigns.field.name) || nil
    default_value = assigns.default_value || (assigns.field && to_string(assigns.field.value || "")) || nil

    hidden_value =
      case {assigns.value, default_value} do
        {nil, nil} -> ""
        {nil, dv} -> dv || ""
        {v, _} -> v || ""
      end

    assigns =
      assigns
      |> assign(:state_mode, state_mode)
      |> assign(:computed_name, name)
      |> assign(:computed_default_value, default_value)
      |> assign(:hidden_value, hidden_value)

    ~H"""
    <div
      id={@id}
      data-slot="select"
      data-state-mode={@state_mode}
      data-value={@value}
      data-default-value={@computed_default_value}
      data-on-value-change={@on_value_change}
      data-on-open-change={@on_open_change}
      data-auto-open={to_string(@show)}
      data-animation-duration={@animation_duration}
      class={cn(["relative inline-block", @class])}
      phx-hook="PhxShadcnSelect"
      {@rest}
    >
      {render_slot(@inner_block)}
      <input :if={@computed_name} type="hidden" name={@computed_name} value={@hidden_value} />
    </div>
    """
  end

  # ── select_trigger ─────────────────────────────────────────────────

  @doc """
  The trigger button that opens the dropdown.

  ## Attributes

  - `size` — `"default"` or `"sm"`
  - `disabled` — disables the trigger
  - `class` — additional classes
  """

  attr :size, :string, default: "default", values: ~w(default sm)
  attr :disabled, :boolean, default: false
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def select_trigger(assigns) do
    ~H"""
    <div data-select-trigger class="inline-flex">
      <button
        type="button"
        role="combobox"
        aria-expanded="false"
        aria-haspopup="listbox"
        data-slot="select-trigger"
        disabled={@disabled}
        class={
          cn([
            "border-input data-[placeholder]:text-muted-foreground [&_svg:not([class*='text-'])]:text-muted-foreground focus-visible:border-ring focus-visible:ring-ring/50 aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive",
            "flex w-fit items-center justify-between gap-2 rounded-md border bg-transparent px-3 py-2 text-sm shadow-xs outline-none focus-visible:ring-[3px]",
            "disabled:cursor-not-allowed disabled:opacity-50",
            "*:data-[slot=select-value]:line-clamp-1 *:data-[slot=select-value]:flex *:data-[slot=select-value]:items-center *:data-[slot=select-value]:gap-2",
            "[&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4",
            @size == "sm" && "h-8 rounded-md px-2.5 text-xs",
            @size == "default" && "h-9",
            @class
          ])
        }
        {@rest}
      >
        {render_slot(@inner_block)}
        <.chevron_down_icon />
      </button>
    </div>
    """
  end

  # ── select_value ───────────────────────────────────────────────────

  @doc """
  Displays the selected value or placeholder text.

  JS hook manages its `textContent` dynamically.
  """

  attr :placeholder, :string, default: ""
  attr :class, :any, default: []
  attr :rest, :global

  def select_value(assigns) do
    ~H"""
    <span
      data-slot="select-value"
      data-placeholder
      data-placeholder-text={@placeholder}
      class={cn(["pointer-events-none", @class])}
      {@rest}
    >{@placeholder}</span>
    """
  end

  # ── select_content ─────────────────────────────────────────────────

  @doc """
  The floating popup panel containing select items.

  ## Attributes

  - `side` — preferred side: `"top"`, `"right"`, `"bottom"` (default), `"left"`
  - `align` — alignment: `"start"` (default), `"center"`, `"end"`
  - `side_offset` — gap between trigger and content in px (default: 4)
  - `class` — additional classes
  """

  attr :side, :string, default: "bottom"
  attr :align, :string, default: "start"
  attr :side_offset, :integer, default: 4
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def select_content(assigns) do
    ~H"""
    <div
      data-slot="select-content"
      data-select-content
      data-side={@side}
      data-align={@align}
      data-side-offset={@side_offset}
      role="listbox"
      hidden
      class={
        cn([
          "bg-popover text-popover-foreground z-50 max-h-[min(var(--available-h,300px),300px)] min-w-[8rem] overflow-y-auto rounded-md border p-1 shadow-md outline-hidden",
          "opacity-0 scale-95",
          "data-[side=bottom]:translate-y-1 data-[side=top]:-translate-y-1 data-[side=left]:-translate-x-1 data-[side=right]:translate-x-1",
          "data-[state=open]:opacity-100 data-[state=open]:scale-100 data-[state=open]:translate-x-0 data-[state=open]:translate-y-0",
          "data-[state=closing]:ease-in",
          "transition-[opacity,transform,translate] duration-150 ease-out",
          "data-[side=bottom]:origin-top data-[side=top]:origin-bottom data-[side=left]:origin-right data-[side=right]:origin-left",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── select_item ────────────────────────────────────────────────────

  @doc """
  An individual option in the select dropdown.

  ## Attributes

  - `value` (required) — the option value
  - `disabled` — disables the item
  - `class` — additional classes
  """

  attr :value, :string, required: true
  attr :disabled, :boolean, default: false
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def select_item(assigns) do
    ~H"""
    <div
      data-slot="select-item"
      data-roving-item
      data-val={@value}
      data-disabled={@disabled}
      data-state="unchecked"
      role="option"
      aria-selected="false"
      tabindex="-1"
      class={
        cn([
          "focus:bg-accent focus:text-accent-foreground hover:bg-accent hover:text-accent-foreground",
          "relative flex w-full cursor-default items-center gap-2 rounded-sm py-1.5 pr-8 pl-2 text-sm outline-hidden select-none",
          "data-[disabled]:pointer-events-none data-[disabled]:opacity-50",
          "[&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
      <span
        data-select-indicator
        class="pointer-events-none absolute right-2 flex size-3.5 items-center justify-center opacity-0 [[aria-selected=true]>&]:opacity-100"
      >
        <.check_icon />
      </span>
    </div>
    """
  end

  # ── select_group ───────────────────────────────────────────────────

  @doc """
  Groups related select items.
  """

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def select_group(assigns) do
    ~H"""
    <div
      data-slot="select-group"
      role="group"
      class={cn(["p-1", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── select_label ───────────────────────────────────────────────────

  @doc """
  A non-interactive label for a group of select items.
  """

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def select_label(assigns) do
    ~H"""
    <div
      data-slot="select-label"
      class={cn(["text-muted-foreground px-2 py-1.5 text-xs font-medium", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── select_separator ───────────────────────────────────────────────

  @doc """
  A visual divider between groups.
  """

  attr :class, :any, default: []
  attr :rest, :global

  def select_separator(assigns) do
    ~H"""
    <div
      data-slot="select-separator"
      role="separator"
      class={cn(["bg-border -mx-1 my-1 h-px", @class])}
      {@rest}
    />
    """
  end

  # ── Icons (inline SVG) ─────────────────────────────────────────────

  defp check_icon(assigns) do
    ~H"""
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
      class="size-4"
    >
      <path d="M20 6 9 17l-5-5" />
    </svg>
    """
  end

  defp chevron_down_icon(assigns) do
    ~H"""
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
      class="size-4 opacity-50"
      aria-hidden="true"
    >
      <path d="m6 9 6 6 6-6" />
    </svg>
    """
  end
end
