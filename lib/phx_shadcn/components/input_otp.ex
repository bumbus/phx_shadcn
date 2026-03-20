defmodule PhxShadcn.Components.InputOTP do
  @moduledoc """
  InputOTP component mirroring shadcn/ui InputOTP.

  A segmented code input where each character gets its own visual slot.
  Used for OTP codes, PINs, verification tokens, hex codes, etc.

  A single native `<input>` is positioned transparently over visual slot divs.
  All keyboard, paste, and autocomplete events go to this native input — no
  manual key handling needed. `autocomplete="one-time-code"` enables SMS autofill.

  Sub-components: `input_otp/1`, `input_otp_group/1`, `input_otp_slot/1`,
  `input_otp_separator/1`.

  ## State Modes

  - **Client-only** — no `value` or `on_value_change`. Pure JS, server unaware.
  - **Hybrid** — `on_value_change` set, no `value`. JS updates instantly + pushes event.
  - **Server-controlled** — `value` set. Server owns the state.

  ## Pattern presets

  - `"digits"` (default) — only `0-9`
  - `"alphanumeric"` — letters and digits
  - Any regex character class — e.g. `"[a-fA-F0-9]"` for hex

  ## Examples

      <%!-- 6-digit OTP, 2 groups of 3 with separator --%>
      <.input_otp id="otp" max_length={6}>
        <.input_otp_group>
          <.input_otp_slot :for={i <- 0..2} index={i} />
        </.input_otp_group>
        <.input_otp_separator />
        <.input_otp_group>
          <.input_otp_slot :for={i <- 3..5} index={i} />
        </.input_otp_group>
      </.input_otp>

      <%!-- 4-digit PIN --%>
      <.input_otp id="pin" max_length={4} on_complete="verify_pin">
        <.input_otp_group>
          <.input_otp_slot :for={i <- 0..3} index={i} />
        </.input_otp_group>
      </.input_otp>
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  # ── Pattern normalization ──────────────────────────────────────────

  @pattern_presets %{
    "digits" => "\\d",
    "alphanumeric" => "[a-zA-Z0-9]"
  }

  defp normalize_pattern(pattern) do
    Map.get(@pattern_presets, pattern, pattern)
  end

  defp inputmode_for_pattern("digits"), do: "numeric"
  defp inputmode_for_pattern("\\d"), do: "numeric"
  defp inputmode_for_pattern(_), do: "text"

  # ── input_otp (root) ──────────────────────────────────────────────

  @root_base_classes [
    "group/input-otp flex items-center gap-2 has-disabled:opacity-50"
  ]

  attr :id, :string, required: true
  attr :max_length, :integer, required: true
  attr :value, :string, default: nil
  attr :default_value, :string, default: nil
  attr :pattern, :string, default: "digits"
  attr :on_value_change, :any, default: nil
  attr :on_complete, :any, default: nil
  attr :disabled, :boolean, default: false
  attr :name, :string, default: nil
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def input_otp(assigns) do
    state_mode =
      cond do
        assigns.value != nil -> "server"
        assigns.on_value_change != nil -> "hybrid"
        true -> "client"
      end

    normalized_pattern = normalize_pattern(assigns.pattern)
    inputmode = inputmode_for_pattern(normalized_pattern)

    # Extract name from field if provided
    name = assigns.name || (assigns.field && assigns.field.name) || nil

    hidden_value =
      case {assigns.value, assigns.default_value} do
        {nil, nil} -> ""
        {nil, dv} -> dv || ""
        {v, _} -> v || ""
      end

    assigns =
      assigns
      |> assign(:state_mode, state_mode)
      |> assign(:normalized_pattern, normalized_pattern)
      |> assign(:inputmode, inputmode)
      |> assign(:computed_name, name)
      |> assign(:hidden_value, hidden_value)
      |> assign(:computed_class, cn([@root_base_classes, assigns.class]))

    ~H"""
    <div
      id={@id}
      data-slot="input-otp"
      data-state-mode={@state_mode}
      data-max-length={@max_length}
      data-value={@value}
      data-default-value={@default_value}
      data-pattern={@normalized_pattern}
      data-on-value-change={@on_value_change}
      data-on-complete={@on_complete}
      data-disabled={@disabled && "true"}
      class={@computed_class}
      phx-hook="PhxShadcnInputOTP"
      {@rest}
    >
      <div class="relative flex items-center gap-2 overflow-hidden">
        <%!-- Transparent native input — wider than container so password manager
             badges (Bitwarden, 1Password, etc.) render outside the clipped area --%>
        <input
          data-slot="input-otp-native"
          type="text"
          inputmode={@inputmode}
          autocomplete="one-time-code"
          maxlength={@max_length}
          disabled={@disabled}
          class="absolute inset-0 z-10 h-full w-[calc(100%+40px)] opacity-0 cursor-pointer disabled:cursor-not-allowed"
          tabindex="0"
        />

        <%!-- Visual slot content --%>
        {render_slot(@inner_block)}
      </div>

      <%!-- Hidden form input --%>
      <input
        :if={@computed_name}
        data-slot="input-otp-hidden"
        type="hidden"
        name={@computed_name}
        value={@hidden_value}
      />
    </div>
    """
  end

  # ── input_otp_group ───────────────────────────────────────────────

  @group_base_classes [
    "flex items-center"
  ]

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def input_otp_group(assigns) do
    assigns = assign(assigns, :computed_class, cn([@group_base_classes, assigns.class]))

    ~H"""
    <div data-slot="input-otp-group" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ── input_otp_slot ────────────────────────────────────────────────

  @slot_base_classes [
    "relative flex h-9 w-9 items-center justify-center",
    "border-y border-r border-input text-sm shadow-xs transition-all",
    "first:rounded-l-md first:border-l last:rounded-r-md",
    "data-[active=true]:z-10 data-[active=true]:border-ring data-[active=true]:ring-ring/50 data-[active=true]:ring-[3px]"
  ]

  attr :index, :integer, required: true
  attr :class, :any, default: []
  attr :rest, :global

  def input_otp_slot(assigns) do
    assigns = assign(assigns, :computed_class, cn([@slot_base_classes, assigns.class]))

    ~H"""
    <div
      data-slot="input-otp-slot"
      data-slot-index={@index}
      data-active="false"
      class={@computed_class}
      {@rest}
    >
      <span data-slot="input-otp-slot-char" class="pointer-events-none"></span>
      <div
        data-slot="input-otp-caret"
        class="pointer-events-none absolute inset-0 flex items-center justify-center"
        style="display: none;"
      >
        <div class="h-4 w-px animate-caret-blink bg-foreground duration-1000"></div>
      </div>
    </div>
    """
  end

  # ── input_otp_separator ───────────────────────────────────────────

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block

  def input_otp_separator(assigns) do
    ~H"""
    <div data-slot="input-otp-separator" role="separator" class={@class} {@rest}>
      <%= if @inner_block != [] do %>
        {render_slot(@inner_block)}
      <% else %>
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
          class="lucide lucide-minus"
        >
          <path d="M5 12h14" />
        </svg>
      <% end %>
    </div>
    """
  end
end
