defmodule PhxShadcn.Components.CheckboxTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  use Phoenix.Component
  import PhxShadcn.Components.Checkbox

  # ── Basic rendering ─────────────────────────────────────────────────

  describe "checkbox/1" do
    test "renders with data-slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox id="cb1" />
        """)

      assert html =~ ~s(data-slot="checkbox")
    end

    test "renders as <input type=\"checkbox\">" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox id="cb1" />
        """)

      assert html =~ ~s(type="checkbox")
    end

    test "renders with appearance-none class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox id="cb1" />
        """)

      assert html =~ "appearance-none"
    end

    test "renders id on the input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox id="my-cb" />
        """)

      assert html =~ ~s(id="my-cb")
    end

    test "renders SVG checkmark icon" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox id="cb1" />
        """)

      assert html =~ "<svg"
      assert html =~ "M20 6 9 17l-5-5"
    end

    test "SVG has peer-checked:opacity-100 class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox id="cb1" />
        """)

      assert html =~ "peer-checked:opacity-100"
    end

    test "wrapping span has relative positioning" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox id="cb1" />
        """)

      assert html =~ "relative"
      assert html =~ "inline-flex"
    end
  end

  # ── Hidden input ────────────────────────────────────────────────────

  describe "hidden input" do
    test "renders hidden input when name is set" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox id="cb1" name="terms" />
        """)

      assert html =~ ~s(type="hidden")
      assert html =~ ~s(value="false")
    end

    test "hidden input has same name as checkbox" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox id="cb1" name="settings[terms]" />
        """)

      # Should appear twice: once on hidden, once on checkbox
      assert length(Regex.scan(~r/name="settings\[terms\]"/, html)) == 2
    end

    test "no hidden input when name is nil" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox id="cb1" />
        """)

      refute html =~ ~s(type="hidden")
    end
  end

  # ── Checked state ───────────────────────────────────────────────────

  describe "checked state" do
    test "not checked by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox id="cb1" />
        """)

      # The bare "checked" attribute should not appear (CSS classes like checked: are fine)
      refute html =~ ~r/ checked[ >]/
    end

    test "checked attr renders on input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox id="cb1" checked />
        """)

      assert html =~ "checked"
    end
  end

  # ── Disabled state ──────────────────────────────────────────────────

  describe "disabled state" do
    test "not disabled by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox id="cb1" />
        """)

      # bare "disabled" attr should not appear (note: "disabled:" in classes is fine)
      refute html =~ ~r/ disabled[ >]/
    end

    test "disabled attr renders on input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox id="cb1" disabled />
        """)

      assert html =~ ~r/ disabled[ >]/
    end
  end

  # ── Custom value ────────────────────────────────────────────────────

  describe "custom value" do
    test "default value is 'true'" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox id="cb1" name="terms" />
        """)

      assert html =~ ~s(value="true")
    end

    test "custom value attr" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox id="cb1" name="terms" value="accepted" />
        """)

      assert html =~ ~s(value="accepted")
    end
  end

  # ── Class override ──────────────────────────────────────────────────

  describe "class override" do
    test "user class merges with base classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox id="cb1" class={["mt-4"]} />
        """)

      assert html =~ "mt-4"
      assert html =~ "appearance-none"
    end

    test "user class as string" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox id="cb1" class="ring-2" />
        """)

      assert html =~ "ring-2"
    end
  end

  # ── Global attrs passthrough ────────────────────────────────────────

  describe "global attrs" do
    test "passes through global attrs" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox id="cb1" data-testid="my-checkbox" />
        """)

      assert html =~ ~s(data-testid="my-checkbox")
    end

    test "passes through required attr" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox id="cb1" required />
        """)

      assert html =~ "required"
    end
  end

  # ── FormField extraction ────────────────────────────────────────────

  describe "FormField extraction" do
    test "extracts id from field" do
      assigns = %{
        field: %Phoenix.HTML.FormField{
          form: %Phoenix.HTML.Form{},
          field: :terms,
          id: "settings_terms",
          name: "settings[terms]",
          errors: [],
          value: false
        }
      }

      html =
        rendered_to_string(~H"""
        <.checkbox field={@field} />
        """)

      assert html =~ ~s(id="settings_terms")
    end

    test "extracts name from field" do
      assigns = %{
        field: %Phoenix.HTML.FormField{
          form: %Phoenix.HTML.Form{},
          field: :terms,
          id: "settings_terms",
          name: "settings[terms]",
          errors: [],
          value: false
        }
      }

      html =
        rendered_to_string(~H"""
        <.checkbox field={@field} />
        """)

      assert html =~ ~s(name="settings[terms]")
    end

    test "extracts checked=true from field value true" do
      assigns = %{
        field: %Phoenix.HTML.FormField{
          form: %Phoenix.HTML.Form{},
          field: :terms,
          id: "settings_terms",
          name: "settings[terms]",
          errors: [],
          value: true
        }
      }

      html =
        rendered_to_string(~H"""
        <.checkbox field={@field} />
        """)

      assert html =~ "checked"
    end

    test "extracts checked=true from field value \"true\"" do
      assigns = %{
        field: %Phoenix.HTML.FormField{
          form: %Phoenix.HTML.Form{},
          field: :terms,
          id: "settings_terms",
          name: "settings[terms]",
          errors: [],
          value: "true"
        }
      }

      html =
        rendered_to_string(~H"""
        <.checkbox field={@field} />
        """)

      assert html =~ "checked"
    end

    test "not checked when field value is false" do
      assigns = %{
        field: %Phoenix.HTML.FormField{
          form: %Phoenix.HTML.Form{},
          field: :terms,
          id: "settings_terms",
          name: "settings[terms]",
          errors: [],
          value: false
        }
      }

      html =
        rendered_to_string(~H"""
        <.checkbox field={@field} />
        """)

      refute html =~ ~r/ checked[ >]/
    end
  end

  # ── CSS classes present ─────────────────────────────────────────────

  describe "CSS classes" do
    test "has shadcn checkbox styling" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox id="cb1" />
        """)

      assert html =~ "size-4"
      assert html =~ "rounded-[4px]"
      assert html =~ "border-input"
      assert html =~ "shadow-xs"
    end

    test "has checked state classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox id="cb1" />
        """)

      assert html =~ "checked:bg-primary"
      assert html =~ "checked:border-primary"
    end

    test "has focus-visible classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox id="cb1" />
        """)

      assert html =~ "focus-visible:border-ring"
      assert html =~ "focus-visible:ring-ring/50"
    end

    test "has aria-invalid classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox id="cb1" />
        """)

      assert html =~ "aria-invalid:border-destructive"
    end

    test "has disabled classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox id="cb1" />
        """)

      assert html =~ "disabled:cursor-not-allowed"
      assert html =~ "disabled:opacity-50"
    end
  end
end
