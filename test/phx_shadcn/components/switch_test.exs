defmodule PhxShadcn.Components.SwitchTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  use Phoenix.Component
  import PhxShadcn.Components.Switch

  # ── switch/1 (basic rendering) ─────────────────────────────────────

  describe "switch/1" do
    test "renders with required attrs and defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.switch id="s1" />
        """)

      assert html =~ ~s(id="s1")
      assert html =~ ~s(data-slot="switch")
      assert html =~ ~s(type="button")
      assert html =~ ~s(role="switch")
      assert html =~ ~s(phx-hook="Switch")
      assert html =~ ~s(aria-checked="false")
      assert html =~ ~s(data-state="unchecked")
    end

    test "renders as <button> element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.switch id="s1" />
        """)

      assert html =~ "<button"
    end

    test "renders thumb with data-slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.switch id="s1" />
        """)

      assert html =~ ~s(data-slot="switch-thumb")
    end

    test "thumb inherits data-state from track" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.switch id="s1" default_checked />
        """)

      # Both track and thumb should have checked state
      assert Regex.scan(~r/data-state="checked"/, html) |> length() == 2
    end

    test "default size data attr" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.switch id="s1" />
        """)

      assert html =~ ~s(data-size="default")
    end
  end

  # ── Sizes ──────────────────────────────────────────────────────────

  describe "sizes" do
    test "default size classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.switch id="s1" />
        """)

      assert html =~ "h-[1.15rem]"
      assert html =~ "w-8"
      assert html =~ "size-4"
      assert html =~ ~s(data-size="default")
    end

    test "sm size classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.switch id="s1" size="sm" />
        """)

      assert html =~ "h-3.5"
      assert html =~ "w-6"
      assert html =~ "size-3"
      assert html =~ ~s(data-size="sm")
    end
  end

  # ── State mode detection ───────────────────────────────────────────

  describe "state mode detection" do
    test "client mode — no checked, no on_checked_change" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.switch id="s1" />
        """)

      assert html =~ ~s(data-state-mode="client")
    end

    test "hybrid mode — on_checked_change set, no checked" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.switch id="s1" on_checked_change="switched" />
        """)

      assert html =~ ~s(data-state-mode="hybrid")
      assert html =~ ~s(data-on-checked-change="switched")
    end

    test "server mode — checked set" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.switch id="s1" checked={true} />
        """)

      assert html =~ ~s(data-state-mode="server")
    end

    test "server mode — checked=true sets data-state=checked" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.switch id="s1" checked={true} />
        """)

      assert html =~ ~s(data-state="checked")
      assert html =~ ~s(aria-checked="true")
    end

    test "server mode — checked=false sets data-state=unchecked" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.switch id="s1" checked={false} />
        """)

      assert html =~ ~s(data-state="unchecked")
      assert html =~ ~s(aria-checked="false")
    end
  end

  # ── default_checked ────────────────────────────────────────────────

  describe "default_checked" do
    test "false by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.switch id="s1" />
        """)

      assert html =~ ~s(data-state="unchecked")
      assert html =~ ~s(data-default-checked="false")
    end

    test "true sets initial state to checked" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.switch id="s1" default_checked />
        """)

      assert html =~ ~s(data-state="checked")
      assert html =~ ~s(aria-checked="true")
      assert html =~ ~s(data-default-checked="true")
    end
  end

  # ── Disabled ───────────────────────────────────────────────────────

  describe "disabled" do
    test "not disabled by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.switch id="s1" />
        """)

      # bare "disabled" attr should not appear (note: "disabled:" in classes is fine)
      refute html =~ ~r/ disabled[ >]/
    end

    test "disabled attr renders on button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.switch id="s1" disabled />
        """)

      assert html =~ ~r/ disabled[ >]/
    end
  end

  # ── Class override ─────────────────────────────────────────────────

  describe "class override" do
    test "user class merges with track classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.switch id="s1" class={["mt-4"]} />
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
        <.switch id="s1" data-testid="my-switch" />
        """)

      assert html =~ ~s(data-testid="my-switch")
    end
  end

  # ── JS struct support ──────────────────────────────────────────────

  describe "JS struct support" do
    test "on_checked_change accepts JS struct" do
      assigns = %{js: Phoenix.LiveView.JS.push("my-event", value: %{source: "switch"})}

      html =
        rendered_to_string(~H"""
        <.switch id="s1" on_checked_change={@js} />
        """)

      assert html =~ ~s(data-on-checked-change="[[)
      assert html =~ ~s(data-state-mode="hybrid")
    end
  end

  # ── Form integration ───────────────────────────────────────────────

  describe "form integration" do
    test "renders hidden input when name is set" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.switch id="s1" name="settings[notifications]" />
        """)

      assert html =~ ~s(type="hidden")
      assert html =~ ~s(name="settings[notifications]")
    end

    test "hidden input value is empty when unchecked" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.switch id="s1" name="prefs[dark]" />
        """)

      assert html =~ ~s(type="hidden")
      assert html =~ ~s(value="")
    end

    test "hidden input has active value when checked" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.switch id="s1" name="prefs[dark]" default_checked />
        """)

      assert html =~ ~s(type="hidden")
      assert html =~ ~s(value="on")
      # Input should not be disabled
      refute html =~ ~r/<input[^>]*disabled/
    end

    test "custom value attr" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.switch id="s1" name="opt" value="yes" default_checked />
        """)

      assert html =~ ~s(value="yes")
      assert html =~ ~s(data-checked-value="yes")
    end

    test "data-checked-value on button when name is set" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.switch id="s1" name="opt" />
        """)

      assert html =~ ~s(data-checked-value="on")
    end

    test "no data-checked-value when name is nil" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.switch id="s1" />
        """)

      refute html =~ "data-checked-value"
    end

    test "no hidden input when name is nil" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.switch id="s1" />
        """)

      refute html =~ ~s(type="hidden")
    end
  end
end
