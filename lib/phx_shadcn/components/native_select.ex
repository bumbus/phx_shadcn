defmodule PhxShadcn.Components.NativeSelect do
  @moduledoc """
  NativeSelect component mirroring shadcn/ui NativeSelect.

  A styled `<select>` that uses the browser's native dropdown. Better
  accessibility and mobile experience than custom selects, but options
  cannot be styled.

  Includes a decorative chevron icon, focus ring, disabled state, and
  `aria-invalid` error styles.

  ## Examples

      <%!-- Simple: options attr --%>
      <.native_select
        options={[{"Pick a fruit", ""}, {"Apple", "apple"}, {"Banana", "banana"}]}
      />

      <%!-- With form field --%>
      <.native_select field={@form[:fruit]}
        options={[{"Apple", "apple"}, {"Banana", "banana"}]}
      />

      <%!-- Advanced: inner_block for optgroups --%>
      <.native_select>
        <.native_select_optgroup label="Fruits">
          <.native_select_option value="apple">Apple</.native_select_option>
          <.native_select_option value="banana">Banana</.native_select_option>
        </.native_select_optgroup>
        <.native_select_optgroup label="Vegetables">
          <.native_select_option value="carrot">Carrot</.native_select_option>
        </.native_select_optgroup>
      </.native_select>
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  @select_classes [
    "placeholder:text-muted-foreground selection:bg-primary selection:text-primary-foreground",
    "dark:bg-input/30 dark:hover:bg-input/50 border-input",
    "h-9 w-full min-w-0 appearance-none rounded-md border bg-transparent px-3 py-2 pr-9",
    "text-base shadow-xs transition-[color,box-shadow] outline-none md:text-sm",
    "disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50",
    "focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]",
    "aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive"
  ]

  # -- native_select ----------------------------------------------------------

  attr :field, Phoenix.HTML.FormField,
    default: nil,
    doc: "a form field struct, auto-extracts name, value, and id"

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :string, default: nil
  attr :size, :string, default: "default", values: ~w(default sm)

  attr :options, :list,
    default: nil,
    doc: "list of {label, value} tuples, e.g. [{\"Apple\", \"apple\"}]"

  attr :prompt, :string, default: nil, doc: "placeholder option with empty value"
  attr :class, :any, default: []
  attr :rest, :global, include: ~w(autofocus disabled form multiple required)

  slot :inner_block

  def native_select(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil)
    |> assign(:id, assigns.id || field.id)
    |> assign(:name, assigns.name || field.name)
    |> assign(:value, assigns.value || field.value)
    |> native_select()
  end

  def native_select(assigns) do
    assigns =
      assign(
        assigns,
        :computed_class,
        cn([@select_classes, size_class(assigns.size), assigns.class])
      )

    ~H"""
    <div
      data-slot="native-select-wrapper"
      class="group/native-select relative w-fit has-[select:disabled]:opacity-50"
    >
      <select
        data-slot="native-select"
        id={@id}
        name={@name}
        value={@value}
        class={@computed_class}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        <%= if @options do %>
          <option :for={{label, val} <- @options} value={val}>{label}</option>
        <% else %>
          {render_slot(@inner_block)}
        <% end %>
      </select>
      <svg
        xmlns="http://www.w3.org/2000/svg"
        width="24"
        height="24"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="2"
        stroke-linecap="round"
        stroke-linejoin="round"
        class="text-muted-foreground pointer-events-none absolute top-1/2 right-3.5 size-4 -translate-y-1/2 opacity-50 select-none"
        aria-hidden="true"
        data-slot="native-select-icon"
      >
        <path d="m6 9 6 6 6-6" />
      </svg>
    </div>
    """
  end

  defp size_class("sm"), do: "h-8 py-1"
  defp size_class(_default), do: nil

  # -- native_select_option ----------------------------------------------------

  attr :value, :string, default: nil
  attr :class, :any, default: []
  attr :rest, :global, include: ~w(disabled selected)

  slot :inner_block, required: true

  def native_select_option(assigns) do
    ~H"""
    <option data-slot="native-select-option" value={@value} class={@class} {@rest}>
      {render_slot(@inner_block)}
    </option>
    """
  end

  # -- native_select_optgroup --------------------------------------------------

  attr :label, :string, required: true
  attr :class, :any, default: []
  attr :rest, :global, include: ~w(disabled)

  slot :inner_block, required: true

  def native_select_optgroup(assigns) do
    ~H"""
    <optgroup data-slot="native-select-optgroup" label={@label} class={@class} {@rest}>
      {render_slot(@inner_block)}
    </optgroup>
    """
  end
end
