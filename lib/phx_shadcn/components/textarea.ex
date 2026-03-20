defmodule PhxShadcn.Components.Textarea do
  @moduledoc """
  Textarea component mirroring shadcn/ui Textarea.

  A styled `<textarea>` for multi-line text input. Includes focus ring,
  disabled state, and `aria-invalid` error styles. Uses `field-sizing-content`
  for auto-sizing with a minimum height.

  ## Examples

      <.textarea placeholder="Type your message here." />
      <.textarea placeholder="Bio" value="Hello world" />
      <.textarea placeholder="Notes" disabled />
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  @base_classes [
    "placeholder:text-muted-foreground selection:bg-primary selection:text-primary-foreground",
    "dark:bg-input/30 border-input flex field-sizing-content min-h-16 w-full rounded-md border bg-transparent px-3 py-2",
    "text-base shadow-xs transition-[color,box-shadow] outline-none md:text-sm",
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
  attr :class, :any, default: []
  attr :rest, :global, include: ~w(
    autocomplete autofocus cols disabled form maxlength minlength
    placeholder readonly required rows wrap
  )

  def textarea(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil)
    |> assign(:id, assigns.id || field.id)
    |> assign(:name, assigns.name || field.name)
    |> assign(:value, assigns.value || field.value)
    |> textarea()
  end

  def textarea(assigns) do
    assigns =
      assign(assigns, :computed_class, cn([@base_classes, assigns.class]))

    ~H"""
    <textarea id={@id} name={@name} data-slot="textarea" class={@computed_class} {@rest}>{@value}</textarea>
    """
  end
end
