defmodule PhxShadcn.Components.TabsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  use Phoenix.Component
  import PhxShadcn.Components.Tabs

  # ── tabs/1 (root) ────────────────────────────────────────────────

  describe "tabs/1" do
    test "renders with required attrs and defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs id="t1" default_value="a">
          <.tabs_list>
            <.tabs_trigger value="a">A</.tabs_trigger>
          </.tabs_list>
          <.tabs_content value="a">Content A</.tabs_content>
        </.tabs>
        """)

      assert html =~ ~s(id="t1")
      assert html =~ ~s(data-slot="tabs")
      assert html =~ ~s(phx-hook="Tabs")
      assert html =~ ~s(data-orientation="horizontal")
      assert html =~ ~s(data-activation-mode="automatic")
      assert html =~ ~s(data-default-value="a")
    end

    test "renders vertical orientation" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs id="t1" orientation="vertical">
          <.tabs_list>
            <.tabs_trigger value="a">A</.tabs_trigger>
          </.tabs_list>
          <.tabs_content value="a">Content A</.tabs_content>
        </.tabs>
        """)

      assert html =~ ~s(data-orientation="vertical")
      assert html =~ "flex-row"
    end

    test "horizontal orientation renders flex-col" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs id="t1">
          <.tabs_list>
            <.tabs_trigger value="a">A</.tabs_trigger>
          </.tabs_list>
          <.tabs_content value="a">Content A</.tabs_content>
        </.tabs>
        """)

      assert html =~ "flex-col"
    end

    test "client state mode when no value or on_value_change" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs id="t1">
          <.tabs_list>
            <.tabs_trigger value="a">A</.tabs_trigger>
          </.tabs_list>
        </.tabs>
        """)

      assert html =~ ~s(data-state-mode="client")
    end

    test "hybrid state mode when on_value_change set" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs id="t1" on_value_change="tab_changed">
          <.tabs_list>
            <.tabs_trigger value="a">A</.tabs_trigger>
          </.tabs_list>
        </.tabs>
        """)

      assert html =~ ~s(data-state-mode="hybrid")
      assert html =~ ~s(data-on-value-change="tab_changed")
    end

    test "server state mode when value set" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs id="t1" value="a" on_value_change="tab_changed">
          <.tabs_list>
            <.tabs_trigger value="a">A</.tabs_trigger>
          </.tabs_list>
        </.tabs>
        """)

      assert html =~ ~s(data-state-mode="server")
      assert html =~ ~s(data-value="a")
    end

    test "manual activation mode" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs id="t1" activation_mode="manual">
          <.tabs_list>
            <.tabs_trigger value="a">A</.tabs_trigger>
          </.tabs_list>
        </.tabs>
        """)

      assert html =~ ~s(data-activation-mode="manual")
    end

    test "custom class is applied" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs id="t1" class="mt-4">
          <.tabs_list>
            <.tabs_trigger value="a">A</.tabs_trigger>
          </.tabs_list>
        </.tabs>
        """)

      assert html =~ "mt-4"
    end

    test "global attrs are forwarded" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs id="t1" data-testid="my-tabs">
          <.tabs_list>
            <.tabs_trigger value="a">A</.tabs_trigger>
          </.tabs_list>
        </.tabs>
        """)

      assert html =~ ~s(data-testid="my-tabs")
    end
  end

  # ── tabs_list/1 ──────────────────────────────────────────────────

  describe "tabs_list/1" do
    test "renders with defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs_list>
          <.tabs_trigger value="a">A</.tabs_trigger>
        </.tabs_list>
        """)

      assert html =~ ~s(role="tablist")
      assert html =~ ~s(data-slot="tabs-list")
      assert html =~ ~s(data-variant="default")
      assert html =~ "bg-muted"
    end

    test "line variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs_list variant="line">
          <.tabs_trigger value="a">A</.tabs_trigger>
        </.tabs_list>
        """)

      assert html =~ ~s(data-variant="line")
      assert html =~ "bg-transparent"
      assert html =~ "rounded-none"
    end

    test "custom class applied" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs_list class="w-full">
          <.tabs_trigger value="a">A</.tabs_trigger>
        </.tabs_list>
        """)

      assert html =~ "w-full"
    end
  end

  # ── tabs_trigger/1 ───────────────────────────────────────────────

  describe "tabs_trigger/1" do
    test "renders as button by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs_trigger value="account">Account</.tabs_trigger>
        """)

      assert html =~ "<button"
      assert html =~ ~s(type="button")
      assert html =~ ~s(role="tab")
      assert html =~ ~s(data-slot="tabs-trigger")
      assert html =~ ~s(data-value="account")
      assert html =~ ~s(data-state="inactive")
      assert html =~ ~s(aria-selected="false")
      assert html =~ ~s(tabindex="-1")
      assert html =~ "Account"
    end

    test "disabled state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs_trigger value="x" disabled>X</.tabs_trigger>
        """)

      assert html =~ ~s(data-disabled="true")
      assert html =~ ~s(disabled)
    end

    test "patch mode renders as link" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs_trigger value="account" patch="/settings?tab=account">Account</.tabs_trigger>
        """)

      assert html =~ "<a"
      assert html =~ ~s(data-phx-link="patch")
      assert html =~ ~s(href="/settings?tab=account")
      assert html =~ ~s(role="tab")
      assert html =~ ~s(data-value="account")
    end

    test "navigate mode renders as link" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs_trigger value="account" navigate="/account">Account</.tabs_trigger>
        """)

      assert html =~ "<a"
      assert html =~ ~s(data-phx-link="redirect")
      assert html =~ ~s(href="/account")
      assert html =~ ~s(role="tab")
    end

    test "patch takes precedence over navigate" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs_trigger value="a" patch="/patch" navigate="/nav">A</.tabs_trigger>
        """)

      assert html =~ ~s(href="/patch")
      refute html =~ ~s(href="/nav")
    end

    test "custom class applied" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs_trigger value="a" class="custom-class">A</.tabs_trigger>
        """)

      assert html =~ "custom-class"
    end

    test "renders slot content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs_trigger value="a">
          <span>Icon</span> Tab Text
        </.tabs_trigger>
        """)

      assert html =~ "<span>Icon</span>"
      assert html =~ "Tab Text"
    end
  end

  # ── tabs_content/1 ───────────────────────────────────────────────

  describe "tabs_content/1" do
    test "renders with defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs_content value="account">
          Account settings here.
        </.tabs_content>
        """)

      assert html =~ ~s(role="tabpanel")
      assert html =~ ~s(data-slot="tabs-content")
      assert html =~ ~s(data-value="account")
      assert html =~ ~s(data-state="inactive")
      assert html =~ ~s(tabindex="0")
      assert html =~ ~s(hidden)
      assert html =~ "Account settings here."
    end

    test "custom class applied" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs_content value="a" class="p-4">Content</.tabs_content>
        """)

      assert html =~ "p-4"
    end

    test "base classes applied" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs_content value="a">Content</.tabs_content>
        """)

      assert html =~ "flex-1"
      assert html =~ "outline-none"
    end

    test "global attrs forwarded" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs_content value="a" data-testid="panel-a">Content</.tabs_content>
        """)

      assert html =~ ~s(data-testid="panel-a")
    end
  end

  # ── Integration ──────────────────────────────────────────────────

  describe "integration" do
    test "full tabs structure renders correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs id="settings" default_value="account">
          <.tabs_list>
            <.tabs_trigger value="account">Account</.tabs_trigger>
            <.tabs_trigger value="password">Password</.tabs_trigger>
            <.tabs_trigger value="notifications" disabled>Notifications</.tabs_trigger>
          </.tabs_list>
          <.tabs_content value="account">Account settings</.tabs_content>
          <.tabs_content value="password">Password settings</.tabs_content>
          <.tabs_content value="notifications">Notification settings</.tabs_content>
        </.tabs>
        """)

      # Root
      assert html =~ ~s(id="settings")
      assert html =~ ~s(data-default-value="account")

      # Triggers
      assert html =~ ~s(data-value="account")
      assert html =~ ~s(data-value="password")
      assert html =~ ~s(data-value="notifications")

      # Content panels
      assert html =~ "Account settings"
      assert html =~ "Password settings"
      assert html =~ "Notification settings"

      # Disabled trigger
      [disabled_trigger] = Regex.scan(~r/<button[^>]*data-value="notifications"[^>]*>/, html)
      assert hd(disabled_trigger) =~ ~s(data-disabled="true")
    end

    test "server mode full structure" do
      assigns = %{active_tab: "password"}

      html =
        rendered_to_string(~H"""
        <.tabs id="srv" value={@active_tab} on_value_change="tab_changed">
          <.tabs_list>
            <.tabs_trigger value="account">Account</.tabs_trigger>
            <.tabs_trigger value="password">Password</.tabs_trigger>
          </.tabs_list>
          <.tabs_content :if={@active_tab == "account"} value="account">Account</.tabs_content>
          <.tabs_content :if={@active_tab == "password"} value="password">Password</.tabs_content>
        </.tabs>
        """)

      assert html =~ ~s(data-state-mode="server")
      assert html =~ ~s(data-value="password")
      # Only active tab content panel rendered (triggers are always present)
      assert html =~ ~s(role="tabpanel")
      # Only one tabpanel in DOM (the password one)
      panels = Regex.scan(~r/role="tabpanel"/, html)
      assert length(panels) == 1
    end

    test "patch mode triggers render as links" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs id="patched" value="account">
          <.tabs_list>
            <.tabs_trigger value="account" patch="/settings?tab=account">Account</.tabs_trigger>
            <.tabs_trigger value="password" patch="/settings?tab=password">Password</.tabs_trigger>
          </.tabs_list>
          <.tabs_content value="account">Account</.tabs_content>
        </.tabs>
        """)

      # Both triggers are links
      links = Regex.scan(~r/<a [^>]*role="tab"[^>]*>/, html)
      assert length(links) == 2
    end
  end
end
