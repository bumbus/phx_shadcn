defmodule PhxShadcn.Components.ToggleGroupTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  use Phoenix.Component
  import PhxShadcn.Components.ToggleGroup

  # ── toggle_group/1 (root) ──────────────────────────────────────────

  describe "toggle_group/1" do
    test "renders with required attrs and defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group id="tg1">
          <.toggle_group_item value="a">A</.toggle_group_item>
        </.toggle_group>
        """)

      assert html =~ ~s(id="tg1")
      assert html =~ ~s(data-slot="toggle-group")
      assert html =~ ~s(role="group")
      assert html =~ ~s(phx-hook="ToggleGroup")
      assert html =~ ~s(data-type="single")
    end

    test "renders type=multiple" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group id="tg1" type="multiple">
          <.toggle_group_item value="a">A</.toggle_group_item>
        </.toggle_group>
        """)

      assert html =~ ~s(data-type="multiple")
    end

    test "variant and size data attrs on group" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group id="tg1" variant="outline" size="sm">
          <.toggle_group_item value="a" variant="outline" size="sm">A</.toggle_group_item>
        </.toggle_group>
        """)

      [group_tag] = Regex.run(~r/<div id="tg1"[^>]*>/, html)
      assert group_tag =~ ~s(data-variant="outline")
      assert group_tag =~ ~s(data-size="sm")
    end

    test "spacing=0 by default renders gap-0" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group id="tg1">
          <.toggle_group_item value="a">A</.toggle_group_item>
        </.toggle_group>
        """)

      assert html =~ "gap-0"
      assert html =~ ~s(data-spacing="0")
    end

    test "spacing=1 renders gap-1" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group id="tg1" spacing={1}>
          <.toggle_group_item value="a">A</.toggle_group_item>
        </.toggle_group>
        """)

      assert html =~ "gap-1"
      assert html =~ ~s(data-spacing="1")
    end

    test "user class merges" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group id="tg1" class={["mt-4"]}>
          <.toggle_group_item value="a">A</.toggle_group_item>
        </.toggle_group>
        """)

      assert html =~ "mt-4"
      assert html =~ "flex"
    end

    test "passes through global attrs" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group id="tg1" data-testid="my-group">
          <.toggle_group_item value="a">A</.toggle_group_item>
        </.toggle_group>
        """)

      assert html =~ ~s(data-testid="my-group")
    end
  end

  # ── State mode detection ───────────────────────────────────────────

  describe "state mode detection" do
    test "client mode — no value, no on_value_change" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group id="tg1">
          <.toggle_group_item value="a">A</.toggle_group_item>
        </.toggle_group>
        """)

      assert html =~ ~s(data-state-mode="client")
    end

    test "hybrid mode — on_value_change set, no value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group id="tg1" on_value_change="changed">
          <.toggle_group_item value="a">A</.toggle_group_item>
        </.toggle_group>
        """)

      assert html =~ ~s(data-state-mode="hybrid")
      assert html =~ ~s(data-on-value-change="changed")
    end

    test "server mode — value set" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group id="tg1" value="a" on_value_change="changed">
          <.toggle_group_item value="a">A</.toggle_group_item>
        </.toggle_group>
        """)

      assert html =~ ~s(data-state-mode="server")
      assert html =~ ~s(data-value="a")
    end
  end

  # ── Value serialization ────────────────────────────────────────────

  describe "value serialization" do
    test "single string value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group id="tg1" value="bold">
          <.toggle_group_item value="bold">B</.toggle_group_item>
        </.toggle_group>
        """)

      assert html =~ ~s(data-value="bold")
    end

    test "list value serialized as comma-separated" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group id="tg1" type="multiple" value={["bold", "italic"]}>
          <.toggle_group_item value="bold">B</.toggle_group_item>
          <.toggle_group_item value="italic">I</.toggle_group_item>
        </.toggle_group>
        """)

      assert html =~ ~s(data-value="bold,italic")
    end

    test "nil value omits data-value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group id="tg1">
          <.toggle_group_item value="a">A</.toggle_group_item>
        </.toggle_group>
        """)

      [group_tag] = Regex.run(~r/<div id="tg1"[^>]*>/, html)
      refute group_tag =~ "data-value="
    end

    test "default_value string" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group id="tg1" default_value="bold">
          <.toggle_group_item value="bold">B</.toggle_group_item>
        </.toggle_group>
        """)

      assert html =~ ~s(data-default-value="bold")
    end

    test "default_value list" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group id="tg1" type="multiple" default_value={["bold", "italic"]}>
          <.toggle_group_item value="bold">B</.toggle_group_item>
          <.toggle_group_item value="italic">I</.toggle_group_item>
        </.toggle_group>
        """)

      assert html =~ ~s(data-default-value="bold,italic")
    end
  end

  # ── toggle_group_item/1 ────────────────────────────────────────────

  describe "toggle_group_item/1" do
    test "renders with required attrs" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group_item value="bold">B</.toggle_group_item>
        """)

      assert html =~ ~s(data-slot="toggle-group-item")
      assert html =~ ~s(data-value="bold")
      assert html =~ ~s(data-state="off")
      assert html =~ ~s(aria-pressed="false")
      assert html =~ ~s(type="button")
      assert html =~ "B"
    end

    test "variant and size on item" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group_item value="a" variant="outline" size="lg">A</.toggle_group_item>
        """)

      assert html =~ ~s(data-variant="outline")
      assert html =~ ~s(data-size="lg")
      assert html =~ "border"
      assert html =~ "h-10"
    end

    test "disabled item" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group_item value="a" disabled>A</.toggle_group_item>
        """)

      assert html =~ "disabled"
      assert html =~ ~s(data-disabled="true")
    end

    test "not disabled by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group_item value="a">A</.toggle_group_item>
        """)

      refute html =~ "data-disabled"
    end

    test "user class merges" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group_item value="a" class={["font-bold"]}>A</.toggle_group_item>
        """)

      assert html =~ "font-bold"
      assert html =~ "inline-flex"
    end

    test "passes through global attrs" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group_item value="a" data-testid="item-a">A</.toggle_group_item>
        """)

      assert html =~ ~s(data-testid="item-a")
    end
  end

  # ── Form integration ───────────────────────────────────────────────

  describe "form integration" do
    test "renders hidden input when name is set" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group id="tg1" name="format">
          <.toggle_group_item value="bold">B</.toggle_group_item>
        </.toggle_group>
        """)

      assert html =~ ~s(type="hidden")
      assert html =~ ~s(name="format")
    end

    test "hidden input value is empty when nothing selected" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group id="tg1" name="format">
          <.toggle_group_item value="bold">B</.toggle_group_item>
        </.toggle_group>
        """)

      assert html =~ ~s(value="")
    end

    test "hidden input has value for single default_value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group id="tg1" name="align" default_value="left">
          <.toggle_group_item value="left">L</.toggle_group_item>
          <.toggle_group_item value="center">C</.toggle_group_item>
        </.toggle_group>
        """)

      assert html =~ ~s(value="left")
    end

    test "hidden input has comma-separated value for multiple default_value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group id="tg1" name="format" type="multiple" default_value={["bold", "italic"]}>
          <.toggle_group_item value="bold">B</.toggle_group_item>
          <.toggle_group_item value="italic">I</.toggle_group_item>
        </.toggle_group>
        """)

      assert html =~ ~s(value="bold,italic")
    end

    test "server mode value in hidden input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group id="tg1" name="align" value="center" on_value_change="changed">
          <.toggle_group_item value="left">L</.toggle_group_item>
          <.toggle_group_item value="center">C</.toggle_group_item>
        </.toggle_group>
        """)

      # The hidden input should reflect the server value
      assert html =~ ~s(name="align")
      assert html =~ ~s(value="center")
    end

    test "no hidden input when name is nil" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group id="tg1">
          <.toggle_group_item value="bold">B</.toggle_group_item>
        </.toggle_group>
        """)

      refute html =~ ~s(type="hidden")
    end
  end

  # ── JS struct support ──────────────────────────────────────────────

  describe "JS struct support" do
    test "on_value_change accepts JS struct" do
      assigns = %{js: Phoenix.LiveView.JS.push("my-event", value: %{source: "toggle-group"})}

      html =
        rendered_to_string(~H"""
        <.toggle_group id="tg1" on_value_change={@js}>
          <.toggle_group_item value="a">A</.toggle_group_item>
        </.toggle_group>
        """)

      assert html =~ ~s(data-on-value-change="[[)
      assert html =~ ~s(data-state-mode="hybrid")
    end
  end

  # ── Composition ────────────────────────────────────────────────────

  describe "composition" do
    test "full toggle group renders all items" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group id="fmt" type="multiple">
          <.toggle_group_item value="bold">B</.toggle_group_item>
          <.toggle_group_item value="italic">I</.toggle_group_item>
          <.toggle_group_item value="underline">U</.toggle_group_item>
        </.toggle_group>
        """)

      assert html =~ ~s(data-slot="toggle-group")
      assert html =~ ~s(data-value="bold")
      assert html =~ ~s(data-value="italic")
      assert html =~ ~s(data-value="underline")
      assert html =~ "B"
      assert html =~ "I"
      assert html =~ "U"
    end

    test "outline variant with spacing=0 includes border-collapsing classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group id="tg1" variant="outline">
          <.toggle_group_item value="a" variant="outline">A</.toggle_group_item>
          <.toggle_group_item value="b" variant="outline">B</.toggle_group_item>
        </.toggle_group>
        """)

      assert html =~ "group-data-[spacing=0]/toggle-group"
    end
  end
end
