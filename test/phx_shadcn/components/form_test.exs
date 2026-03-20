defmodule PhxShadcn.Components.FormTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  use Phoenix.Component
  import PhxShadcn.Components.Form

  # ── Helpers ──────────────────────────────────────────────────────────

  # Build a minimal FormField struct for testing.
  # `used: true` puts the field key into form.params so used_input?/1 returns true.
  defp form_field(opts) do
    name = Keyword.get(opts, :name, "user[email]")
    id = Keyword.get(opts, :id, "user_email")
    errors = Keyword.get(opts, :errors, [])
    value = Keyword.get(opts, :value, "")
    used = Keyword.get(opts, :used, false)

    params = if used, do: %{"email" => ""}, else: %{}

    form = to_form(params, as: "user")

    %Phoenix.HTML.FormField{
      id: id,
      name: name,
      errors: errors,
      value: value,
      field: :email,
      form: form
    }
  end

  # ── form_item/1 ─────────────────────────────────────────────────────

  describe "form_item/1" do
    test "renders div with data-slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.form_item>Content</.form_item>
        """)

      assert html =~ ~s(data-slot="form-item")
      assert html =~ "<div"
      assert html =~ "Content"
    end

    test "has default gap classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.form_item>Content</.form_item>
        """)

      assert html =~ "grid"
      assert html =~ "gap-2"
    end

    test "merges custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.form_item class="mt-4">Content</.form_item>
        """)

      assert html =~ "mt-4"
    end

    test "passes global attrs" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.form_item id="my-item">Content</.form_item>
        """)

      assert html =~ ~s(id="my-item")
    end
  end

  # ── form_label/1 ────────────────────────────────────────────────────

  describe "form_label/1" do
    test "renders label with data-slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.form_label>Email</.form_label>
        """)

      assert html =~ ~s(data-slot="form-label")
      assert html =~ "<label"
      assert html =~ "Email"
    end

    test "auto-sets for from field" do
      assigns = %{field: form_field(id: "user_email")}

      html =
        rendered_to_string(~H"""
        <.form_label field={@field}>Email</.form_label>
        """)

      assert html =~ ~s(for="user_email")
    end

    test "explicit for overrides field-derived for" do
      assigns = %{field: form_field(id: "user_email")}

      html =
        rendered_to_string(~H"""
        <.form_label field={@field} for="custom-id">Email</.form_label>
        """)

      assert html =~ ~s(for="custom-id")
    end

    test "without field works as plain label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.form_label for="my-input">Username</.form_label>
        """)

      assert html =~ ~s(for="my-input")
      assert html =~ "Username"
    end

    test "adds text-destructive when field has errors and is used" do
      assigns = %{field: form_field(errors: [{"is required", []}], used: true)}

      html =
        rendered_to_string(~H"""
        <.form_label field={@field}>Email</.form_label>
        """)

      assert html =~ "text-destructive"
    end

    test "no text-destructive when field has errors but is not used" do
      assigns = %{field: form_field(errors: [{"is required", []}], used: false)}

      html =
        rendered_to_string(~H"""
        <.form_label field={@field}>Email</.form_label>
        """)

      refute html =~ "text-destructive"
    end

    test "adds text-destructive when error prop is true" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.form_label error>Email</.form_label>
        """)

      assert html =~ "text-destructive"
    end

    test "no text-destructive when no errors" do
      assigns = %{field: form_field(errors: [])}

      html =
        rendered_to_string(~H"""
        <.form_label field={@field}>Email</.form_label>
        """)

      refute html =~ "text-destructive"
    end

    test "merges custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.form_label class="font-bold">Email</.form_label>
        """)

      assert html =~ "font-bold"
    end
  end

  # ── form_control/1 ──────────────────────────────────────────────────

  describe "form_control/1" do
    test "is a pass-through" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.form_control><input type="text" /></.form_control>
        """)

      assert html =~ ~s(<input type="text")
      # No wrapping div
      refute html =~ "data-slot"
    end
  end

  # ── form_description/1 ─────────────────────────────────────────────

  describe "form_description/1" do
    test "renders p with data-slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.form_description>Helper text</.form_description>
        """)

      assert html =~ ~s(data-slot="form-description")
      assert html =~ "<p"
      assert html =~ "Helper text"
    end

    test "has muted foreground text style" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.form_description>Helper text</.form_description>
        """)

      assert html =~ "text-muted-foreground"
      assert html =~ "text-sm"
    end

    test "merges custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.form_description class="italic">Helper text</.form_description>
        """)

      assert html =~ "italic"
    end
  end

  # ── form_message/1 ─────────────────────────────────────────────────

  describe "form_message/1" do
    test "renders nothing when no errors and no inner_block" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.form_message />
        """)

      refute html =~ "data-slot"
    end

    test "renders field errors when field has been used" do
      assigns = %{field: form_field(errors: [{"is required", []}], used: true)}

      html =
        rendered_to_string(~H"""
        <.form_message field={@field} />
        """)

      assert html =~ ~s(data-slot="form-message")
      assert html =~ "is required"
      assert html =~ "text-destructive"
    end

    test "renders nothing for unused field (no action)" do
      assigns = %{field: form_field(errors: [{"is required", []}], used: false)}

      html =
        rendered_to_string(~H"""
        <.form_message field={@field} />
        """)

      refute html =~ "is required"
    end

    test "renders explicit errors list" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.form_message errors={["must be valid", "is too short"]} />
        """)

      assert html =~ "must be valid"
      assert html =~ "is too short"
    end

    test "renders inner_block when no errors" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.form_message>Custom message</.form_message>
        """)

      assert html =~ "Custom message"
      assert html =~ ~s(data-slot="form-message")
    end

    test "explicit errors override field errors" do
      assigns = %{field: form_field(errors: [{"field error", []}], used: true)}

      html =
        rendered_to_string(~H"""
        <.form_message field={@field} errors={["explicit error"]} />
        """)

      assert html =~ "explicit error"
      refute html =~ "field error"
    end

    test "merges custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.form_message errors={["error"]} class="font-bold" />
        """)

      assert html =~ "font-bold"
    end

    test "renders multiple errors as multiple p elements" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.form_message errors={["error one", "error two"]} />
        """)

      assert length(Regex.scan(~r/data-slot="form-message"/, html)) == 2
    end
  end

  # ── translate_error/1 ──────────────────────────────────────────────

  describe "translate_error/1" do
    test "fallback interpolates %{key} placeholders" do
      # Ensure no translator configured for this test
      prev = Application.get_env(:phx_shadcn, :error_translator_function)
      Application.delete_env(:phx_shadcn, :error_translator_function)

      assert translate_error({"should be at least %{count} character(s)", [count: 3]}) ==
               "should be at least 3 character(s)"

      # Restore
      if prev, do: Application.put_env(:phx_shadcn, :error_translator_function, prev)
    end

    test "passes through plain strings" do
      assert translate_error("already taken") == "already taken"
    end
  end
end
