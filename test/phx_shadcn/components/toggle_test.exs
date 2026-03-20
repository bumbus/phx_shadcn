defmodule PhxShadcn.Components.ToggleTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  use Phoenix.Component
  import PhxShadcn.Components.Toggle

  # ── toggle/1 (basic rendering) ─────────────────────────────────────

  describe "toggle/1" do
    test "renders with required attrs and defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle id="t1">Bold</.toggle>
        """)

      assert html =~ ~s(id="t1")
      assert html =~ ~s(data-slot="toggle")
      assert html =~ ~s(type="button")
      assert html =~ ~s(phx-hook="Toggle")
      assert html =~ ~s(aria-pressed="false")
      assert html =~ ~s(data-state="off")
      assert html =~ "Bold"
    end

    test "renders as <button> element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle id="t1">B</.toggle>
        """)

      assert html =~ "<button"
    end

    test "default variant and size data attrs" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle id="t1">B</.toggle>
        """)

      assert html =~ ~s(data-variant="default")
      assert html =~ ~s(data-size="default")
    end
  end

  # ── Variants ───────────────────────────────────────────────────────

  describe "variants" do
    test "default variant classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle id="t1" variant="default">B</.toggle>
        """)

      assert html =~ "bg-transparent"
      assert html =~ ~s(data-variant="default")
    end

    test "outline variant classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle id="t1" variant="outline">B</.toggle>
        """)

      assert html =~ "border"
      assert html =~ "border-input"
      assert html =~ ~s(data-variant="outline")
    end
  end

  # ── Sizes ──────────────────────────────────────────────────────────

  describe "sizes" do
    test "default size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle id="t1">B</.toggle>
        """)

      assert html =~ "h-9"
      assert html =~ ~s(data-size="default")
    end

    test "sm size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle id="t1" size="sm">B</.toggle>
        """)

      assert html =~ "h-8"
      assert html =~ ~s(data-size="sm")
    end

    test "lg size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle id="t1" size="lg">B</.toggle>
        """)

      assert html =~ "h-10"
      assert html =~ ~s(data-size="lg")
    end
  end

  # ── State mode detection ───────────────────────────────────────────

  describe "state mode detection" do
    test "client mode — no pressed, no on_pressed_change" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle id="t1">B</.toggle>
        """)

      assert html =~ ~s(data-state-mode="client")
    end

    test "hybrid mode — on_pressed_change set, no pressed" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle id="t1" on_pressed_change="toggled">B</.toggle>
        """)

      assert html =~ ~s(data-state-mode="hybrid")
      assert html =~ ~s(data-on-pressed-change="toggled")
    end

    test "server mode — pressed set" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle id="t1" pressed={true}>B</.toggle>
        """)

      assert html =~ ~s(data-state-mode="server")
    end

    test "server mode — pressed=true sets data-state=on" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle id="t1" pressed={true}>B</.toggle>
        """)

      assert html =~ ~s(data-state="on")
      assert html =~ ~s(aria-pressed="true")
    end

    test "server mode — pressed=false sets data-state=off" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle id="t1" pressed={false}>B</.toggle>
        """)

      assert html =~ ~s(data-state="off")
      assert html =~ ~s(aria-pressed="false")
    end
  end

  # ── default_pressed ────────────────────────────────────────────────

  describe "default_pressed" do
    test "false by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle id="t1">B</.toggle>
        """)

      assert html =~ ~s(data-state="off")
      assert html =~ ~s(data-default-pressed="false")
    end

    test "true sets initial state to on" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle id="t1" default_pressed>B</.toggle>
        """)

      assert html =~ ~s(data-state="on")
      assert html =~ ~s(aria-pressed="true")
      assert html =~ ~s(data-default-pressed="true")
    end
  end

  # ── Disabled ───────────────────────────────────────────────────────

  describe "disabled" do
    test "not disabled by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle id="t1">B</.toggle>
        """)

      # bare "disabled" attr should not appear (note: "disabled:" in classes is fine)
      refute html =~ ~r/ disabled[ >]/
    end

    test "disabled attr renders on button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle id="t1" disabled>B</.toggle>
        """)

      assert html =~ ~r/ disabled[ >]/
    end
  end

  # ── Class override ─────────────────────────────────────────────────

  describe "class override" do
    test "user class merges with base classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle id="t1" class={["mt-4"]}>B</.toggle>
        """)

      assert html =~ "mt-4"
      assert html =~ "inline-flex"
    end
  end

  # ── Global attrs ───────────────────────────────────────────────────

  describe "global attrs" do
    test "passes through global attrs" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle id="t1" data-testid="my-toggle">B</.toggle>
        """)

      assert html =~ ~s(data-testid="my-toggle")
    end
  end

  # ── Form integration ───────────────────────────────────────────────

  describe "form integration" do
    test "renders hidden input when name is set" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle id="t1" name="format[bold]">B</.toggle>
        """)

      assert html =~ ~s(type="hidden")
      assert html =~ ~s(name="format[bold]")
    end

    test "hidden input value is empty when off" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle id="t1" name="format[bold]">B</.toggle>
        """)

      assert html =~ ~s(value="")
    end

    test "hidden input has active value when on" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle id="t1" name="format[bold]" default_pressed>B</.toggle>
        """)

      assert html =~ ~s(value="on")
    end

    test "custom value attr" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle id="t1" name="opt" value="yes" default_pressed>B</.toggle>
        """)

      assert html =~ ~s(value="yes")
      assert html =~ ~s(data-pressed-value="yes")
    end

    test "data-pressed-value on button when name is set" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle id="t1" name="opt">B</.toggle>
        """)

      assert html =~ ~s(data-pressed-value="on")
    end

    test "no data-pressed-value when name is nil" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle id="t1">B</.toggle>
        """)

      refute html =~ "data-pressed-value"
    end

    test "no hidden input when name is nil" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle id="t1">B</.toggle>
        """)

      refute html =~ ~s(type="hidden")
    end
  end

  # ── JS struct support ──────────────────────────────────────────────

  describe "JS struct support" do
    test "on_pressed_change accepts JS struct" do
      assigns = %{js: Phoenix.LiveView.JS.push("my-event", value: %{source: "toggle"})}

      html =
        rendered_to_string(~H"""
        <.toggle id="t1" on_pressed_change={@js}>B</.toggle>
        """)

      assert html =~ ~s(data-on-pressed-change="[[)
      assert html =~ ~s(data-state-mode="hybrid")
    end
  end
end
