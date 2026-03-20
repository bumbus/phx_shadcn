defmodule PhxShadcn.Components.TooltipTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  use Phoenix.Component
  import PhxShadcn.Components.Tooltip

  # ── tooltip/1 (root) ────────────────────────────────────────────────

  describe "tooltip/1" do
    test "renders div with data-slot, phx-hook, and trigger-type hover" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tooltip id="tt">
          <.tooltip_trigger><button>Hover</button></.tooltip_trigger>
          <.tooltip_content>Tip</.tooltip_content>
        </.tooltip>
        """)

      assert html =~ ~s(data-slot="tooltip")
      assert html =~ ~s(phx-hook="Floating")
      assert html =~ ~s(data-trigger-type="hover")
      assert html =~ ~s(id="tt")
    end

    test "has default delays" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tooltip id="tt">
          <.tooltip_trigger><button>Hover</button></.tooltip_trigger>
          <.tooltip_content>Tip</.tooltip_content>
        </.tooltip>
        """)

      assert html =~ ~s(data-open-delay="200")
      assert html =~ ~s(data-close-delay="100")
    end

    test "custom delays" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tooltip id="tt" open_delay={500} close_delay={200}>
          <.tooltip_trigger><button>Hover</button></.tooltip_trigger>
          <.tooltip_content>Tip</.tooltip_content>
        </.tooltip>
        """)

      assert html =~ ~s(data-open-delay="500")
      assert html =~ ~s(data-close-delay="200")
    end

    test "has hardcoded animation duration" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tooltip id="tt">
          <.tooltip_trigger><button>Hover</button></.tooltip_trigger>
          <.tooltip_content>Tip</.tooltip_content>
        </.tooltip>
        """)

      assert html =~ ~s(data-animation-duration="150")
    end

    test "has relative inline-block classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tooltip id="tt">
          <.tooltip_trigger><button>Hover</button></.tooltip_trigger>
          <.tooltip_content>Tip</.tooltip_content>
        </.tooltip>
        """)

      assert html =~ "relative"
      assert html =~ "inline-block"
    end

    test "class merges with defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tooltip id="tt" class="my-class">
          <.tooltip_trigger><button>Hover</button></.tooltip_trigger>
          <.tooltip_content>Tip</.tooltip_content>
        </.tooltip>
        """)

      assert html =~ "my-class"
      assert html =~ "relative"
    end

    test "passes through global attrs" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tooltip id="tt" data-testid="my-tooltip">
          <.tooltip_trigger><button>Hover</button></.tooltip_trigger>
          <.tooltip_content>Tip</.tooltip_content>
        </.tooltip>
        """)

      assert html =~ ~s(data-testid="my-tooltip")
    end
  end

  # ── tooltip_trigger/1 ──────────────────────────────────────────────

  describe "tooltip_trigger/1" do
    test "renders with data-slot and data-floating-trigger" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tooltip_trigger><button>Hover me</button></.tooltip_trigger>
        """)

      assert html =~ ~s(data-slot="tooltip-trigger")
      assert html =~ "data-floating-trigger"
      assert html =~ "inline-flex"
      assert html =~ "Hover me"
    end

    test "class merges" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tooltip_trigger class="gap-2"><button>Hover</button></.tooltip_trigger>
        """)

      assert html =~ "gap-2"
      assert html =~ "inline-flex"
    end
  end

  # ── tooltip_content/1 ─────────────────────────────────────────────

  describe "tooltip_content/1" do
    test "renders with data-slot, data-floating-content, hidden, and role=tooltip" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tooltip_content>Tip text</.tooltip_content>
        """)

      assert html =~ ~s(data-slot="tooltip-content")
      assert html =~ "data-floating-content"
      assert html =~ "hidden"
      assert html =~ ~s(role="tooltip")
    end

    test "has expected tooltip classes (inverted, compact)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tooltip_content>Tip</.tooltip_content>
        """)

      assert html =~ "bg-primary"
      assert html =~ "text-primary-foreground"
      assert html =~ "z-50"
      assert html =~ "w-fit"
      assert html =~ "rounded-md"
      assert html =~ "px-3"
      assert html =~ "py-1.5"
      assert html =~ "text-xs"
      assert html =~ "text-balance"
    end

    test "has transition classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tooltip_content>Tip</.tooltip_content>
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
        <.tooltip_content>Tip</.tooltip_content>
        """)

      assert html =~ "data-[side=bottom]:origin-top"
      assert html =~ "data-[side=top]:origin-bottom"
      assert html =~ "data-[side=left]:origin-right"
      assert html =~ "data-[side=right]:origin-left"
    end

    test "default side is top (unlike popover's bottom)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tooltip_content>Tip</.tooltip_content>
        """)

      assert html =~ ~s(data-side="top")
      assert html =~ ~s(data-align="center")
      assert html =~ ~s(data-side-offset="10")
    end

    test "has arrow element by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tooltip_content>Tip</.tooltip_content>
        """)

      assert html =~ ~s(data-slot="tooltip-arrow")
      assert html =~ "rotate-45"
      assert html =~ "size-2.5"
      assert html =~ "rounded-[2px]"
    end

    test "arrow can be disabled" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tooltip_content arrow={false}>Tip</.tooltip_content>
        """)

      refute html =~ ~s(data-slot="tooltip-arrow")
    end

    test "custom side, align, side_offset" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tooltip_content side="bottom" align="start" side_offset={8}>
          Tip
        </.tooltip_content>
        """)

      assert html =~ ~s(data-side="bottom")
      assert html =~ ~s(data-align="start")
      assert html =~ ~s(data-side-offset="8")
    end

    test "class merges with defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tooltip_content class="max-w-xs"><p>Tip</p></.tooltip_content>
        """)

      assert html =~ "max-w-xs"
      assert html =~ "bg-primary"
    end
  end

  # ── JS helpers ─────────────────────────────────────────────────────

  describe "show_tooltip/1" do
    test "returns a JS struct" do
      result = show_tooltip("my-tt")
      assert %Phoenix.LiveView.JS{} = result
    end

    test "is chainable" do
      result = Phoenix.LiveView.JS.push("open") |> show_tooltip("my-tt")
      assert %Phoenix.LiveView.JS{} = result
    end
  end

  describe "hide_tooltip/1" do
    test "returns a JS struct" do
      result = hide_tooltip("my-tt")
      assert %Phoenix.LiveView.JS{} = result
    end

    test "is chainable" do
      result = Phoenix.LiveView.JS.push("close") |> hide_tooltip("my-tt")
      assert %Phoenix.LiveView.JS{} = result
    end
  end

  # ── Composition ────────────────────────────────────────────────────

  describe "composition" do
    test "full tooltip renders all parts" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tooltip id="demo">
          <.tooltip_trigger>
            <button>Hover me</button>
          </.tooltip_trigger>
          <.tooltip_content>
            Add to library
          </.tooltip_content>
        </.tooltip>
        """)

      assert html =~ ~s(data-slot="tooltip")
      assert html =~ ~s(data-slot="tooltip-trigger")
      assert html =~ ~s(data-slot="tooltip-content")
      assert html =~ "Hover me"
      assert html =~ "Add to library"
    end

    test "content is inside root wrapper" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tooltip id="demo">
          <.tooltip_trigger><button>T</button></.tooltip_trigger>
          <.tooltip_content>Tip</.tooltip_content>
        </.tooltip>
        """)

      [content_onwards] = Regex.run(~r/data-slot="tooltip".*$/s, html)
      assert content_onwards =~ ~s(data-slot="tooltip-content")
      assert content_onwards =~ ~s(data-slot="tooltip-trigger")
    end
  end
end
