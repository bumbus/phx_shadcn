defmodule PhxShadcn.Components.Input do
  @moduledoc """
  Input component mirroring shadcn/ui Input.

  A styled `<input>` for text-like types. Includes focus ring, disabled
  state, file input styling, and `aria-invalid` error styles.

  For other input kinds, use dedicated components: Textarea, Checkbox,
  RadioGroup, Switch, Select, DatePicker.

  ## Examples

      <.input type="text" placeholder="Name" />
      <.input type="email" placeholder="Email" />
      <.input type="password" placeholder="Password" />
      <.input type="file" />
      <.input type="text" disabled />
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  @base_classes [
    "file:text-foreground placeholder:text-muted-foreground selection:bg-primary selection:text-primary-foreground",
    "dark:bg-input/30 border-input h-9 w-full min-w-0 rounded-md border bg-transparent px-3 py-1",
    "text-base shadow-xs transition-[color,box-shadow] outline-none md:text-sm",
    "file:inline-flex file:h-7 file:border-0 file:bg-transparent file:text-sm file:font-medium",
    "disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50",
    "focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]",
    "aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive"
  ]

  attr :field, Phoenix.HTML.FormField,
    default: nil,
    doc: "a form field struct, auto-extracts name, value, and id"

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :string, default: nil
  attr :type, :string, default: "text"
  attr :class, :any, default: []
  attr :rest, :global, include: ~w(
    accept autocomplete autofocus disabled form list max maxlength min minlength
    multiple pattern placeholder readonly required size step
  )

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil)
    |> assign(:id, assigns.id || field.id)
    |> assign(:name, assigns.name || field.name)
    |> assign(:value, assigns.value || field.value)
    |> input()
  end

  def input(assigns) do
    assigns =
      assign(assigns, :computed_class, cn([@base_classes, assigns.class]))

    ~H"""
    <input type={@type} id={@id} name={@name} value={@value} data-slot="input" class={@computed_class} {@rest} />
    """
  end
end
