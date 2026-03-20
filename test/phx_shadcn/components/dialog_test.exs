defmodule PhxShadcn.Components.DialogTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  use Phoenix.Component
  import PhxShadcn.Components.Dialog

  # ── dialog/1 (root) ────────────────────────────────────────────────

  describe "dialog/1" do
    test "renders native <dialog> with data-slot and phx-hook" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog id="dlg">
          <p>Content</p>
        </.dialog>
        """)

      assert html =~ "<dialog"
      assert html =~ ~s(id="dlg")
      assert html =~ ~s(data-slot="dialog")
      assert html =~ ~s(phx-hook="Dialog")
      assert html =~ "Content"
    end

    test "has data-auto-open attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog id="dlg">
          <p>Content</p>
        </.dialog>
        """)

      assert html =~ ~s(data-auto-open="false")

      html_show =
        rendered_to_string(~H"""
        <.dialog id="dlg" show>
          <p>Content</p>
        </.dialog>
        """)

      assert html_show =~ ~s(data-auto-open="true")
    end

    test "dialog element has overlay classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog id="dlg">
          <p>Content</p>
        </.dialog>
        """)

      assert html =~ "bg-black/50"
      assert html =~ "fixed"
      assert html =~ "inset-0"
      assert html =~ "h-dvh"
      assert html =~ "w-screen"
      assert html =~ "border-0"
      assert html =~ "open:grid"
      assert html =~ "place-items-center"
    end

    test "content panel has correct classes and ARIA" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog id="dlg">
          <p>Content</p>
        </.dialog>
        """)

      assert html =~ ~s(data-slot="dialog-content")
      assert html =~ ~s(aria-labelledby="dlg-title")
      assert html =~ ~s(aria-describedby="dlg-description")
      assert html =~ "bg-background"
      assert html =~ "rounded-lg"
      assert html =~ "shadow-lg"
    end

    test "no explicit role=dialog or aria-modal (implicit on <dialog>)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog id="dlg">
          <p>Content</p>
        </.dialog>
        """)

      refute html =~ ~s(role="dialog")
      refute html =~ ~s(aria-modal="true")
    end

    test "no overlay div or focus_wrap" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog id="dlg">
          <p>Content</p>
        </.dialog>
        """)

      refute html =~ ~s(data-slot="dialog-overlay")
      refute html =~ "focus-wrap"
    end

    test "close button renders by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog id="dlg">
          <p>Content</p>
        </.dialog>
        """)

      assert html =~ ~s(aria-label="Close")
      assert html =~ ~s(<span class="sr-only">Close</span>)
    end

    test "close button hidden when show_close is false" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog id="dlg" show_close={false}>
          <p>Content</p>
        </.dialog>
        """)

      refute html =~ ~s(aria-label="Close")
    end

    test "class merges with content defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog id="dlg" class="max-w-2xl">
          <p>Content</p>
        </.dialog>
        """)

      assert html =~ "max-w-2xl"
      assert html =~ "bg-background"
    end

    test "overlay_class merges with dialog defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog id="dlg" overlay_class="bg-red-500/50">
          <p>Content</p>
        </.dialog>
        """)

      assert html =~ "bg-red-500/50"
    end

    test "passes through global attrs" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog id="dlg" data-testid="my-dialog">
          <p>Content</p>
        </.dialog>
        """)

      assert html =~ ~s(data-testid="my-dialog")
    end

    test "on_cancel stored as data-on-cancel" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog id="dlg" on_cancel={Phoenix.LiveView.JS.push("close")}>
          <p>Content</p>
        </.dialog>
        """)

      assert html =~ "data-on-cancel"
    end

    test "has phx-mounted with ignore_attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog id="dlg">
          <p>Content</p>
        </.dialog>
        """)

      assert html =~ "phx-mounted"
    end

    test "animation_duration sets CSS custom property and data attribute" do
      assigns = %{}

      html_default =
        rendered_to_string(~H"""
        <.dialog id="dlg">
          <p>Content</p>
        </.dialog>
        """)

      # Default: no inline style override, but data attribute present
      refute html_default =~ "--dialog-duration: 200ms"
      assert html_default =~ ~s(data-animation-duration="200")

      html_custom =
        rendered_to_string(~H"""
        <.dialog id="dlg" animation_duration={300}>
          <p>Content</p>
        </.dialog>
        """)

      assert html_custom =~ "--dialog-duration: 300ms"
      assert html_custom =~ ~s(data-animation-duration="300")
    end

    test "close_class merges with close button defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog id="dlg" close_class="text-red-500">
          <p>Content</p>
        </.dialog>
        """)

      assert html =~ "text-red-500"
      assert html =~ "absolute top-4 right-4"
    end

    test "close slot replaces default X icon" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog id="dlg">
          <:close>Custom Icon</:close>
          <p>Content</p>
        </.dialog>
        """)

      assert html =~ "Custom Icon"
      refute html =~ "<svg"
      # sr-only Close text still present
      assert html =~ ~s(<span class="sr-only">Close</span>)
    end

    test "default X icon renders when close slot not provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog id="dlg">
          <p>Content</p>
        </.dialog>
        """)

      assert html =~ "<svg"
      assert html =~ ~s(aria-label="Close")
    end
  end

  # ── dialog_header/1 ────────────────────────────────────────────────

  describe "dialog_header/1" do
    test "renders with data-slot and correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog_header>Header</.dialog_header>
        """)

      assert html =~ ~s(data-slot="dialog-header")
      assert html =~ "flex flex-col gap-2"
      assert html =~ "text-center"
      assert html =~ "sm:text-left"
      assert html =~ "Header"
    end

    test "user class merges" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog_header class="p-4">Header</.dialog_header>
        """)

      assert html =~ "p-4"
      assert html =~ "flex flex-col"
    end
  end

  # ── dialog_footer/1 ────────────────────────────────────────────────

  describe "dialog_footer/1" do
    test "renders with data-slot and correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog_footer>Footer</.dialog_footer>
        """)

      assert html =~ ~s(data-slot="dialog-footer")
      assert html =~ "flex flex-col-reverse"
      assert html =~ "sm:flex-row"
      assert html =~ "sm:justify-end"
      assert html =~ "Footer"
    end

    test "user class merges" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog_footer class="gap-4">Footer</.dialog_footer>
        """)

      assert html =~ "gap-4"
    end
  end

  # ── dialog_title/1 ─────────────────────────────────────────────────

  describe "dialog_title/1" do
    test "renders with data-slot and correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog_title>My Title</.dialog_title>
        """)

      assert html =~ ~s(data-slot="dialog-title")
      assert html =~ "text-lg"
      assert html =~ "font-semibold"
      assert html =~ "My Title"
    end

    test "accepts explicit id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog_title id="custom-title">Title</.dialog_title>
        """)

      assert html =~ ~s(id="custom-title")
    end

    test "user class merges" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog_title class="text-2xl">Title</.dialog_title>
        """)

      assert html =~ "text-2xl"
    end
  end

  # ── dialog_description/1 ───────────────────────────────────────────

  describe "dialog_description/1" do
    test "renders with data-slot and correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog_description>Description text</.dialog_description>
        """)

      assert html =~ ~s(data-slot="dialog-description")
      assert html =~ "text-muted-foreground"
      assert html =~ "text-sm"
      assert html =~ "Description text"
    end

    test "accepts explicit id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog_description id="custom-desc">Desc</.dialog_description>
        """)

      assert html =~ ~s(id="custom-desc")
    end
  end

  # ── dialog_close/1 ─────────────────────────────────────────────────

  describe "dialog_close/1" do
    test "renders with data-slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog_close>Cancel</.dialog_close>
        """)

      assert html =~ ~s(data-slot="dialog-close")
      assert html =~ "Cancel"
    end

    test "triggers on_cancel JS on click" do
      assigns = %{cancel: Phoenix.LiveView.JS.push("close")}

      html =
        rendered_to_string(~H"""
        <.dialog_close on_cancel={@cancel}>Cancel</.dialog_close>
        """)

      assert html =~ "phx-click"
    end
  end

  # ── JS helpers ─────────────────────────────────────────────────────

  describe "show_dialog/1" do
    test "returns a JS struct" do
      result = show_dialog("my-dialog")
      assert %Phoenix.LiveView.JS{} = result
    end

    test "is chainable" do
      result = Phoenix.LiveView.JS.push("open") |> show_dialog("my-dialog")
      assert %Phoenix.LiveView.JS{} = result
    end
  end

  describe "hide_dialog/1" do
    test "returns a JS struct" do
      result = hide_dialog("my-dialog")
      assert %Phoenix.LiveView.JS{} = result
    end

    test "is chainable" do
      result = Phoenix.LiveView.JS.push("close") |> hide_dialog("my-dialog")
      assert %Phoenix.LiveView.JS{} = result
    end
  end

  # ── Composition ────────────────────────────────────────────────────

  describe "composition" do
    test "full dialog renders all parts" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog id="demo">
          <.dialog_header>
            <.dialog_title id="demo-title">Title</.dialog_title>
            <.dialog_description id="demo-description">Desc</.dialog_description>
          </.dialog_header>
          <p>Body content</p>
          <.dialog_footer>
            <.dialog_close on_cancel={Phoenix.LiveView.JS.push("close")}>
              <button>Cancel</button>
            </.dialog_close>
            <button>Confirm</button>
          </.dialog_footer>
        </.dialog>
        """)

      assert html =~ ~s(data-slot="dialog")
      assert html =~ ~s(data-slot="dialog-content")
      assert html =~ ~s(data-slot="dialog-header")
      assert html =~ ~s(data-slot="dialog-title")
      assert html =~ ~s(data-slot="dialog-description")
      assert html =~ ~s(data-slot="dialog-footer")
      assert html =~ ~s(data-slot="dialog-close")
      assert html =~ "Title"
      assert html =~ "Desc"
      assert html =~ "Body content"
      assert html =~ "Cancel"
      assert html =~ "Confirm"
    end

    test "title and description inside content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog id="demo">
          <.dialog_header>
            <.dialog_title id="demo-title">T</.dialog_title>
            <.dialog_description id="demo-description">D</.dialog_description>
          </.dialog_header>
        </.dialog>
        """)

      # Title and description should be inside the content container
      [content_onwards] = Regex.run(~r/data-slot="dialog-content".*$/s, html)
      assert content_onwards =~ ~s(data-slot="dialog-title")
      assert content_onwards =~ ~s(data-slot="dialog-description")
    end
  end
end
