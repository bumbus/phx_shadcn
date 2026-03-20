defmodule PhxShadcn.Components.CardTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  use Phoenix.Component
  import PhxShadcn.Components.Card

  describe "card/1" do
    test "renders card with default classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.card>Content</.card>
        """)

      assert html =~ ~s(data-slot="card")
      assert html =~ "bg-card"
      assert html =~ "rounded-xl"
      assert html =~ "shadow-sm"
    end

    test "user class overrides via cn()" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.card class={["rounded-none"]}>Content</.card>
        """)

      assert html =~ "rounded-none"
      refute html =~ "rounded-xl"
    end
  end

  describe "card_header/1" do
    test "renders card header" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.card_header>Header</.card_header>
        """)

      assert html =~ ~s(data-slot="card-header")
      assert html =~ "px-6"
      assert html =~ "grid"
    end
  end

  describe "card_title/1" do
    test "renders card title" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.card_title>My Title</.card_title>
        """)

      assert html =~ ~s(data-slot="card-title")
      assert html =~ "font-semibold"
      assert html =~ "My Title"
    end
  end

  describe "card_description/1" do
    test "renders card description" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.card_description>Some description</.card_description>
        """)

      assert html =~ ~s(data-slot="card-description")
      assert html =~ "text-muted-foreground"
      assert html =~ "text-sm"
    end
  end

  describe "card_action/1" do
    test "renders card action" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.card_action>Action</.card_action>
        """)

      assert html =~ ~s(data-slot="card-action")
      assert html =~ "col-start-2"
    end
  end

  describe "card_content/1" do
    test "renders card content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.card_content>Body</.card_content>
        """)

      assert html =~ ~s(data-slot="card-content")
      assert html =~ "px-6"
    end
  end

  describe "card_footer/1" do
    test "renders card footer" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.card_footer>Footer</.card_footer>
        """)

      assert html =~ ~s(data-slot="card-footer")
      assert html =~ "flex"
      assert html =~ "items-center"
    end
  end

  describe "composition" do
    test "full card with all sub-components" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.card>
          <.card_header>
            <.card_title>Title</.card_title>
            <.card_description>Description</.card_description>
          </.card_header>
          <.card_content>Body content</.card_content>
          <.card_footer>Footer content</.card_footer>
        </.card>
        """)

      assert html =~ "Title"
      assert html =~ "Description"
      assert html =~ "Body content"
      assert html =~ "Footer content"
      assert html =~ ~s(data-slot="card")
      assert html =~ ~s(data-slot="card-header")
      assert html =~ ~s(data-slot="card-content")
      assert html =~ ~s(data-slot="card-footer")
    end

    test "card with header action" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.card>
          <.card_header>
            <.card_title>Title</.card_title>
            <.card_action>Edit</.card_action>
          </.card_header>
        </.card>
        """)

      assert html =~ ~s(data-slot="card-action")
      assert html =~ "Edit"
    end

    test "all sub-components pass through global attrs" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.card id="c"><.card_content id="cc">X</.card_content></.card>
        """)

      assert html =~ ~s(id="c")
      assert html =~ ~s(id="cc")
    end
  end
end
