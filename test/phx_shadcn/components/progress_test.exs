defmodule PhxShadcn.Components.ProgressTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  use Phoenix.Component
  import PhxShadcn.Components.Progress

  # ── progress/1 (basic rendering) ─────────────────────────────────

  describe "progress/1" do
    test "renders with required attrs and defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" />
        """)

      assert html =~ ~s(id="p1")
      assert html =~ ~s(data-slot="progress")
      assert html =~ ~s(role="progressbar")
      assert html =~ ~s(phx-hook="Progress")
    end

    test "renders as <div> element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" />
        """)

      assert html =~ "<div"
    end

    test "renders indicator with data-slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" />
        """)

      assert html =~ ~s(data-slot="progress-indicator")
    end

    test "root has expected CSS classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" />
        """)

      assert html =~ "bg-primary/20"
      assert html =~ "rounded-full"
      assert html =~ "overflow-hidden"
    end

    test "indicator has expected CSS classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" value={50} />
        """)

      assert html =~ "bg-primary"
      assert html =~ "transition-all"
    end
  end

  # ── Indeterminate (no value) ─────────────────────────────────────

  describe "indeterminate" do
    test "default (no value) is indeterminate" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" />
        """)

      assert html =~ ~s(data-state="indeterminate")
    end

    test "no aria-valuenow when indeterminate" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" />
        """)

      refute html =~ "aria-valuenow"
    end

    test "indicator gets indeterminate animation class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" />
        """)

      assert html =~ "animate-progress-indeterminate"
    end

    test "indicator has translateX(-100%) when indeterminate" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" />
        """)

      assert html =~ "translateX(-100%)"
    end

    test "indicator data-state matches root" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" />
        """)

      assert Regex.scan(~r/data-state="indeterminate"/, html) |> length() == 2
    end
  end

  # ── State mode detection ─────────────────────────────────────────

  describe "state mode detection" do
    test "client mode — no value, no on_value_change" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" />
        """)

      assert html =~ ~s(data-state-mode="client")
    end

    test "client mode — default_value only" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" default_value={25} />
        """)

      assert html =~ ~s(data-state-mode="client")
    end

    test "hybrid mode — on_value_change set, no value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" on_value_change="progress:change" />
        """)

      assert html =~ ~s(data-state-mode="hybrid")
      assert html =~ ~s(data-on-value-change="progress:change")
    end

    test "server mode — value set" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" value={50} />
        """)

      assert html =~ ~s(data-state-mode="server")
    end
  end

  # ── data-state ───────────────────────────────────────────────────

  describe "data-state" do
    test "loading when 0 < value < max" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" value={50} />
        """)

      assert html =~ ~s(data-state="loading")
    end

    test "loading when value is 0" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" value={0} />
        """)

      assert html =~ ~s(data-state="loading")
    end

    test "complete when value equals max" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" value={100} />
        """)

      assert html =~ ~s(data-state="complete")
    end

    test "complete when value exceeds max" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" value={150} />
        """)

      assert html =~ ~s(data-state="complete")
    end

    test "indeterminate when value is nil" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" />
        """)

      assert html =~ ~s(data-state="indeterminate")
    end

    test "indicator data-state syncs with root" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" value={100} />
        """)

      assert Regex.scan(~r/data-state="complete"/, html) |> length() == 2
    end
  end

  # ── Aria attributes ──────────────────────────────────────────────

  describe "aria attributes" do
    test "aria-valuemin is always 0" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" />
        """)

      assert html =~ ~s(aria-valuemin="0")
    end

    test "aria-valuemax defaults to 100" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" />
        """)

      assert html =~ ~s(aria-valuemax="100")
    end

    test "aria-valuemax matches custom max" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" max={200} />
        """)

      assert html =~ ~s(aria-valuemax="200")
    end

    test "aria-valuenow set when value is provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" value={42} />
        """)

      assert html =~ ~s(aria-valuenow="42")
    end

    test "aria-valuenow not set when indeterminate" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" />
        """)

      refute html =~ "aria-valuenow"
    end
  end

  # ── Indicator transform style ────────────────────────────────────

  describe "indicator transform" do
    test "0% value → translateX(-100%)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" value={0} />
        """)

      assert html =~ "translateX(-100%)"
    end

    test "50% value → translateX(-50%)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" value={50} />
        """)

      assert html =~ "translateX(-50"
    end

    test "100% value → translateX(0%)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" value={100} />
        """)

      assert html =~ "translateX(-0"
    end

    test "custom max — 25 of 50 → translateX(-50%)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" value={25} max={50} />
        """)

      assert html =~ "translateX(-50"
    end
  end

  # ── Custom max ───────────────────────────────────────────────────

  describe "custom max" do
    test "data-max attr" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" max={200} />
        """)

      assert html =~ ~s(data-max="200")
    end

    test "complete at custom max" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" value={200} max={200} />
        """)

      assert html =~ ~s(data-state="complete")
    end
  end

  # ── default_value ────────────────────────────────────────────────

  describe "default_value" do
    test "renders as data attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" default_value={25} />
        """)

      assert html =~ ~s(data-default-value="25")
    end
  end

  # ── Class override ───────────────────────────────────────────────

  describe "class override" do
    test "user class merges with root classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" class={["mt-4"]} />
        """)

      assert html =~ "mt-4"
      assert html =~ "bg-primary/20"
    end

    test "indicator_class merges with indicator classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" value={50} indicator_class={["bg-green-500"]} />
        """)

      assert html =~ "bg-green-500"
    end
  end

  # ── Global attrs ─────────────────────────────────────────────────

  describe "global attrs" do
    test "passes through global attrs" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" data-testid="my-progress" />
        """)

      assert html =~ ~s(data-testid="my-progress")
    end

    test "aria-label passthrough" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" aria-label="Upload progress" />
        """)

      assert html =~ ~s(aria-label="Upload progress")
    end
  end

  # ── JS struct support ────────────────────────────────────────────

  describe "JS struct support" do
    test "on_value_change accepts JS struct" do
      assigns = %{js: Phoenix.LiveView.JS.push("my-event", value: %{source: "progress"})}

      html =
        rendered_to_string(~H"""
        <.progress id="p1" on_value_change={@js} />
        """)

      assert html =~ ~s(data-on-value-change="[[)
      assert html =~ ~s(data-state-mode="hybrid")
    end
  end
end
