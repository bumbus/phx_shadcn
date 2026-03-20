defmodule PhxShadcn.Components.SheetTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  use Phoenix.Component
  import PhxShadcn.Components.Sheet

  # ── sheet/1 (root) ────────────────────────────────────────────────

  describe "sheet/1" do
    test "renders native <dialog> with data-slot and phx-hook" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="sht">
          <p>Content</p>
        </.sheet>
        """)

      assert html =~ "<dialog"
      assert html =~ ~s(id="sht")
      assert html =~ ~s(data-slot="sheet")
      assert html =~ ~s(phx-hook="Dialog")
      assert html =~ "Content"
    end

    test "default side is :right with correct positioning classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="sht">
          <p>Content</p>
        </.sheet>
        """)

      assert html =~ "inset-y-0"
      assert html =~ "right-0"
      assert html =~ "border-l"
      assert html =~ "translate-x-full"
      assert html =~ "data-[state=open]:translate-x-0"
    end

    test "side :left has correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="sht" side={:left}>
          <p>Content</p>
        </.sheet>
        """)

      assert html =~ "inset-y-0"
      assert html =~ "left-0"
      assert html =~ "border-r"
      assert html =~ "-translate-x-full"
      assert html =~ "data-[state=open]:translate-x-0"
    end

    test "side :top has correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="sht" side={:top}>
          <p>Content</p>
        </.sheet>
        """)

      assert html =~ "inset-x-0"
      assert html =~ "top-0"
      assert html =~ "border-b"
      assert html =~ "rounded-b-lg"
      assert html =~ "-translate-y-full"
      assert html =~ "data-[state=open]:translate-y-0"
    end

    test "side :bottom has correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="sht" side={:bottom}>
          <p>Content</p>
        </.sheet>
        """)

      assert html =~ "inset-x-0"
      assert html =~ "bottom-0"
      assert html =~ "border-t"
      assert html =~ "rounded-t-lg"
      assert html =~ "translate-y-full"
      assert html =~ "data-[state=open]:translate-y-0"
    end

    test "content div has correct data-slot and ARIA" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="sht">
          <p>Content</p>
        </.sheet>
        """)

      assert html =~ ~s(data-slot="sheet-content")
      assert html =~ ~s(aria-labelledby="sht-title")
      assert html =~ ~s(aria-describedby="sht-description")
    end

    test "no place-items-center on overlay" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="sht">
          <p>Content</p>
        </.sheet>
        """)

      refute html =~ "place-items-center"
      assert html =~ "open:block"
    end

    test "overlay has bg-black/50 and correct base classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="sht">
          <p>Content</p>
        </.sheet>
        """)

      assert html =~ "bg-black/50"
      assert html =~ "fixed"
      assert html =~ "inset-0"
      assert html =~ "h-dvh"
      assert html =~ "w-screen"
    end

    test "close button shown by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="sht">
          <p>Content</p>
        </.sheet>
        """)

      assert html =~ ~s(aria-label="Close")
      assert html =~ ~s(<span class="sr-only">Close</span>)
    end

    test "close button hidden when show_close is false" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="sht" show_close={false}>
          <p>Content</p>
        </.sheet>
        """)

      refute html =~ ~s(aria-label="Close")
    end

    test "handle hidden by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="sht" side={:bottom}>
          <p>Content</p>
        </.sheet>
        """)

      refute html =~ ~s(data-slot="sheet-handle")
    end

    test "handle shown for bottom when handle={true}" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="sht" side={:bottom} handle>
          <p>Content</p>
        </.sheet>
        """)

      assert html =~ ~s(data-slot="sheet-handle")
      assert html =~ "rounded-full"
      assert html =~ "bg-muted"
      assert html =~ "w-[100px]"
      assert html =~ "mt-4"
    end

    test "handle shown for top when handle={true}" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="sht" side={:top} handle>
          <p>Content</p>
        </.sheet>
        """)

      assert html =~ ~s(data-slot="sheet-handle")
      assert html =~ "mb-4"
    end

    test "handle not shown for left/right even when handle={true}" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="sht" side={:right} handle>
          <p>Content</p>
        </.sheet>
        """)

      refute html =~ ~s(data-slot="sheet-handle")
    end

    test "handle_class merges with handle defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="sht" side={:bottom} handle handle_class="bg-primary">
          <p>Content</p>
        </.sheet>
        """)

      assert html =~ "bg-primary"
      assert html =~ "rounded-full"
    end

    test "class merges with content defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="sht" class="w-full sm:max-w-lg">
          <p>Content</p>
        </.sheet>
        """)

      assert html =~ "w-full sm:max-w-lg"
      assert html =~ "bg-background"
    end

    test "overlay_class merges with dialog defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="sht" overlay_class="bg-red-500/50">
          <p>Content</p>
        </.sheet>
        """)

      assert html =~ "bg-red-500/50"
    end

    test "close_class merges with close button defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="sht" close_class="text-red-500">
          <p>Content</p>
        </.sheet>
        """)

      assert html =~ "text-red-500"
      assert html =~ "absolute top-4 right-4"
    end

    test "animation_duration defaults to 300" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="sht">
          <p>Content</p>
        </.sheet>
        """)

      # Default: no inline style override
      refute html =~ "--dialog-duration: 300ms"
      assert html =~ ~s(data-animation-duration="300")
      # Duration in class references 300ms default
      assert html =~ "duration-[var(--dialog-duration,300ms)]"
    end

    test "custom animation_duration sets CSS property and data attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="sht" animation_duration={500}>
          <p>Content</p>
        </.sheet>
        """)

      assert html =~ "--dialog-duration: 500ms"
      assert html =~ ~s(data-animation-duration="500")
    end

    test "has phx-mounted with ignore_attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="sht">
          <p>Content</p>
        </.sheet>
        """)

      assert html =~ "phx-mounted"
    end

    test "data-auto-open attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="sht">
          <p>Content</p>
        </.sheet>
        """)

      assert html =~ ~s(data-auto-open="false")

      html_show =
        rendered_to_string(~H"""
        <.sheet id="sht" show>
          <p>Content</p>
        </.sheet>
        """)

      assert html_show =~ ~s(data-auto-open="true")
    end

    test "on_cancel stored as data-on-cancel" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="sht" on_cancel={Phoenix.LiveView.JS.push("close")}>
          <p>Content</p>
        </.sheet>
        """)

      assert html =~ "data-on-cancel"
    end

    test "passes through global attrs" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="sht" data-testid="my-sheet">
          <p>Content</p>
        </.sheet>
        """)

      assert html =~ ~s(data-testid="my-sheet")
    end
  end

  # ── sheet_header/1 ────────────────────────────────────────────────

  describe "sheet_header/1" do
    test "renders with data-slot and correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet_header>Header</.sheet_header>
        """)

      assert html =~ ~s(data-slot="sheet-header")
      assert html =~ "flex flex-col gap-1.5"
      assert html =~ "p-4"
      assert html =~ "Header"
    end

    test "user class merges" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet_header class="p-6">Header</.sheet_header>
        """)

      assert html =~ "p-6"
      assert html =~ "flex flex-col"
    end
  end

  # ── sheet_footer/1 ────────────────────────────────────────────────

  describe "sheet_footer/1" do
    test "renders with data-slot and correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet_footer>Footer</.sheet_footer>
        """)

      assert html =~ ~s(data-slot="sheet-footer")
      assert html =~ "mt-auto"
      assert html =~ "flex flex-col gap-2"
      assert html =~ "p-4"
      assert html =~ "Footer"
    end

    test "user class merges" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet_footer class="gap-4">Footer</.sheet_footer>
        """)

      assert html =~ "gap-4"
    end
  end

  # ── sheet_title/1 ─────────────────────────────────────────────────

  describe "sheet_title/1" do
    test "renders with data-slot and correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet_title>My Title</.sheet_title>
        """)

      assert html =~ ~s(data-slot="sheet-title")
      assert html =~ "text-foreground"
      assert html =~ "font-semibold"
      assert html =~ "My Title"
    end

    test "accepts explicit id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet_title id="custom-title">Title</.sheet_title>
        """)

      assert html =~ ~s(id="custom-title")
    end

    test "user class merges" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet_title class="text-2xl">Title</.sheet_title>
        """)

      assert html =~ "text-2xl"
    end
  end

  # ── sheet_description/1 ───────────────────────────────────────────

  describe "sheet_description/1" do
    test "renders with data-slot and correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet_description>Description text</.sheet_description>
        """)

      assert html =~ ~s(data-slot="sheet-description")
      assert html =~ "text-muted-foreground"
      assert html =~ "text-sm"
      assert html =~ "Description text"
    end

    test "accepts explicit id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet_description id="custom-desc">Desc</.sheet_description>
        """)

      assert html =~ ~s(id="custom-desc")
    end
  end

  # ── sheet_close/1 ─────────────────────────────────────────────────

  describe "sheet_close/1" do
    test "renders with data-slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet_close>Cancel</.sheet_close>
        """)

      assert html =~ ~s(data-slot="sheet-close")
      assert html =~ "Cancel"
    end

    test "triggers on_cancel JS on click" do
      assigns = %{cancel: Phoenix.LiveView.JS.push("close")}

      html =
        rendered_to_string(~H"""
        <.sheet_close on_cancel={@cancel}>Cancel</.sheet_close>
        """)

      assert html =~ "phx-click"
    end
  end

  # ── JS helpers ─────────────────────────────────────────────────────

  describe "show_sheet/1" do
    test "returns a JS struct" do
      result = show_sheet("my-sheet")
      assert %Phoenix.LiveView.JS{} = result
    end

    test "is chainable" do
      result = Phoenix.LiveView.JS.push("open") |> show_sheet("my-sheet")
      assert %Phoenix.LiveView.JS{} = result
    end
  end

  describe "hide_sheet/1" do
    test "returns a JS struct" do
      result = hide_sheet("my-sheet")
      assert %Phoenix.LiveView.JS{} = result
    end

    test "is chainable" do
      result = Phoenix.LiveView.JS.push("close") |> hide_sheet("my-sheet")
      assert %Phoenix.LiveView.JS{} = result
    end
  end

  # ── Composition ────────────────────────────────────────────────────

  describe "composition" do
    test "full sheet renders all parts" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="demo">
          <.sheet_header>
            <.sheet_title id="demo-title">Title</.sheet_title>
            <.sheet_description id="demo-description">Desc</.sheet_description>
          </.sheet_header>
          <p>Body content</p>
          <.sheet_footer>
            <.sheet_close on_cancel={Phoenix.LiveView.JS.push("close")}>
              <button>Cancel</button>
            </.sheet_close>
            <button>Save</button>
          </.sheet_footer>
        </.sheet>
        """)

      assert html =~ ~s(data-slot="sheet")
      assert html =~ ~s(data-slot="sheet-content")
      assert html =~ ~s(data-slot="sheet-header")
      assert html =~ ~s(data-slot="sheet-title")
      assert html =~ ~s(data-slot="sheet-description")
      assert html =~ ~s(data-slot="sheet-footer")
      assert html =~ ~s(data-slot="sheet-close")
      assert html =~ "Title"
      assert html =~ "Desc"
      assert html =~ "Body content"
      assert html =~ "Cancel"
      assert html =~ "Save"
    end

    test "title and description inside content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="demo">
          <.sheet_header>
            <.sheet_title id="demo-title">T</.sheet_title>
            <.sheet_description id="demo-description">D</.sheet_description>
          </.sheet_header>
        </.sheet>
        """)

      # Title and description should be inside the content container
      [content_onwards] = Regex.run(~r/data-slot="sheet-content".*$/s, html)
      assert content_onwards =~ ~s(data-slot="sheet-title")
      assert content_onwards =~ ~s(data-slot="sheet-description")
    end
  end
end
