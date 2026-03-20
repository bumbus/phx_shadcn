defmodule PhxShadcn.Components.BadgeTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  use Phoenix.Component
  import PhxShadcn.Components.Badge

  describe "badge/1" do
    test "renders with default variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.badge>New</.badge>
        """)

      assert html =~ "New"
      assert html =~ ~s(data-slot="badge")
      assert html =~ ~s(data-variant="default")
      assert html =~ "bg-primary"
      assert html =~ "rounded-full"
    end

    test "renders secondary variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.badge variant="secondary">Info</.badge>
        """)

      assert html =~ ~s(data-variant="secondary")
      assert html =~ "bg-secondary"
    end

    test "renders destructive variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.badge variant="destructive">Error</.badge>
        """)

      assert html =~ ~s(data-variant="destructive")
      assert html =~ "bg-destructive"
    end

    test "renders outline variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.badge variant="outline">v1.0</.badge>
        """)

      assert html =~ ~s(data-variant="outline")
      assert html =~ "border-border"
    end

    test "renders ghost variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.badge variant="ghost">Draft</.badge>
        """)

      assert html =~ ~s(data-variant="ghost")
    end

    test "renders link variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.badge variant="link">More</.badge>
        """)

      assert html =~ ~s(data-variant="link")
      assert html =~ "underline-offset-4"
    end

    test "renders as span element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.badge>Tag</.badge>
        """)

      assert html =~ "<span"
    end

    test "user class overrides defaults via cn()" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.badge class={["rounded-md"]}>Custom</.badge>
        """)

      assert html =~ "rounded-md"
      refute html =~ "rounded-full"
    end

    test "passes through global attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.badge id="my-badge" role="status">Live</.badge>
        """)

      assert html =~ ~s(id="my-badge")
      assert html =~ ~s(role="status")
    end

    test "renders as link with navigate" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.badge navigate="/tags">Tags</.badge>
        """)

      assert html =~ "<a"
      assert html =~ ~s(href="/tags")
      assert html =~ ~s(data-phx-link="redirect")
    end

    test "renders as link with href" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.badge href="https://example.com">External</.badge>
        """)

      assert html =~ "<a"
      assert html =~ ~s(href="https://example.com")
    end

    test "renders as link with patch" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.badge patch="/tags?page=2">Page 2</.badge>
        """)

      assert html =~ "<a"
      assert html =~ ~s(data-phx-link="patch")
    end
  end
end
