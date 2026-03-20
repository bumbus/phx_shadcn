defmodule PhxShadcn.Components.CollapsibleTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  use Phoenix.Component
  import PhxShadcn.Components.Collapsible

  # ── collapsible/1 (root) ────────────────────────────────────────────

  describe "collapsible/1" do
    test "renders with required attrs and defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible id="col">
          <.collapsible_trigger>Toggle</.collapsible_trigger>
          <.collapsible_content>Content</.collapsible_content>
        </.collapsible>
        """)

      assert html =~ ~s(id="col")
      assert html =~ ~s(data-slot="collapsible")
      assert html =~ ~s(data-type="single")
      assert html =~ ~s(data-collapsible="true")
      assert html =~ ~s(phx-hook="Collapsible")
    end

    test "renders inner wrapper item with synthetic value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible id="col">
          <.collapsible_trigger>Toggle</.collapsible_trigger>
          <.collapsible_content>Content</.collapsible_content>
        </.collapsible>
        """)

      assert html =~ ~s(data-slot="collapsible-item")
      assert html =~ ~s(data-value="_")
      assert html =~ ~s(data-item-selector="[data-slot=collapsible-item]")
    end

    test "hook selectors point to collapsible slots" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible id="col">
          <.collapsible_trigger>T</.collapsible_trigger>
          <.collapsible_content>C</.collapsible_content>
        </.collapsible>
        """)

      assert html =~ ~s(data-trigger-selector="[data-slot=collapsible-trigger]")
      assert html =~ ~s(data-content-selector="[data-slot=collapsible-content]")
    end

    test "user class merges" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible id="col" class={["max-w-sm"]}>
          <.collapsible_trigger>T</.collapsible_trigger>
          <.collapsible_content>C</.collapsible_content>
        </.collapsible>
        """)

      assert html =~ "max-w-sm"
    end

    test "passes through global attrs" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible id="col" data-testid="my-col">
          <.collapsible_trigger>T</.collapsible_trigger>
          <.collapsible_content>C</.collapsible_content>
        </.collapsible>
        """)

      assert html =~ ~s(data-testid="my-col")
    end
  end

  # ── State mode detection ────────────────────────────────────────────

  describe "state mode detection" do
    test "client mode — no open, no on_open_change" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible id="col">
          <.collapsible_trigger>T</.collapsible_trigger>
          <.collapsible_content>C</.collapsible_content>
        </.collapsible>
        """)

      assert html =~ ~s(data-state-mode="client")
    end

    test "hybrid mode — on_open_change set, no open" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible id="col" on_open_change="toggled">
          <.collapsible_trigger>T</.collapsible_trigger>
          <.collapsible_content>C</.collapsible_content>
        </.collapsible>
        """)

      assert html =~ ~s(data-state-mode="hybrid")
      assert html =~ ~s(data-on-value-change="toggled")
    end

    test "server mode — open set" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible id="col" open={true} on_open_change="changed">
          <.collapsible_trigger>T</.collapsible_trigger>
          <.collapsible_content>C</.collapsible_content>
        </.collapsible>
        """)

      assert html =~ ~s(data-state-mode="server")
    end

    test "server mode open=true sets data-value to synthetic value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible id="col" open={true}>
          <.collapsible_trigger>T</.collapsible_trigger>
          <.collapsible_content>C</.collapsible_content>
        </.collapsible>
        """)

      [root_tag] = Regex.run(~r/<div id="col"[^>]*>/, html)
      assert root_tag =~ ~s(data-value="_")
    end

    test "server mode open=false sets empty data-value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible id="col" open={false}>
          <.collapsible_trigger>T</.collapsible_trigger>
          <.collapsible_content>C</.collapsible_content>
        </.collapsible>
        """)

      [root_tag] = Regex.run(~r/<div id="col"[^>]*>/, html)
      assert root_tag =~ ~s(data-value="")
    end
  end

  # ── default_open ────────────────────────────────────────────────────

  describe "default_open" do
    test "false by default — no data-default-value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible id="col">
          <.collapsible_trigger>T</.collapsible_trigger>
          <.collapsible_content>C</.collapsible_content>
        </.collapsible>
        """)

      [root_tag] = Regex.run(~r/<div id="col"[^>]*>/, html)
      refute root_tag =~ "data-default-value"
    end

    test "true sets data-default-value to synthetic value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible id="col" default_open>
          <.collapsible_trigger>T</.collapsible_trigger>
          <.collapsible_content>C</.collapsible_content>
        </.collapsible>
        """)

      assert html =~ ~s(data-default-value="_")
    end
  end

  # ── Animation duration ──────────────────────────────────────────────

  describe "animation_duration" do
    test "no duration style on root when default (200)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible id="col">
          <.collapsible_trigger>T</.collapsible_trigger>
          <.collapsible_content>C</.collapsible_content>
        </.collapsible>
        """)

      refute html =~ ~s(style="--accordion-duration:)
    end

    test "sets CSS variable when non-default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible id="col" animation_duration={300}>
          <.collapsible_trigger>T</.collapsible_trigger>
          <.collapsible_content>C</.collapsible_content>
        </.collapsible>
        """)

      assert html =~ "--accordion-duration: 300ms"
    end
  end

  # ── JS struct support ─────────────────────────────────────────────

  describe "JS struct support" do
    test "on_open_change accepts JS struct and renders it" do
      assigns = %{js: Phoenix.LiveView.JS.push("my-event", value: %{source: "collapsible"})}

      html =
        rendered_to_string(~H"""
        <.collapsible id="col" on_open_change={@js}>
          <.collapsible_trigger>T</.collapsible_trigger>
          <.collapsible_content>C</.collapsible_content>
        </.collapsible>
        """)

      assert html =~ ~s(data-on-value-change="[[)
      assert html =~ ~s(data-state-mode="hybrid")
    end
  end

  # ── collapsible_trigger/1 ───────────────────────────────────────────

  describe "collapsible_trigger/1" do
    test "renders with data-slot and data-state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible_trigger>Click me</.collapsible_trigger>
        """)

      assert html =~ ~s(data-slot="collapsible-trigger")
      assert html =~ ~s(data-state="closed")
      assert html =~ "Click me"
    end

    test "unstyled by default — no default classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible_trigger>T</.collapsible_trigger>
        """)

      # Trigger is unstyled — users wrap their own button/element inside
      assert html =~ "<div data-slot"
    end

    test "user class applies" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible_trigger class={["cursor-pointer"]}>T</.collapsible_trigger>
        """)

      assert html =~ "cursor-pointer"
    end

    test "passes through global attrs" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible_trigger data-testid="trig">T</.collapsible_trigger>
        """)

      assert html =~ ~s(data-testid="trig")
    end
  end

  # ── collapsible_content/1 ───────────────────────────────────────────

  describe "collapsible_content/1" do
    test "renders with animation classes and hidden by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible_content>Secret</.collapsible_content>
        """)

      assert html =~ ~s(data-slot="collapsible-content")
      assert html =~ ~s(data-state="closed")
      assert html =~ ~s(style="display:none")
      assert html =~ "overflow-hidden"
      assert html =~ "animate-accordion-down"
      assert html =~ "animate-accordion-up"
      assert html =~ "Secret"
    end

    test "user class merges" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible_content class={["p-4"]}>Text</.collapsible_content>
        """)

      assert html =~ "p-4"
      assert html =~ "overflow-hidden"
    end

    test "passes through global attrs" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible_content data-testid="content">Text</.collapsible_content>
        """)

      assert html =~ ~s(data-testid="content")
    end
  end

  # ── Composition ─────────────────────────────────────────────────────

  describe "composition" do
    test "full collapsible renders all parts" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible id="demo">
          <.collapsible_trigger>Toggle</.collapsible_trigger>
          <.collapsible_content>Hidden content</.collapsible_content>
        </.collapsible>
        """)

      assert html =~ ~s(data-slot="collapsible")
      assert html =~ ~s(data-slot="collapsible-item")
      assert html =~ ~s(data-slot="collapsible-trigger")
      assert html =~ ~s(data-slot="collapsible-content")
      assert html =~ "Toggle"
      assert html =~ "Hidden content"
    end

    test "trigger and content are inside the item wrapper" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.collapsible id="demo">
          <.collapsible_trigger>T</.collapsible_trigger>
          <.collapsible_content>C</.collapsible_content>
        </.collapsible>
        """)

      # The item wrapper should contain both trigger and content
      [item_onwards] = Regex.run(~r/data-slot="collapsible-item".*$/s, html)
      assert item_onwards =~ ~s(data-slot="collapsible-trigger")
      assert item_onwards =~ ~s(data-slot="collapsible-content")
    end
  end
end
