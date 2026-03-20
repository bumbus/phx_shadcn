defmodule PhxShadcn.Components.Checkbox do
  @moduledoc """
  Checkbox component mirroring shadcn/ui Checkbox.

  A native `<input type="checkbox">` styled with `appearance-none` and a
  CSS-only SVG checkmark via the `peer`/`peer-checked:` pattern. Zero JS —
  all behavior (click, spacebar, form submission) comes from the browser.

  For full event support (hybrid/server state modes, custom callbacks),
  use `Switch` instead.

  ## Form integration

  Like Phoenix's own checkbox helper, a hidden input with `value="false"`
  is rendered before the checkbox. When unchecked the hidden input sends
  `"false"`; when checked the checkbox's value (default `"true"`) overrides it.

  ## Examples

      <.checkbox id="terms" name="terms" />
      <.checkbox id="terms" name="terms" checked />
      <.checkbox id="terms" name="terms" disabled />
      <.checkbox field={@form[:terms]} />
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  @input_classes [
    "peer appearance-none size-4 shrink-0 rounded-[4px] border border-input shadow-xs",
    "bg-transparent transition-shadow outline-none cursor-pointer",
    "checked:bg-primary checked:border-primary checked:text-primary-foreground",
    "focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]",
    "disabled:cursor-not-allowed disabled:opacity-50",
    "aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive"
  ]

  @icon_classes [
    "pointer-events-none absolute size-3 text-primary-foreground opacity-0",
    "peer-checked:opacity-100 transition-opacity"
  ]

  attr :field, Phoenix.HTML.FormField,
    default: nil,
    doc: "a form field struct, auto-extracts name, value, id, and checked state"

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :string, default: "true", doc: "value sent when checked"
  attr :checked, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :class, :any, default: []
  attr :rest, :global, include: ~w(required form autofocus)

  def checkbox(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil)
    |> assign(:id, assigns.id || field.id)
    |> assign(:name, assigns.name || field.name)
    |> assign(:checked, field.value == true || field.value == "true")
    |> checkbox()
  end

  def checkbox(assigns) do
    assigns =
      assigns
      |> assign(:computed_class, cn([@input_classes, assigns.class]))
      |> assign(:icon_classes, @icon_classes)

    ~H"""
    <span data-slot="checkbox" class="relative inline-flex items-center justify-center">
      <input
        :if={@name}
        type="hidden"
        name={@name}
        value="false"
      />
      <input
        type="checkbox"
        id={@id}
        name={@name}
        value={@value}
        checked={@checked}
        disabled={@disabled}
        class={@computed_class}
        {@rest}
      />
      <svg
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="3"
        stroke-linecap="round"
        stroke-linejoin="round"
        class={@icon_classes}
      >
        <path d="M20 6 9 17l-5-5" />
      </svg>
    </span>
    """
  end

end
