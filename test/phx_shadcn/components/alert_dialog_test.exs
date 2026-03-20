defmodule PhxShadcn.Components.AlertDialogTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  use Phoenix.Component
  import PhxShadcn.Components.AlertDialog

  # ── alert_dialog/1 (root) ─────────────────────────────────────────

  describe "alert_dialog/1" do
    test "renders native <dialog> with phx-hook and data-no-backdrop-dismiss" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="adlg">
          <p>Content</p>
        </.alert_dialog>
        """)

      assert html =~ "<dialog"
      assert html =~ ~s(id="adlg")
      assert html =~ ~s(data-slot="alert-dialog")
      assert html =~ ~s(phx-hook="Dialog")
      assert html =~ ~s(data-no-backdrop-dismiss="true")
      assert html =~ "Content"
    end

    test "has data-auto-open attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="adlg">
          <p>Content</p>
        </.alert_dialog>
        """)

      assert html =~ ~s(data-auto-open="false")

      html_show =
        rendered_to_string(~H"""
        <.alert_dialog id="adlg" show>
          <p>Content</p>
        </.alert_dialog>
        """)

      assert html_show =~ ~s(data-auto-open="true")
    end

    test "content div has role=alertdialog and ARIA attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="adlg">
          <p>Content</p>
        </.alert_dialog>
        """)

      assert html =~ ~s(data-slot="alert-dialog-content")
      assert html =~ ~s(role="alertdialog")
      assert html =~ ~s(aria-labelledby="adlg-title")
      assert html =~ ~s(aria-describedby="adlg-description")
    end

    test "close button hidden by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="adlg">
          <p>Content</p>
        </.alert_dialog>
        """)

      refute html =~ ~s(aria-label="Close")
    end

    test "close button shown when show_close is true" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="adlg" show_close={true}>
          <p>Content</p>
        </.alert_dialog>
        """)

      assert html =~ ~s(aria-label="Close")
      assert html =~ ~s(<span class="sr-only">Close</span>)
    end

    test "dialog element has overlay classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="adlg">
          <p>Content</p>
        </.alert_dialog>
        """)

      assert html =~ "bg-black/50"
      assert html =~ "fixed"
      assert html =~ "inset-0"
      assert html =~ "h-dvh"
      assert html =~ "w-screen"
      assert html =~ "open:grid"
      assert html =~ "place-items-center"
    end

    test "content panel has correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="adlg">
          <p>Content</p>
        </.alert_dialog>
        """)

      assert html =~ "bg-background"
      assert html =~ "rounded-lg"
      assert html =~ "shadow-lg"
    end

    test "class merges with content defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="adlg" class="max-w-2xl">
          <p>Content</p>
        </.alert_dialog>
        """)

      assert html =~ "max-w-2xl"
      assert html =~ "bg-background"
    end

    test "overlay_class merges with dialog defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="adlg" overlay_class="bg-red-500/50">
          <p>Content</p>
        </.alert_dialog>
        """)

      assert html =~ "bg-red-500/50"
    end

    test "close_class merges with close button defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="adlg" show_close={true} close_class="text-red-500">
          <p>Content</p>
        </.alert_dialog>
        """)

      assert html =~ "text-red-500"
      assert html =~ "absolute top-4 right-4"
    end

    test "animation_duration sets CSS custom property and data attribute" do
      assigns = %{}

      html_default =
        rendered_to_string(~H"""
        <.alert_dialog id="adlg">
          <p>Content</p>
        </.alert_dialog>
        """)

      refute html_default =~ "--dialog-duration: 200ms"
      assert html_default =~ ~s(data-animation-duration="200")

      html_custom =
        rendered_to_string(~H"""
        <.alert_dialog id="adlg" animation_duration={300}>
          <p>Content</p>
        </.alert_dialog>
        """)

      assert html_custom =~ "--dialog-duration: 300ms"
      assert html_custom =~ ~s(data-animation-duration="300")
    end

    test "on_cancel stored as data-on-cancel" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="adlg" on_cancel={Phoenix.LiveView.JS.push("cancel")}>
          <p>Content</p>
        </.alert_dialog>
        """)

      assert html =~ "data-on-cancel"
    end

    test "has phx-mounted with ignore_attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="adlg">
          <p>Content</p>
        </.alert_dialog>
        """)

      assert html =~ "phx-mounted"
    end

    test "passes through global attrs" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="adlg" data-testid="my-alert-dialog">
          <p>Content</p>
        </.alert_dialog>
        """)

      assert html =~ ~s(data-testid="my-alert-dialog")
    end
  end

  # ── alert_dialog_header/1 ──────────────────────────────────────────

  describe "alert_dialog_header/1" do
    test "renders with data-slot and correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_header>Header</.alert_dialog_header>
        """)

      assert html =~ ~s(data-slot="alert-dialog-header")
      assert html =~ "flex flex-col gap-2"
      assert html =~ "text-center"
      assert html =~ "sm:text-left"
      assert html =~ "Header"
    end

    test "user class merges" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_header class="p-4">Header</.alert_dialog_header>
        """)

      assert html =~ "p-4"
      assert html =~ "flex flex-col"
    end
  end

  # ── alert_dialog_footer/1 ──────────────────────────────────────────

  describe "alert_dialog_footer/1" do
    test "renders with data-slot and correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_footer>Footer</.alert_dialog_footer>
        """)

      assert html =~ ~s(data-slot="alert-dialog-footer")
      assert html =~ "flex flex-col-reverse"
      assert html =~ "sm:flex-row"
      assert html =~ "sm:justify-end"
      assert html =~ "Footer"
    end

    test "user class merges" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_footer class="gap-4">Footer</.alert_dialog_footer>
        """)

      assert html =~ "gap-4"
    end
  end

  # ── alert_dialog_title/1 ───────────────────────────────────────────

  describe "alert_dialog_title/1" do
    test "renders with data-slot and correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_title>My Title</.alert_dialog_title>
        """)

      assert html =~ ~s(data-slot="alert-dialog-title")
      assert html =~ "text-lg"
      assert html =~ "font-semibold"
      assert html =~ "My Title"
    end

    test "accepts explicit id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_title id="custom-title">Title</.alert_dialog_title>
        """)

      assert html =~ ~s(id="custom-title")
    end

    test "user class merges" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_title class="text-2xl">Title</.alert_dialog_title>
        """)

      assert html =~ "text-2xl"
    end
  end

  # ── alert_dialog_description/1 ─────────────────────────────────────

  describe "alert_dialog_description/1" do
    test "renders with data-slot and correct classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_description>Description text</.alert_dialog_description>
        """)

      assert html =~ ~s(data-slot="alert-dialog-description")
      assert html =~ "text-muted-foreground"
      assert html =~ "text-sm"
      assert html =~ "Description text"
    end

    test "accepts explicit id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_description id="custom-desc">Desc</.alert_dialog_description>
        """)

      assert html =~ ~s(id="custom-desc")
    end
  end

  # ── alert_dialog_cancel/1 ──────────────────────────────────────────

  describe "alert_dialog_cancel/1" do
    test "renders with data-slot and contents class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_cancel>Cancel</.alert_dialog_cancel>
        """)

      assert html =~ ~s(data-slot="alert-dialog-cancel")
      assert html =~ "contents"
      assert html =~ "Cancel"
    end

    test "triggers on_cancel JS on click" do
      assigns = %{cancel: Phoenix.LiveView.JS.push("cancel")}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_cancel on_cancel={@cancel}>Cancel</.alert_dialog_cancel>
        """)

      assert html =~ "phx-click"
    end
  end

  # ── alert_dialog_action/1 ──────────────────────────────────────────

  describe "alert_dialog_action/1" do
    test "renders with data-slot and contents class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_action>
          <button>Continue</button>
        </.alert_dialog_action>
        """)

      assert html =~ ~s(data-slot="alert-dialog-action")
      assert html =~ "contents"
      assert html =~ "Continue"
    end
  end

  # ── JS helpers ─────────────────────────────────────────────────────

  describe "show_alert_dialog/1" do
    test "returns a JS struct" do
      result = show_alert_dialog("my-alert-dialog")
      assert %Phoenix.LiveView.JS{} = result
    end

    test "is chainable" do
      result = Phoenix.LiveView.JS.push("open") |> show_alert_dialog("my-alert-dialog")
      assert %Phoenix.LiveView.JS{} = result
    end
  end

  describe "hide_alert_dialog/1" do
    test "returns a JS struct" do
      result = hide_alert_dialog("my-alert-dialog")
      assert %Phoenix.LiveView.JS{} = result
    end

    test "is chainable" do
      result = Phoenix.LiveView.JS.push("close") |> hide_alert_dialog("my-alert-dialog")
      assert %Phoenix.LiveView.JS{} = result
    end
  end

  # ── Composition ────────────────────────────────────────────────────

  describe "composition" do
    test "full alert dialog renders all parts" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="demo">
          <.alert_dialog_header>
            <.alert_dialog_title id="demo-title">Title</.alert_dialog_title>
            <.alert_dialog_description id="demo-description">Desc</.alert_dialog_description>
          </.alert_dialog_header>
          <p>Body content</p>
          <.alert_dialog_footer>
            <.alert_dialog_cancel on_cancel={Phoenix.LiveView.JS.push("cancel")}>
              <button>Cancel</button>
            </.alert_dialog_cancel>
            <.alert_dialog_action>
              <button>Continue</button>
            </.alert_dialog_action>
          </.alert_dialog_footer>
        </.alert_dialog>
        """)

      assert html =~ ~s(data-slot="alert-dialog")
      assert html =~ ~s(data-slot="alert-dialog-content")
      assert html =~ ~s(data-slot="alert-dialog-header")
      assert html =~ ~s(data-slot="alert-dialog-title")
      assert html =~ ~s(data-slot="alert-dialog-description")
      assert html =~ ~s(data-slot="alert-dialog-footer")
      assert html =~ ~s(data-slot="alert-dialog-cancel")
      assert html =~ ~s(data-slot="alert-dialog-action")
      assert html =~ ~s(role="alertdialog")
      assert html =~ ~s(data-no-backdrop-dismiss="true")
      assert html =~ "Title"
      assert html =~ "Desc"
      assert html =~ "Body content"
      assert html =~ "Cancel"
      assert html =~ "Continue"
    end

    test "title and description inside content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="demo">
          <.alert_dialog_header>
            <.alert_dialog_title id="demo-title">T</.alert_dialog_title>
            <.alert_dialog_description id="demo-description">D</.alert_dialog_description>
          </.alert_dialog_header>
        </.alert_dialog>
        """)

      [content_onwards] = Regex.run(~r/data-slot="alert-dialog-content".*$/s, html)
      assert content_onwards =~ ~s(data-slot="alert-dialog-title")
      assert content_onwards =~ ~s(data-slot="alert-dialog-description")
    end
  end
end
