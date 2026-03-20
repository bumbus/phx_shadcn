defmodule PhxShadcn.Components.Form do
  @moduledoc """
  Form structural primitives mirroring shadcn/ui's form composition pattern.

  These components provide layout and error display for form fields. They are
  composable building blocks — not a monolithic `input/1` component.

  ## Example

      <.form for={@form} phx-change="validate" phx-submit="save">
        <.form_item>
          <.form_label field={@form[:email]}>Email</.form_label>
          <.input name={@form[:email].name} value={@form[:email].value} type="email" />
          <.form_description>We'll never share your email.</.form_description>
          <.form_message field={@form[:email]} />
        </.form_item>
      </.form>

  ## Error Translation

  `form_message` translates `{msg, opts}` error tuples using a configurable function:

      config :phx_shadcn, :error_translator_function, {MyAppWeb.CoreComponents, :translate_error}

  If unconfigured, a built-in fallback interpolates `%{key}` placeholders.
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  # ── form_item ──────────────────────────────────────────────────────

  @doc """
  Container for a form field group (label + input + description + message).
  """

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def form_item(assigns) do
    assigns = assign(assigns, :computed_class, cn(["grid gap-2", assigns.class]))

    ~H"""
    <div data-slot="form-item" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── form_label ─────────────────────────────────────────────────────

  @doc """
  Error-aware label for form fields.

  When `field` is provided, auto-sets `for` to the field's ID and adds
  `text-destructive` styling when the field has errors.
  """

  attr :field, Phoenix.HTML.FormField, default: nil
  attr :error, :boolean, default: false
  attr :class, :any, default: []
  attr :rest, :global, include: ~w(for)

  slot :inner_block, required: true

  def form_label(assigns) do
    has_errors =
      assigns.error ||
        (assigns.field != nil && assigns.field.errors != [] && used_input?(assigns.field))

    for_value =
      if assigns.field != nil && !Map.has_key?(assigns.rest, :for) do
        assigns.field.id
      else
        assigns.rest[:for]
      end

    rest = Map.delete(assigns.rest, :for)

    assigns =
      assigns
      |> assign(:has_errors, has_errors)
      |> assign(:for_value, for_value)
      |> assign(:label_rest, rest)

    assigns =
      assign(
        assigns,
        :computed_class,
        cn([
          "flex items-center gap-2 text-sm leading-none font-medium select-none",
          "group-data-[disabled=true]:pointer-events-none group-data-[disabled=true]:opacity-50",
          "peer-disabled:cursor-not-allowed peer-disabled:opacity-50",
          has_errors && "text-destructive",
          assigns.class
        ])
      )

    ~H"""
    <label data-slot="form-label" for={@for_value} class={@computed_class} {@label_rest}>
      {render_slot(@inner_block)}
    </label>
    """
  end

  # ── form_control ───────────────────────────────────────────────────

  @doc """
  Semantic pass-through. Maintains shadcn API parity.
  """

  slot :inner_block, required: true

  def form_control(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  # ── form_description ───────────────────────────────────────────────

  @doc """
  Helper text displayed below a form input.
  """

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def form_description(assigns) do
    assigns =
      assign(assigns, :computed_class, cn(["text-muted-foreground text-sm", assigns.class]))

    ~H"""
    <p data-slot="form-description" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </p>
    """
  end

  # ── form_message ───────────────────────────────────────────────────

  @doc """
  Displays validation errors for a form field.

  When `field` is provided, errors only display after the field has been
  interacted with (via `Phoenix.Component.used_input?/1`). This prevents
  showing errors on initial page load.

  You can also pass pre-translated `errors` strings directly, or use the
  inner block for a custom message.
  """

  attr :field, Phoenix.HTML.FormField, default: nil
  attr :errors, :list, default: []
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block

  def form_message(assigns) do
    errors = resolve_errors(assigns.field, assigns.errors)
    assigns = assign(assigns, :resolved_errors, errors)

    assigns =
      assign(assigns, :computed_class, cn(["text-destructive text-sm", assigns.class]))

    ~H"""
    <p
      :for={error <- @resolved_errors}
      data-slot="form-message"
      class={@computed_class}
      {@rest}
    >
      {error}
    </p>
    <p
      :if={@resolved_errors == [] && @inner_block != []}
      data-slot="form-message"
      class={@computed_class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </p>
    """
  end

  # ── Error translation helpers ──────────────────────────────────────

  defp resolve_errors(nil, []), do: []
  defp resolve_errors(nil, errors) when is_list(errors), do: errors

  defp resolve_errors(%Phoenix.HTML.FormField{} = field, []) do
    if used_input?(field) do
      Enum.map(field.errors, &translate_error/1)
    else
      []
    end
  end

  defp resolve_errors(_field, errors) when is_list(errors), do: errors

  @doc """
  Translates an error tuple `{msg, opts}` using the configured translator
  or a built-in fallback that interpolates `%{key}` placeholders.

  ## Configuration

      config :phx_shadcn, :error_translator_function,
        {MyAppWeb.CoreComponents, :translate_error}
  """
  def translate_error({msg, opts}) do
    case Application.get_env(:phx_shadcn, :error_translator_function) do
      {mod, fun} -> apply(mod, fun, [{msg, opts}])
      nil -> fallback_translate(msg, opts)
    end
  end

  def translate_error(msg) when is_binary(msg), do: msg

  defp fallback_translate(msg, opts) do
    Enum.reduce(opts, msg, fn {key, val}, acc ->
      String.replace(acc, "%{#{key}}", to_string(val))
    end)
  end
end
