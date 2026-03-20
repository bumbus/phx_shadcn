defmodule PhxShadcn.Components.FormField do
  @moduledoc """
  Convenience wrapper that renders a complete form field in one call.

  Internally composes `form_item`, `form_label`, `form_description`,
  `form_message`, and the appropriate input component based on `type`.

  For custom layouts (e.g. Switch next to label), use the individual
  primitives from `PhxShadcn.Components.Form` directly.

  ## Types

  - Standard HTML input types (`"text"`, `"email"`, `"password"`, etc.) → `<.input>`
  - `"textarea"` → `<.textarea>`
  - `"switch"` → `<.switch>` (horizontal layout)
  - `"toggle"` → `<.toggle>` (horizontal layout, use inner_block for icon)
  - `"checkbox"` → `<.checkbox>` (horizontal layout)
  - `"slider"` → `<.slider>` (standard vertical layout)
  - `"toggle_group"` → `<.toggle_group>` (pass items via inner_block)
  - `"radio_group"` → `<.radio_group>` (pass items via inner_block)
  - `"native_select"` → `<.native_select>` (pass options via inner_block)

  ## Examples

      <.form_field field={@form[:email]} label="Email" type="email"
        description="We'll never share your email." placeholder="you@example.com" />

      <.form_field field={@form[:bio]} label="Bio" type="textarea"
        description="Max 160 chars." />

      <.form_field field={@form[:notifications]} label="Notifications" type="switch"
        description="Receive email about new features." />

      <.form_field field={@form[:bold]} label="Bold" type="toggle" variant="outline">
        <svg .../>
      </.form_field>

      <.form_field field={@form[:terms]} label="Accept terms" type="checkbox"
        description="You agree to our Terms of Service." />

      <.form_field field={@form[:volume]} label="Volume" type="slider"
        default_value={50} description="Drag to adjust." />

      <.form_field field={@form[:alignment]} label="Alignment" type="toggle_group"
        variant="outline" description="Choose text alignment.">
        <.toggle_group_item value="left" variant="outline">Left</.toggle_group_item>
        <.toggle_group_item value="center" variant="outline">Center</.toggle_group_item>
        <.toggle_group_item value="right" variant="outline">Right</.toggle_group_item>
      </.form_field>

      <.form_field field={@form[:theme]} label="Theme" type="radio_group"
        description="Select a color theme.">
        <div class="flex items-center space-x-2">
          <.radio_group_item value="light" id="theme-1" />
          <.label for="theme-1">Light</.label>
        </div>
        <div class="flex items-center space-x-2">
          <.radio_group_item value="dark" id="theme-2" />
          <.label for="theme-2">Dark</.label>
        </div>
      </.form_field>
  """

  use Phoenix.Component
  import PhxShadcn.Components.Form
  import PhxShadcn.Components.Input
  import PhxShadcn.Components.Textarea
  import PhxShadcn.Components.Switch
  import PhxShadcn.Components.Toggle
  import PhxShadcn.Components.Checkbox
  import PhxShadcn.Components.Slider
  import PhxShadcn.Components.ToggleGroup
  import PhxShadcn.Components.RadioGroup
  import PhxShadcn.Components.NativeSelect
  import PhxShadcn.Components.Select
  import PhxShadcn.Components.InputOTP

  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, required: true
  attr :type, :string, default: "text"
  attr :description, :string, default: nil
  attr :class, :any, default: []

  # Input/Textarea attrs
  attr :placeholder, :string, default: nil

  # Switch attrs
  attr :default_checked, :boolean, default: false
  attr :size, :string, default: "default"

  # Toggle attrs
  attr :default_pressed, :boolean, default: false
  attr :variant, :string, default: "default"

  # Slider attrs
  attr :min, :any, default: 0
  attr :max, :any, default: 100
  attr :step, :any, default: 1
  attr :default_value, :any, default: nil
  attr :orientation, :string, default: "horizontal"

  # InputOTP attrs
  attr :max_length, :integer, default: 6
  attr :pattern, :string, default: "digits"

  # NativeSelect attrs
  attr :options, :list, default: nil
  attr :prompt, :string, default: nil

  # Shared interactive attrs
  attr :value, :string, default: nil
  attr :disabled, :boolean, default: false

  attr :rest, :global

  slot :inner_block

  def form_field(%{type: "switch"} = assigns) do
    assigns = assign_new(assigns, :field_id, fn -> assigns.field.id <> "-switch" end)

    ~H"""
    <.form_item class={@class}>
      <div class="flex items-center gap-3">
        <.switch
          id={@field_id}
          name={@field.name}
          value={@value || "true"}
          default_checked={@default_checked}
          size={@size}
          disabled={@disabled}
          {@rest}
        />
        <.form_label for={@field_id}>{@label}</.form_label>
      </div>
      <.form_description :if={@description}>{@description}</.form_description>
    </.form_item>
    """
  end

  def form_field(%{type: "toggle"} = assigns) do
    assigns = assign_new(assigns, :field_id, fn -> assigns.field.id <> "-toggle" end)

    ~H"""
    <.form_item class={@class}>
      <div class="flex items-center gap-3">
        <.toggle
          id={@field_id}
          name={@field.name}
          value={@value || "true"}
          default_pressed={@default_pressed}
          variant={@variant}
          size={@size}
          disabled={@disabled}
          aria-label={@label}
          {@rest}
        >
          {render_slot(@inner_block)}
        </.toggle>
        <.form_label for={@field_id}>{@label}</.form_label>
      </div>
      <.form_description :if={@description}>{@description}</.form_description>
    </.form_item>
    """
  end

  def form_field(%{type: "checkbox"} = assigns) do
    ~H"""
    <.form_item class={@class}>
      <div class="flex items-center gap-3">
        <.checkbox
          field={@field}
          value={@value || "true"}
          disabled={@disabled}
          {@rest}
        />
        <.form_label for={@field.id}>{@label}</.form_label>
      </div>
      <.form_description :if={@description}>{@description}</.form_description>
      <.form_message field={@field} />
    </.form_item>
    """
  end

  def form_field(%{type: "slider"} = assigns) do
    assigns = assign_new(assigns, :field_id, fn -> assigns.field.id <> "-slider" end)

    ~H"""
    <.form_item class={@class}>
      <.form_label field={@field}>{@label}</.form_label>
      <.slider
        id={@field_id}
        name={@field.name}
        default_value={@default_value || @field.value}
        min={@min}
        max={@max}
        step={@step}
        orientation={@orientation}
        disabled={@disabled}
        {@rest}
      />
      <.form_description :if={@description}>{@description}</.form_description>
      <.form_message field={@field} />
    </.form_item>
    """
  end

  def form_field(%{type: "toggle_group"} = assigns) do
    assigns = assign_new(assigns, :field_id, fn -> assigns.field.id <> "-toggle-group" end)

    ~H"""
    <.form_item class={@class}>
      <.form_label field={@field}>{@label}</.form_label>
      <.toggle_group
        id={@field_id}
        type="single"
        name={@field.name}
        default_value={@field.value}
        variant={@variant}
        {@rest}
      >
        {render_slot(@inner_block)}
      </.toggle_group>
      <.form_description :if={@description}>{@description}</.form_description>
      <.form_message field={@field} />
    </.form_item>
    """
  end

  def form_field(%{type: "radio_group"} = assigns) do
    assigns = assign_new(assigns, :field_id, fn -> assigns.field.id <> "-radio-group" end)

    ~H"""
    <.form_item class={@class}>
      <.form_label field={@field}>{@label}</.form_label>
      <.radio_group
        id={@field_id}
        name={@field.name}
        default_value={@field.value}
        disabled={@disabled}
        {@rest}
      >
        {render_slot(@inner_block)}
      </.radio_group>
      <.form_description :if={@description}>{@description}</.form_description>
      <.form_message field={@field} />
    </.form_item>
    """
  end

  def form_field(%{type: "textarea"} = assigns) do
    ~H"""
    <.form_item class={@class}>
      <.form_label field={@field}>{@label}</.form_label>
      <.textarea field={@field} placeholder={@placeholder} disabled={@disabled} {@rest} />
      <.form_description :if={@description}>{@description}</.form_description>
      <.form_message field={@field} />
    </.form_item>
    """
  end

  def form_field(%{type: "input_otp"} = assigns) do
    assigns = assign_new(assigns, :field_id, fn -> assigns.field.id <> "-otp" end)

    ~H"""
    <.form_item class={@class}>
      <.form_label field={@field}>{@label}</.form_label>
      <.input_otp
        id={@field_id}
        name={@field.name}
        max_length={@max_length}
        pattern={@pattern}
        default_value={to_string(@field.value || "")}
        disabled={@disabled}
        {@rest}
      >
        <.input_otp_group>
          <.input_otp_slot :for={i <- 0..(@max_length - 1)} index={i} />
        </.input_otp_group>
      </.input_otp>
      <.form_description :if={@description}>{@description}</.form_description>
      <.form_message field={@field} />
    </.form_item>
    """
  end

  def form_field(%{type: "select"} = assigns) do
    assigns = assign_new(assigns, :field_id, fn -> assigns.field.id <> "-select" end)

    ~H"""
    <.form_item class={@class}>
      <.form_label field={@field}>{@label}</.form_label>
      <.select id={@field_id} field={@field} default_value={to_string(@field.value || "")} {@rest}>
        <.select_trigger size={@size}>
          <.select_value placeholder={@prompt || @placeholder} />
        </.select_trigger>
        <.select_content>
          <%= if @options do %>
            <.select_item :for={{label, val} <- @options} value={to_string(val)}>{label}</.select_item>
          <% else %>
            {render_slot(@inner_block)}
          <% end %>
        </.select_content>
      </.select>
      <.form_description :if={@description}>{@description}</.form_description>
      <.form_message field={@field} />
    </.form_item>
    """
  end

  def form_field(%{type: "native_select"} = assigns) do
    ~H"""
    <.form_item class={@class}>
      <.form_label field={@field}>{@label}</.form_label>
      <.native_select field={@field} options={@options} prompt={@prompt} disabled={@disabled} {@rest}>
        {render_slot(@inner_block)}
      </.native_select>
      <.form_description :if={@description}>{@description}</.form_description>
      <.form_message field={@field} />
    </.form_item>
    """
  end

  def form_field(assigns) do
    ~H"""
    <.form_item class={@class}>
      <.form_label field={@field}>{@label}</.form_label>
      <.input
        field={@field}
        type={@type}
        placeholder={@placeholder}
        disabled={@disabled}
        {@rest}
      />
      <.form_description :if={@description}>{@description}</.form_description>
      <.form_message field={@field} />
    </.form_item>
    """
  end
end
