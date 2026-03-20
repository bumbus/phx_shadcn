defmodule PhxShadcn.Components.ButtonTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  use Phoenix.Component
  import PhxShadcn.Components.Button

  describe "button/1" do
    test "renders a button with default variant and size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button>Click me</.button>
        """)

      assert html =~ "Click me"
      assert html =~ ~s(data-slot="button")
      assert html =~ ~s(data-variant="default")
      assert html =~ ~s(data-size="default")
      assert html =~ ~s(type="button")
      assert html =~ "bg-primary"
      assert html =~ "h-9"
    end

    test "renders destructive variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button variant="destructive">Delete</.button>
        """)

      assert html =~ ~s(data-variant="destructive")
      assert html =~ "bg-destructive"
    end

    test "renders outline variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button variant="outline">Outlined</.button>
        """)

      assert html =~ ~s(data-variant="outline")
      assert html =~ "bg-background"
    end

    test "renders secondary variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button variant="secondary">Secondary</.button>
        """)

      assert html =~ ~s(data-variant="secondary")
      assert html =~ "bg-secondary"
    end

    test "renders ghost variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button variant="ghost">Ghost</.button>
        """)

      assert html =~ ~s(data-variant="ghost")
      assert html =~ "hover:bg-accent"
    end

    test "renders link variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button variant="link">Link</.button>
        """)

      assert html =~ ~s(data-variant="link")
      assert html =~ "underline-offset-4"
    end

    test "renders sm size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button size="sm">Small</.button>
        """)

      assert html =~ ~s(data-size="sm")
      assert html =~ "h-8"
    end

    test "renders lg size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button size="lg">Large</.button>
        """)

      assert html =~ ~s(data-size="lg")
      assert html =~ "h-10"
    end

    test "renders icon size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button size="icon">X</.button>
        """)

      assert html =~ ~s(data-size="icon")
      assert html =~ "size-9"
    end

    test "user class overrides defaults via cn()" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button class={["rounded-none", "p-8"]}>Custom</.button>
        """)

      assert html =~ "rounded-none"
      assert html =~ "p-8"
      # Default rounded-md should be overridden
      refute html =~ "rounded-md"
    end

    test "passes through phx-click" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button phx-click="save">Save</.button>
        """)

      assert html =~ ~s(phx-click="save")
    end

    test "supports disabled attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button disabled>Disabled</.button>
        """)

      assert html =~ "disabled"
    end

    test "supports submit type" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button type="submit">Submit</.button>
        """)

      assert html =~ ~s(type="submit")
    end

    test "includes phx-click-loading styles" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button>Loading</.button>
        """)

      assert html =~ "phx-click-loading:opacity-70"
      assert html =~ "phx-click-loading:pointer-events-none"
    end

    test "includes phx-submit-loading styles" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button>Loading</.button>
        """)

      assert html =~ "phx-submit-loading:opacity-70"
      assert html =~ "phx-submit-loading:pointer-events-none"
    end

    test "renders as link with navigate" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button navigate="/about">About</.button>
        """)

      assert html =~ "<a"
      assert html =~ ~s(href="/about")
      assert html =~ ~s(data-phx-link="redirect")
      assert html =~ "bg-primary"
      refute html =~ "<button"
    end

    test "renders as link with href" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button href="https://example.com">External</.button>
        """)

      assert html =~ "<a"
      assert html =~ ~s(href="https://example.com")
    end

    test "renders as link with patch" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button patch="/settings">Settings</.button>
        """)

      assert html =~ "<a"
      assert html =~ ~s(data-phx-link="patch")
    end
  end
end
