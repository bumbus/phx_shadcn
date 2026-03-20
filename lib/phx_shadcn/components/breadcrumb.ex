defmodule PhxShadcn.Components.Breadcrumb do
  @moduledoc """
  Breadcrumb components mirroring shadcn/ui Breadcrumb.

  A composable breadcrumb navigation with separator and ellipsis support.

  ## Sub-components

  - `breadcrumb/1` — `<nav>` wrapper with `aria-label="breadcrumb"`
  - `breadcrumb_list/1` — `<ol>` container
  - `breadcrumb_item/1` — `<li>` for each entry
  - `breadcrumb_link/1` — link (renders `<.link>` or `<span>`)
  - `breadcrumb_page/1` — current page (non-interactive)
  - `breadcrumb_separator/1` — visual separator (defaults to chevron)
  - `breadcrumb_ellipsis/1` — collapsed items indicator

  ## Examples

      <.breadcrumb>
        <.breadcrumb_list>
          <.breadcrumb_item>
            <.breadcrumb_link href="/">Home</.breadcrumb_link>
          </.breadcrumb_item>
          <.breadcrumb_separator />
          <.breadcrumb_item>
            <.breadcrumb_link href="/products">Products</.breadcrumb_link>
          </.breadcrumb_item>
          <.breadcrumb_separator />
          <.breadcrumb_item>
            <.breadcrumb_page>Current Page</.breadcrumb_page>
          </.breadcrumb_item>
        </.breadcrumb_list>
      </.breadcrumb>
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  # -- breadcrumb --

  attr :rest, :global
  slot :inner_block, required: true

  def breadcrumb(assigns) do
    ~H"""
    <nav data-slot="breadcrumb" aria-label="breadcrumb" {@rest}>
      {render_slot(@inner_block)}
    </nav>
    """
  end

  # -- breadcrumb_list --

  attr :class, :any, default: []
  attr :rest, :global
  slot :inner_block, required: true

  def breadcrumb_list(assigns) do
    assigns =
      assign(assigns, :computed_class, cn([
        "text-muted-foreground flex flex-wrap items-center gap-1.5 text-sm break-words sm:gap-2.5",
        assigns.class
      ]))

    ~H"""
    <ol data-slot="breadcrumb-list" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </ol>
    """
  end

  # -- breadcrumb_item --

  attr :class, :any, default: []
  attr :rest, :global
  slot :inner_block, required: true

  def breadcrumb_item(assigns) do
    assigns =
      assign(assigns, :computed_class, cn(["inline-flex items-center gap-1.5", assigns.class]))

    ~H"""
    <li data-slot="breadcrumb-item" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </li>
    """
  end

  # -- breadcrumb_link --

  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  attr :href, :string, default: nil
  attr :class, :any, default: []
  attr :rest, :global
  slot :inner_block, required: true

  def breadcrumb_link(assigns) do
    assigns =
      assigns
      |> assign(:computed_class, cn(["hover:text-foreground transition-colors", assigns.class]))
      |> assign(:is_link, assigns.navigate != nil || assigns.patch != nil || assigns.href != nil)

    ~H"""
    <.link
      :if={@is_link}
      navigate={@navigate}
      patch={@patch}
      href={@href}
      data-slot="breadcrumb-link"
      class={@computed_class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    <span :if={!@is_link} data-slot="breadcrumb-link" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  # -- breadcrumb_page --

  attr :class, :any, default: []
  attr :rest, :global
  slot :inner_block, required: true

  def breadcrumb_page(assigns) do
    assigns =
      assign(assigns, :computed_class, cn(["text-foreground font-normal", assigns.class]))

    ~H"""
    <span
      data-slot="breadcrumb-page"
      role="link"
      aria-disabled="true"
      aria-current="page"
      class={@computed_class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  # -- breadcrumb_separator --

  attr :class, :any, default: []
  attr :rest, :global
  slot :inner_block

  def breadcrumb_separator(assigns) do
    assigns =
      assign(assigns, :computed_class, cn(["[&>svg]:size-3.5", assigns.class]))

    ~H"""
    <li
      data-slot="breadcrumb-separator"
      role="presentation"
      aria-hidden="true"
      class={@computed_class}
      {@rest}
    >
      {if @inner_block != [], do: render_slot(@inner_block), else: default_chevron(assigns)}
    </li>
    """
  end

  defp default_chevron(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="16"
      height="16"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      class="size-3.5"
    >
      <path d="m9 18 6-6-6-6" />
    </svg>
    """
  end

  # -- breadcrumb_ellipsis --

  attr :class, :any, default: []
  attr :rest, :global

  def breadcrumb_ellipsis(assigns) do
    assigns =
      assign(assigns, :computed_class, cn(["flex size-9 items-center justify-center", assigns.class]))

    ~H"""
    <span
      data-slot="breadcrumb-ellipsis"
      role="presentation"
      aria-hidden="true"
      class={@computed_class}
      {@rest}
    >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        width="16"
        height="16"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="2"
        stroke-linecap="round"
        stroke-linejoin="round"
        class="size-4"
      >
        <circle cx="12" cy="12" r="1" />
        <circle cx="19" cy="12" r="1" />
        <circle cx="5" cy="12" r="1" />
      </svg>
      <span class="sr-only">More</span>
    </span>
    """
  end
end
