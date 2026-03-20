defmodule PhxShadcn.Components.HoverCardTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  use Phoenix.Component
  import PhxShadcn.Components.HoverCard

  # ── hover_card/1 (root) ────────────────────────────────────────────

  describe "hover_card/1" do
    test "renders div with data-slot, phx-hook, and trigger-type hover" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.hover_card id="hc">
          <.hover_card_trigger><a href="#">@user</a></.hover_card_trigger>
          <.hover_card_content>Profile</.hover_card_content>
        </.hover_card>
        """)

      assert html =~ ~s(data-slot="hover-card")
      assert html =~ ~s(phx-hook="Floating")
      assert html =~ ~s(data-trigger-type="hover")
      assert html =~ ~s(id="hc")
    end

    test "has default delays" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.hover_card id="hc">
          <.hover_card_trigger><a href="#">@user</a></.hover_card_trigger>
          <.hover_card_content>Profile</.hover_card_content>
        </.hover_card>
        """)

      assert html =~ ~s(data-open-delay="500")
      assert html =~ ~s(data-close-delay="300")
    end

    test "custom delays" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.hover_card id="hc" open_delay={50} close_delay={100}>
          <.hover_card_trigger><a href="#">@user</a></.hover_card_trigger>
          <.hover_card_content>Profile</.hover_card_content>
        </.hover_card>
        """)

      assert html =~ ~s(data-open-delay="50")
      assert html =~ ~s(data-close-delay="100")
    end

    test "has hardcoded animation duration" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.hover_card id="hc">
          <.hover_card_trigger><a href="#">@user</a></.hover_card_trigger>
          <.hover_card_content>Profile</.hover_card_content>
        </.hover_card>
        """)

      assert html =~ ~s(data-animation-duration="150")
    end

    test "has relative inline-block classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.hover_card id="hc">
          <.hover_card_trigger><a href="#">@user</a></.hover_card_trigger>
          <.hover_card_content>Profile</.hover_card_content>
        </.hover_card>
        """)

      assert html =~ "relative"
      assert html =~ "inline-block"
    end

    test "class merges with defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.hover_card id="hc" class="my-class">
          <.hover_card_trigger><a href="#">@user</a></.hover_card_trigger>
          <.hover_card_content>Profile</.hover_card_content>
        </.hover_card>
        """)

      assert html =~ "my-class"
      assert html =~ "relative"
    end

    test "passes through global attrs" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.hover_card id="hc" data-testid="my-hc">
          <.hover_card_trigger><a href="#">@user</a></.hover_card_trigger>
          <.hover_card_content>Profile</.hover_card_content>
        </.hover_card>
        """)

      assert html =~ ~s(data-testid="my-hc")
    end
  end

  # ── hover_card_trigger/1 ──────────────────────────────────────────

  describe "hover_card_trigger/1" do
    test "renders with data-slot and data-floating-trigger" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.hover_card_trigger><a href="#">@user</a></.hover_card_trigger>
        """)

      assert html =~ ~s(data-slot="hover-card-trigger")
      assert html =~ "data-floating-trigger"
      assert html =~ "inline-flex"
      assert html =~ "@user"
    end

    test "class merges" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.hover_card_trigger class="gap-2"><a href="#">@user</a></.hover_card_trigger>
        """)

      assert html =~ "gap-2"
      assert html =~ "inline-flex"
    end
  end

  # ── hover_card_content/1 ─────────────────────────────────────────

  describe "hover_card_content/1" do
    test "renders with data-slot, data-floating-content, and hidden" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.hover_card_content>Profile info</.hover_card_content>
        """)

      assert html =~ ~s(data-slot="hover-card-content")
      assert html =~ "data-floating-content"
      assert html =~ "hidden"
    end

    test "has expected popover-like classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.hover_card_content>Profile</.hover_card_content>
        """)

      assert html =~ "bg-popover"
      assert html =~ "text-popover-foreground"
      assert html =~ "z-50"
      assert html =~ "w-64"
      assert html =~ "rounded-md"
      assert html =~ "border"
      assert html =~ "p-4"
      assert html =~ "shadow-md"
    end

    test "has transition classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.hover_card_content>Profile</.hover_card_content>
        """)

      assert html =~ "opacity-0"
      assert html =~ "scale-95"
      assert html =~ "data-[state=open]:opacity-100"
      assert html =~ "data-[state=open]:scale-100"
      assert html =~ "data-[state=closing]:ease-in"
    end

    test "has directional transform-origin classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.hover_card_content>Profile</.hover_card_content>
        """)

      assert html =~ "data-[side=bottom]:origin-top"
      assert html =~ "data-[side=top]:origin-bottom"
      assert html =~ "data-[side=left]:origin-right"
      assert html =~ "data-[side=right]:origin-left"
    end

    test "default side, align, side_offset" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.hover_card_content>Profile</.hover_card_content>
        """)

      assert html =~ ~s(data-side="bottom")
      assert html =~ ~s(data-align="center")
      assert html =~ ~s(data-side-offset="4")
    end

    test "custom side, align, side_offset" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.hover_card_content side="top" align="start" side_offset={8}>
          Profile
        </.hover_card_content>
        """)

      assert html =~ ~s(data-side="top")
      assert html =~ ~s(data-align="start")
      assert html =~ ~s(data-side-offset="8")
    end

    test "class merges with defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.hover_card_content class="w-80"><p>Profile</p></.hover_card_content>
        """)

      assert html =~ "w-80"
      assert html =~ "bg-popover"
    end
  end

  # ── JS helpers ─────────────────────────────────────────────────────

  describe "show_hover_card/1" do
    test "returns a JS struct" do
      result = show_hover_card("my-hc")
      assert %Phoenix.LiveView.JS{} = result
    end

    test "is chainable" do
      result = Phoenix.LiveView.JS.push("open") |> show_hover_card("my-hc")
      assert %Phoenix.LiveView.JS{} = result
    end
  end

  describe "hide_hover_card/1" do
    test "returns a JS struct" do
      result = hide_hover_card("my-hc")
      assert %Phoenix.LiveView.JS{} = result
    end

    test "is chainable" do
      result = Phoenix.LiveView.JS.push("close") |> hide_hover_card("my-hc")
      assert %Phoenix.LiveView.JS{} = result
    end
  end

  # ── Composition ────────────────────────────────────────────────────

  describe "composition" do
    test "full hover card renders all parts" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.hover_card id="demo">
          <.hover_card_trigger>
            <a href="#">@username</a>
          </.hover_card_trigger>
          <.hover_card_content>
            <p>User profile content</p>
          </.hover_card_content>
        </.hover_card>
        """)

      assert html =~ ~s(data-slot="hover-card")
      assert html =~ ~s(data-slot="hover-card-trigger")
      assert html =~ ~s(data-slot="hover-card-content")
      assert html =~ "@username"
      assert html =~ "User profile content"
    end

    test "content is inside root wrapper" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.hover_card id="demo">
          <.hover_card_trigger><a href="#">T</a></.hover_card_trigger>
          <.hover_card_content>Profile</.hover_card_content>
        </.hover_card>
        """)

      [content_onwards] = Regex.run(~r/data-slot="hover-card".*$/s, html)
      assert content_onwards =~ ~s(data-slot="hover-card-content")
      assert content_onwards =~ ~s(data-slot="hover-card-trigger")
    end
  end
end
