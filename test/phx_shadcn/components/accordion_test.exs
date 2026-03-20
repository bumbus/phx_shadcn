defmodule PhxShadcn.Components.AccordionTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  use Phoenix.Component
  import PhxShadcn.Components.Accordion

  # ── accordion/1 (root) ──────────────────────────────────────────────

  describe "accordion/1" do
    test "renders with required attrs and default config" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion id="acc">
          <.accordion_item value="a"><.accordion_trigger>T</.accordion_trigger></.accordion_item>
        </.accordion>
        """)

      assert html =~ ~s(id="acc")
      assert html =~ ~s(data-slot="accordion")
      assert html =~ ~s(data-type="single")
      assert html =~ ~s(data-collapsible="false")
      assert html =~ ~s(phx-hook="Collapsible")
      assert html =~ "w-full"
    end

    test "renders type=multiple" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion id="acc" type="multiple">
          <.accordion_item value="a"><.accordion_trigger>T</.accordion_trigger></.accordion_item>
        </.accordion>
        """)

      assert html =~ ~s(data-type="multiple")
    end

    test "renders collapsible=true" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion id="acc" collapsible>
          <.accordion_item value="a"><.accordion_trigger>T</.accordion_trigger></.accordion_item>
        </.accordion>
        """)

      assert html =~ ~s(data-collapsible="true")
    end

    test "user class overrides via cn()" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion id="acc" class={["max-w-md"]}>
          <.accordion_item value="a"><.accordion_trigger>T</.accordion_trigger></.accordion_item>
        </.accordion>
        """)

      assert html =~ "max-w-md"
      assert html =~ "w-full"
    end

    test "passes through global attrs" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion id="acc" data-testid="my-acc">
          <.accordion_item value="a"><.accordion_trigger>T</.accordion_trigger></.accordion_item>
        </.accordion>
        """)

      assert html =~ ~s(data-testid="my-acc")
    end

    test "hook selector data attrs are present" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion id="acc">
          <.accordion_item value="a"><.accordion_trigger>T</.accordion_trigger></.accordion_item>
        </.accordion>
        """)

      assert html =~ ~s(data-item-selector="[data-slot=accordion-item]")
      assert html =~ ~s(data-trigger-selector="[data-slot=accordion-trigger]")
      assert html =~ ~s(data-content-selector="[data-slot=accordion-content]")
    end
  end

  # ── State mode detection ────────────────────────────────────────────

  describe "state mode detection" do
    test "client mode — no value, no on_value_change" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion id="acc">
          <.accordion_item value="a"><.accordion_trigger>T</.accordion_trigger></.accordion_item>
        </.accordion>
        """)

      assert html =~ ~s(data-state-mode="client")
    end

    test "hybrid mode — on_value_change set, no value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion id="acc" on_value_change="toggled">
          <.accordion_item value="a"><.accordion_trigger>T</.accordion_trigger></.accordion_item>
        </.accordion>
        """)

      assert html =~ ~s(data-state-mode="hybrid")
      assert html =~ ~s(data-on-value-change="toggled")
    end

    test "server mode — value set" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion id="acc" value="a" on_value_change="changed">
          <.accordion_item value="a"><.accordion_trigger>T</.accordion_trigger></.accordion_item>
        </.accordion>
        """)

      assert html =~ ~s(data-state-mode="server")
      assert html =~ ~s(data-value="a")
    end

    test "server mode — value set without on_value_change" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion id="acc" value="a">
          <.accordion_item value="a"><.accordion_trigger>T</.accordion_trigger></.accordion_item>
        </.accordion>
        """)

      assert html =~ ~s(data-state-mode="server")
    end
  end

  # ── Value serialization ─────────────────────────────────────────────

  describe "value serialization" do
    test "single string value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion id="acc" value="item-1">
          <.accordion_item value="item-1"><.accordion_trigger>T</.accordion_trigger></.accordion_item>
        </.accordion>
        """)

      assert html =~ ~s(data-value="item-1")
    end

    test "list value serialized as comma-separated" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion id="acc" type="multiple" value={["a", "b"]}>
          <.accordion_item value="a"><.accordion_trigger>T</.accordion_trigger></.accordion_item>
        </.accordion>
        """)

      assert html =~ ~s(data-value="a,b")
    end

    test "nil value omits data-value on root" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion id="acc">
          <.accordion_item value="a"><.accordion_trigger>T</.accordion_trigger></.accordion_item>
        </.accordion>
        """)

      # Root div should not have data-value (the item's data-value is expected)
      # Extract just the root element's opening tag to check
      [root_tag] = Regex.run(~r/<div id="acc"[^>]*>/, html)
      refute root_tag =~ "data-value="
    end

    test "single default_value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion id="acc" default_value="item-2">
          <.accordion_item value="item-2"><.accordion_trigger>T</.accordion_trigger></.accordion_item>
        </.accordion>
        """)

      assert html =~ ~s(data-default-value="item-2")
    end

    test "list default_value serialized as comma-separated" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion id="acc" type="multiple" default_value={["x", "y"]}>
          <.accordion_item value="x"><.accordion_trigger>T</.accordion_trigger></.accordion_item>
        </.accordion>
        """)

      assert html =~ ~s(data-default-value="x,y")
    end
  end

  # ── Animation duration ──────────────────────────────────────────────

  describe "animation_duration" do
    test "no duration style on root when default (200)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion id="acc">
          <.accordion_item value="a"><.accordion_trigger>T</.accordion_trigger></.accordion_item>
        </.accordion>
        """)

      # Root div should not have a --accordion-duration declaration
      # (the SVG fallback var reference is fine — we only check the root's style attr)
      refute html =~ ~s(style="--accordion-duration:)
    end

    test "sets CSS variable when non-default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion id="acc" animation_duration={400}>
          <.accordion_item value="a"><.accordion_trigger>T</.accordion_trigger></.accordion_item>
        </.accordion>
        """)

      assert html =~ "--accordion-duration: 400ms"
    end
  end

  # ── accordion_item/1 ────────────────────────────────────────────────

  describe "accordion_item/1" do
    test "renders with required value and default classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion_item value="q1">Content</.accordion_item>
        """)

      assert html =~ ~s(data-slot="accordion-item")
      assert html =~ ~s(data-value="q1")
      assert html =~ ~s(data-state="closed")
      assert html =~ "border-b"
    end

    test "not disabled by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion_item value="q1">Content</.accordion_item>
        """)

      refute html =~ ~s(data-disabled)
      refute html =~ "opacity-50"
    end

    test "disabled adds data attr and default disabled classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion_item value="q1" disabled>Content</.accordion_item>
        """)

      assert html =~ ~s(data-disabled="true")
      assert html =~ "opacity-50"
      assert html =~ "pointer-events-none"
    end

    test "custom disabled_class overrides default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion_item value="q1" disabled disabled_class={["opacity-25 cursor-not-allowed"]}>
          Content
        </.accordion_item>
        """)

      assert html =~ "opacity-25"
      assert html =~ "cursor-not-allowed"
      refute html =~ "opacity-50"
      refute html =~ "pointer-events-none"
    end

    test "user class merges" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion_item value="q1" class={["px-4"]}>Content</.accordion_item>
        """)

      assert html =~ "border-b"
      assert html =~ "px-4"
    end

    test "passes through global attrs" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion_item value="q1" data-testid="item-1">Content</.accordion_item>
        """)

      assert html =~ ~s(data-testid="item-1")
    end
  end

  # ── accordion_trigger/1 ─────────────────────────────────────────────

  describe "accordion_trigger/1" do
    test "renders h3 > button structure with default classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion_trigger>Click me</.accordion_trigger>
        """)

      assert html =~ "<h3"
      assert html =~ "<button"
      assert html =~ ~s(type="button")
      assert html =~ ~s(data-slot="accordion-trigger")
      assert html =~ ~s(data-state="closed")
      assert html =~ "Click me"
      assert html =~ "group/trigger"
      assert html =~ "hover:underline"
    end

    test "renders default chevron SVG" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion_trigger>Text</.accordion_trigger>
        """)

      assert html =~ "<svg"
      assert html =~ ~s(m6 9 6 6 6-6)
      assert html =~ "group-data-[state=open]/trigger:rotate-180"
    end

    test "hide_icon suppresses all icons" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion_trigger hide_icon>Text</.accordion_trigger>
        """)

      refute html =~ "<svg"
      assert html =~ "Text"
    end

    test "custom icon slot replaces default chevron" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion_trigger>
          Text
          <:icon><span class="custom-icon">+</span></:icon>
        </.accordion_trigger>
        """)

      assert html =~ "custom-icon"
      assert html =~ "+"
      refute html =~ ~s(m6 9 6 6 6-6)
    end

    test "hide_icon takes precedence over icon slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion_trigger hide_icon>
          Text
          <:icon><span>ICON</span></:icon>
        </.accordion_trigger>
        """)

      refute html =~ "ICON"
      refute html =~ "<svg"
    end

    test "user class merges" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion_trigger class={["text-lg"]}>Text</.accordion_trigger>
        """)

      assert html =~ "text-lg"
      refute html =~ "text-sm"
    end

    test "passes through global attrs to button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion_trigger data-testid="trig-1">Text</.accordion_trigger>
        """)

      assert html =~ ~s(data-testid="trig-1")
    end
  end

  # ── accordion_content/1 ─────────────────────────────────────────────

  describe "accordion_content/1" do
    test "renders outer wrapper with animation classes and inner content div" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion_content>Answer here</.accordion_content>
        """)

      assert html =~ ~s(data-slot="accordion-content")
      assert html =~ ~s(data-state="closed")
      assert html =~ ~s(style="display:none")
      assert html =~ "overflow-hidden"
      assert html =~ "animate-accordion-down"
      assert html =~ "animate-accordion-up"
      assert html =~ "Answer here"
    end

    test "inner div has default padding" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion_content>Text</.accordion_content>
        """)

      assert html =~ "pb-4"
    end

    test "user class applies to inner div and merges" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion_content class={["px-6"]}>Text</.accordion_content>
        """)

      assert html =~ "px-6"
      assert html =~ "pb-4"
    end

    test "passes through global attrs to inner div" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion_content data-testid="content-1">Text</.accordion_content>
        """)

      assert html =~ ~s(data-testid="content-1")
    end
  end

  # ── JS struct support ─────────────────────────────────────────────

  describe "JS struct support" do
    test "on_value_change accepts JS struct and renders it" do
      assigns = %{js: Phoenix.LiveView.JS.push("my-event", value: %{source: "accordion"})}

      html =
        rendered_to_string(~H"""
        <.accordion id="acc" on_value_change={@js}>
          <.accordion_item value="a"><.accordion_trigger>T</.accordion_trigger></.accordion_item>
        </.accordion>
        """)

      assert html =~ ~s(data-on-value-change="[[)
      assert html =~ ~s(data-state-mode="hybrid")
    end
  end

  # ── Full composition ────────────────────────────────────────────────

  describe "composition" do
    test "full accordion renders all sub-components" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion id="faq" type="single" collapsible>
          <.accordion_item value="q1">
            <.accordion_trigger>Question?</.accordion_trigger>
            <.accordion_content>Answer.</.accordion_content>
          </.accordion_item>
          <.accordion_item value="q2">
            <.accordion_trigger>Another?</.accordion_trigger>
            <.accordion_content>Yes.</.accordion_content>
          </.accordion_item>
        </.accordion>
        """)

      assert html =~ ~s(data-slot="accordion")
      assert html =~ ~s(data-slot="accordion-item")
      assert html =~ ~s(data-slot="accordion-trigger")
      assert html =~ ~s(data-slot="accordion-content")
      assert html =~ ~s(data-value="q1")
      assert html =~ ~s(data-value="q2")
      assert html =~ "Question?"
      assert html =~ "Answer."
      assert html =~ "Another?"
      assert html =~ "Yes."
    end

    test "mixed disabled and enabled items" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion id="mix" type="single" collapsible>
          <.accordion_item value="a">
            <.accordion_trigger>Enabled</.accordion_trigger>
            <.accordion_content>Open me</.accordion_content>
          </.accordion_item>
          <.accordion_item value="b" disabled>
            <.accordion_trigger>Disabled</.accordion_trigger>
            <.accordion_content>Locked</.accordion_content>
          </.accordion_item>
        </.accordion>
        """)

      assert html =~ "Enabled"
      assert html =~ "Disabled"
      assert html =~ ~s(data-disabled="true")
    end

    test "server mode with list value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.accordion id="srv" type="multiple" value={["a", "c"]} on_value_change="changed">
          <.accordion_item value="a">
            <.accordion_trigger>A</.accordion_trigger>
            <.accordion_content>Content A</.accordion_content>
          </.accordion_item>
          <.accordion_item value="b">
            <.accordion_trigger>B</.accordion_trigger>
            <.accordion_content>Content B</.accordion_content>
          </.accordion_item>
          <.accordion_item value="c">
            <.accordion_trigger>C</.accordion_trigger>
            <.accordion_content>Content C</.accordion_content>
          </.accordion_item>
        </.accordion>
        """)

      assert html =~ ~s(data-state-mode="server")
      assert html =~ ~s(data-type="multiple")
      assert html =~ ~s(data-value="a,c")
      assert html =~ ~s(data-on-value-change="changed")
    end
  end
end
