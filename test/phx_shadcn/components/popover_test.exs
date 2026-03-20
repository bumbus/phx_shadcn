defmodule PhxShadcn.Components.PopoverTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  use Phoenix.Component
  import PhxShadcn.Components.Popover

  # ── popover/1 (root) ────────────────────────────────────────────────

  describe "popover/1" do
    test "renders div with data-slot, phx-hook, and trigger-type" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.popover id="pop">
          <.popover_trigger><button>Open</button></.popover_trigger>
          <.popover_content><p>Content</p></.popover_content>
        </.popover>
        """)

      assert html =~ ~s(data-slot="popover")
      assert html =~ ~s(phx-hook="Floating")
      assert html =~ ~s(data-trigger-type="click")
      assert html =~ ~s(id="pop")
    end

    test "has data-auto-open attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.popover id="pop">
          <.popover_trigger><button>Open</button></.popover_trigger>
          <.popover_content><p>Content</p></.popover_content>
        </.popover>
        """)

      assert html =~ ~s(data-auto-open="false")

      html_show =
        rendered_to_string(~H"""
        <.popover id="pop" show>
          <.popover_trigger><button>Open</button></.popover_trigger>
          <.popover_content><p>Content</p></.popover_content>
        </.popover>
        """)

      assert html_show =~ ~s(data-auto-open="true")
    end

    test "on_open_change stored as data-on-open-change" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.popover id="pop" on_open_change={Phoenix.LiveView.JS.push("close")}>
          <.popover_trigger><button>Open</button></.popover_trigger>
          <.popover_content><p>Content</p></.popover_content>
        </.popover>
        """)

      assert html =~ "data-on-open-change"
    end

    test "animation_duration sets data attribute and CSS custom property" do
      assigns = %{}

      html_default =
        rendered_to_string(~H"""
        <.popover id="pop">
          <.popover_trigger><button>Open</button></.popover_trigger>
          <.popover_content><p>Content</p></.popover_content>
        </.popover>
        """)

      # Default: no inline style override, but data attribute present
      assert html_default =~ ~s(data-animation-duration="200")
      refute html_default =~ "--popover-duration: 200ms"

      html_custom =
        rendered_to_string(~H"""
        <.popover id="pop" animation_duration={300}>
          <.popover_trigger><button>Open</button></.popover_trigger>
          <.popover_content><p>Content</p></.popover_content>
        </.popover>
        """)

      assert html_custom =~ ~s(data-animation-duration="300")
      assert html_custom =~ "--popover-duration: 300ms"
    end

    test "has relative inline-block classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.popover id="pop">
          <.popover_trigger><button>Open</button></.popover_trigger>
          <.popover_content><p>Content</p></.popover_content>
        </.popover>
        """)

      assert html =~ "relative"
      assert html =~ "inline-block"
    end

    test "class merges with defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.popover id="pop" class="my-class">
          <.popover_trigger><button>Open</button></.popover_trigger>
          <.popover_content><p>Content</p></.popover_content>
        </.popover>
        """)

      assert html =~ "my-class"
      assert html =~ "relative"
    end

    test "passes through global attrs" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.popover id="pop" data-testid="my-popover">
          <.popover_trigger><button>Open</button></.popover_trigger>
          <.popover_content><p>Content</p></.popover_content>
        </.popover>
        """)

      assert html =~ ~s(data-testid="my-popover")
    end
  end

  # ── popover_trigger/1 ──────────────────────────────────────────────

  describe "popover_trigger/1" do
    test "renders with data-slot and data-floating-trigger" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.popover_trigger><button>Click me</button></.popover_trigger>
        """)

      assert html =~ ~s(data-slot="popover-trigger")
      assert html =~ "data-floating-trigger"
      assert html =~ "inline-flex"
      assert html =~ "Click me"
    end

    test "class merges" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.popover_trigger class="gap-2"><button>Open</button></.popover_trigger>
        """)

      assert html =~ "gap-2"
      assert html =~ "inline-flex"
    end
  end

  # ── popover_content/1 ─────────────────────────────────────────────

  describe "popover_content/1" do
    test "renders with data-slot, data-floating-content, and hidden" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.popover_content><p>Content</p></.popover_content>
        """)

      assert html =~ ~s(data-slot="popover-content")
      assert html =~ "data-floating-content"
      assert html =~ "hidden"
    end

    test "has expected classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.popover_content><p>Content</p></.popover_content>
        """)

      assert html =~ "bg-popover"
      assert html =~ "text-popover-foreground"
      assert html =~ "z-50"
      assert html =~ "w-72"
      assert html =~ "rounded-md"
      assert html =~ "border"
      assert html =~ "p-4"
      assert html =~ "shadow-md"
    end

    test "has transition classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.popover_content><p>Content</p></.popover_content>
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
        <.popover_content><p>Content</p></.popover_content>
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
        <.popover_content><p>Content</p></.popover_content>
        """)

      assert html =~ ~s(data-side="bottom")
      assert html =~ ~s(data-align="center")
      assert html =~ ~s(data-side-offset="4")
    end

    test "custom side, align, side_offset" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.popover_content side="top" align="start" side_offset={8}>
          <p>Content</p>
        </.popover_content>
        """)

      assert html =~ ~s(data-side="top")
      assert html =~ ~s(data-align="start")
      assert html =~ ~s(data-side-offset="8")
    end

    test "class merges with defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.popover_content class="w-96"><p>Content</p></.popover_content>
        """)

      assert html =~ "w-96"
      assert html =~ "bg-popover"
    end
  end

  # ── popover_header/1 ───────────────────────────────────────────────

  describe "popover_header/1" do
    test "renders with data-slot and correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.popover_header>Header</.popover_header>
        """)

      assert html =~ ~s(data-slot="popover-header")
      assert html =~ "flex flex-col gap-1"
      assert html =~ "text-sm"
      assert html =~ "Header"
    end

    test "class merges" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.popover_header class="mb-4">Header</.popover_header>
        """)

      assert html =~ "mb-4"
      assert html =~ "flex flex-col"
    end
  end

  # ── popover_title/1 ────────────────────────────────────────────────

  describe "popover_title/1" do
    test "renders with data-slot and correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.popover_title>My Title</.popover_title>
        """)

      assert html =~ ~s(data-slot="popover-title")
      assert html =~ "font-medium"
      assert html =~ "My Title"
    end

    test "class merges" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.popover_title class="text-lg">Title</.popover_title>
        """)

      assert html =~ "text-lg"
    end
  end

  # ── popover_description/1 ──────────────────────────────────────────

  describe "popover_description/1" do
    test "renders with data-slot and correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.popover_description>Description text</.popover_description>
        """)

      assert html =~ ~s(data-slot="popover-description")
      assert html =~ "text-muted-foreground"
      assert html =~ "Description text"
    end

    test "renders as <p> element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.popover_description>Desc</.popover_description>
        """)

      assert html =~ "<p"
    end
  end

  # ── popover_close/1 ────────────────────────────────────────────────

  describe "popover_close/1" do
    test "renders with data-slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.popover_close>Close</.popover_close>
        """)

      assert html =~ ~s(data-slot="popover-close")
      assert html =~ "contents"
      assert html =~ "Close"
    end

    test "triggers on_open_change JS on click" do
      assigns = %{callback: Phoenix.LiveView.JS.push("close")}

      html =
        rendered_to_string(~H"""
        <.popover_close on_open_change={@callback}>Close</.popover_close>
        """)

      assert html =~ "phx-click"
    end
  end

  # ── JS helpers ─────────────────────────────────────────────────────

  describe "show_popover/1" do
    test "returns a JS struct" do
      result = show_popover("my-pop")
      assert %Phoenix.LiveView.JS{} = result
    end

    test "is chainable" do
      result = Phoenix.LiveView.JS.push("open") |> show_popover("my-pop")
      assert %Phoenix.LiveView.JS{} = result
    end
  end

  describe "hide_popover/1" do
    test "returns a JS struct" do
      result = hide_popover("my-pop")
      assert %Phoenix.LiveView.JS{} = result
    end

    test "is chainable" do
      result = Phoenix.LiveView.JS.push("close") |> hide_popover("my-pop")
      assert %Phoenix.LiveView.JS{} = result
    end
  end

  # ── Composition ────────────────────────────────────────────────────

  describe "composition" do
    test "full popover renders all parts" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.popover id="demo">
          <.popover_trigger>
            <button>Open</button>
          </.popover_trigger>
          <.popover_content>
            <.popover_header>
              <.popover_title>Title</.popover_title>
              <.popover_description>Desc</.popover_description>
            </.popover_header>
            <p>Body content</p>
            <.popover_close on_open_change={Phoenix.LiveView.JS.push("close")}>
              <button>Close</button>
            </.popover_close>
          </.popover_content>
        </.popover>
        """)

      assert html =~ ~s(data-slot="popover")
      assert html =~ ~s(data-slot="popover-trigger")
      assert html =~ ~s(data-slot="popover-content")
      assert html =~ ~s(data-slot="popover-header")
      assert html =~ ~s(data-slot="popover-title")
      assert html =~ ~s(data-slot="popover-description")
      assert html =~ ~s(data-slot="popover-close")
      assert html =~ "Title"
      assert html =~ "Desc"
      assert html =~ "Body content"
      assert html =~ "Open"
      assert html =~ "Close"
    end

    test "content is inside root wrapper" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.popover id="demo">
          <.popover_trigger><button>T</button></.popover_trigger>
          <.popover_content>
            <.popover_title>Title</.popover_title>
          </.popover_content>
        </.popover>
        """)

      [content_onwards] = Regex.run(~r/data-slot="popover".*$/s, html)
      assert content_onwards =~ ~s(data-slot="popover-content")
      assert content_onwards =~ ~s(data-slot="popover-title")
    end
  end
end
