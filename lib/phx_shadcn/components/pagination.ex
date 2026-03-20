defmodule PhxShadcn.Components.Pagination do
  @moduledoc """
  Pagination components mirroring shadcn/ui Pagination.

  Composable pagination navigation with previous/next, page links, and ellipsis.
  `pagination_link` reuses Button variant styling (outline when active, ghost when
  inactive).

  ## Sub-components

  - `pagination/1` — `<nav>` wrapper
  - `pagination_content/1` — `<ul>` container
  - `pagination_item/1` — `<li>` for each entry
  - `pagination_link/1` — page number link (active/inactive)
  - `pagination_previous/1` — "Previous" link with chevron
  - `pagination_next/1` — "Next" link with chevron
  - `pagination_ellipsis/1` — collapsed pages indicator

  ## Examples

      <.pagination>
        <.pagination_content>
          <.pagination_item>
            <.pagination_previous href="/page/1" />
          </.pagination_item>
          <.pagination_item>
            <.pagination_link href="/page/1" is_active>1</.pagination_link>
          </.pagination_item>
          <.pagination_item>
            <.pagination_link href="/page/2">2</.pagination_link>
          </.pagination_item>
          <.pagination_item>
            <.pagination_ellipsis />
          </.pagination_item>
          <.pagination_item>
            <.pagination_next href="/page/2" />
          </.pagination_item>
        </.pagination_content>
      </.pagination>
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  # Button base classes (subset relevant for pagination links)
  @button_base [
    "inline-flex items-center justify-center gap-2 whitespace-nowrap",
    "rounded-md text-sm font-medium transition-all shrink-0",
    "disabled:pointer-events-none disabled:opacity-50",
    "[&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4",
    "outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]"
  ]

  @variant_outline "border bg-background shadow-xs hover:bg-accent hover:text-accent-foreground dark:bg-input/30 dark:border-input dark:hover:bg-input/50"
  @variant_ghost "hover:bg-accent hover:text-accent-foreground dark:hover:bg-accent/50"

  @size_icon "size-9"
  @size_default "h-9 px-4 py-2 has-[>svg]:px-3"

  # -- pagination --

  attr :class, :any, default: []
  attr :rest, :global
  slot :inner_block, required: true

  def pagination(assigns) do
    assigns =
      assign(assigns, :computed_class, cn(["mx-auto flex w-full justify-center", assigns.class]))

    ~H"""
    <nav data-slot="pagination" role="navigation" aria-label="pagination" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </nav>
    """
  end

  # -- pagination_content --

  attr :class, :any, default: []
  attr :rest, :global
  slot :inner_block, required: true

  def pagination_content(assigns) do
    assigns =
      assign(assigns, :computed_class, cn(["flex flex-row items-center gap-1", assigns.class]))

    ~H"""
    <ul data-slot="pagination-content" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </ul>
    """
  end

  # -- pagination_item --

  attr :class, :any, default: []
  attr :rest, :global
  slot :inner_block, required: true

  def pagination_item(assigns) do
    ~H"""
    <li data-slot="pagination-item" {@rest}>
      {render_slot(@inner_block)}
    </li>
    """
  end

  # -- pagination_link --

  attr :is_active, :boolean, default: false
  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  attr :href, :string, default: nil
  attr :class, :any, default: []
  attr :rest, :global
  slot :inner_block, required: true

  def pagination_link(assigns) do
    assigns =
      assigns
      |> assign(:computed_class, cn([
        @button_base,
        if(assigns.is_active, do: @variant_outline, else: @variant_ghost),
        @size_icon,
        assigns.class
      ]))
      |> assign(:is_link, assigns.navigate != nil || assigns.patch != nil || assigns.href != nil)

    ~H"""
    <.link
      :if={@is_link}
      navigate={@navigate}
      patch={@patch}
      href={@href}
      data-slot="pagination-link"
      data-active={@is_active}
      aria-current={@is_active && "page"}
      class={@computed_class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    <span
      :if={!@is_link}
      data-slot="pagination-link"
      data-active={@is_active}
      aria-current={@is_active && "page"}
      class={@computed_class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  # -- pagination_previous --

  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  attr :href, :string, default: nil
  attr :class, :any, default: []
  attr :rest, :global

  def pagination_previous(assigns) do
    assigns =
      assigns
      |> assign(:computed_class, cn([
        @button_base,
        @variant_ghost,
        @size_default,
        "gap-1 px-2.5 sm:pl-2.5",
        assigns.class
      ]))
      |> assign(:is_link, assigns.navigate != nil || assigns.patch != nil || assigns.href != nil)

    ~H"""
    <.link
      :if={@is_link}
      navigate={@navigate}
      patch={@patch}
      href={@href}
      data-slot="pagination-previous"
      aria-label="Go to previous page"
      class={@computed_class}
      {@rest}
    >
      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="size-4"><path d="m15 18-6-6 6-6" /></svg>
      <span class="hidden sm:block">Previous</span>
    </.link>
    <span
      :if={!@is_link}
      data-slot="pagination-previous"
      aria-label="Go to previous page"
      class={@computed_class}
      {@rest}
    >
      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="size-4"><path d="m15 18-6-6 6-6" /></svg>
      <span class="hidden sm:block">Previous</span>
    </span>
    """
  end

  # -- pagination_next --

  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  attr :href, :string, default: nil
  attr :class, :any, default: []
  attr :rest, :global

  def pagination_next(assigns) do
    assigns =
      assigns
      |> assign(:computed_class, cn([
        @button_base,
        @variant_ghost,
        @size_default,
        "gap-1 px-2.5 sm:pr-2.5",
        assigns.class
      ]))
      |> assign(:is_link, assigns.navigate != nil || assigns.patch != nil || assigns.href != nil)

    ~H"""
    <.link
      :if={@is_link}
      navigate={@navigate}
      patch={@patch}
      href={@href}
      data-slot="pagination-next"
      aria-label="Go to next page"
      class={@computed_class}
      {@rest}
    >
      <span class="hidden sm:block">Next</span>
      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="size-4"><path d="m9 18 6-6-6-6" /></svg>
    </.link>
    <span
      :if={!@is_link}
      data-slot="pagination-next"
      aria-label="Go to next page"
      class={@computed_class}
      {@rest}
    >
      <span class="hidden sm:block">Next</span>
      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="size-4"><path d="m9 18 6-6-6-6" /></svg>
    </span>
    """
  end

  # -- pagination_ellipsis --

  attr :class, :any, default: []
  attr :rest, :global

  def pagination_ellipsis(assigns) do
    assigns =
      assign(assigns, :computed_class, cn(["flex size-9 items-center justify-center", assigns.class]))

    ~H"""
    <span data-slot="pagination-ellipsis" role="presentation" aria-hidden="true" class={@computed_class} {@rest}>
      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="size-4">
        <circle cx="12" cy="12" r="1" /><circle cx="19" cy="12" r="1" /><circle cx="5" cy="12" r="1" />
      </svg>
      <span class="sr-only">More pages</span>
    </span>
    """
  end
end
