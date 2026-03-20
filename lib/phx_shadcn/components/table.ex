defmodule PhxShadcn.Components.Table do
  @moduledoc """
  Table components mirroring shadcn/ui Table.

  A set of composable table sub-components with consistent styling,
  hover states, and selection support.

  ## Sub-components

  - `table/1` — wrapper with horizontal scroll + `<table>`
  - `table_header/1` — `<thead>`
  - `table_body/1` — `<tbody>`
  - `table_footer/1` — `<tfoot>`
  - `table_row/1` — `<tr>` with hover and selected states
  - `table_head/1` — `<th>`
  - `table_cell/1` — `<td>`
  - `table_caption/1` — `<caption>`

  ## Examples

      <.table>
        <.table_caption>A list of your recent invoices.</.table_caption>
        <.table_header>
          <.table_row>
            <.table_head>Invoice</.table_head>
            <.table_head>Status</.table_head>
            <.table_head class={["text-right"]}>Amount</.table_head>
          </.table_row>
        </.table_header>
        <.table_body>
          <.table_row>
            <.table_cell class={["font-medium"]}>INV001</.table_cell>
            <.table_cell>Paid</.table_cell>
            <.table_cell class={["text-right"]}>$250.00</.table_cell>
          </.table_row>
        </.table_body>
      </.table>
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  # -- table --

  attr :class, :any, default: []
  attr :rest, :global
  slot :inner_block, required: true

  def table(assigns) do
    assigns =
      assign(assigns, :computed_class, cn(["w-full caption-bottom text-sm", assigns.class]))

    ~H"""
    <div data-slot="table-container" class="relative w-full overflow-x-auto">
      <table data-slot="table" class={@computed_class} {@rest}>
        {render_slot(@inner_block)}
      </table>
    </div>
    """
  end

  # -- table_header --

  attr :class, :any, default: []
  attr :rest, :global
  slot :inner_block, required: true

  def table_header(assigns) do
    assigns =
      assign(assigns, :computed_class, cn(["[&_tr]:border-b", assigns.class]))

    ~H"""
    <thead data-slot="table-header" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </thead>
    """
  end

  # -- table_body --

  attr :class, :any, default: []
  attr :rest, :global
  slot :inner_block, required: true

  def table_body(assigns) do
    assigns =
      assign(assigns, :computed_class, cn(["[&_tr:last-child]:border-0", assigns.class]))

    ~H"""
    <tbody data-slot="table-body" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </tbody>
    """
  end

  # -- table_footer --

  attr :class, :any, default: []
  attr :rest, :global
  slot :inner_block, required: true

  def table_footer(assigns) do
    assigns =
      assign(assigns, :computed_class, cn(["bg-muted/50 border-t font-medium [&>tr]:last:border-b-0", assigns.class]))

    ~H"""
    <tfoot data-slot="table-footer" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </tfoot>
    """
  end

  # -- table_row --

  attr :class, :any, default: []
  attr :rest, :global
  slot :inner_block, required: true

  def table_row(assigns) do
    assigns =
      assign(assigns, :computed_class, cn(["hover:bg-muted/50 data-[state=selected]:bg-muted border-b transition-colors", assigns.class]))

    ~H"""
    <tr data-slot="table-row" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </tr>
    """
  end

  # -- table_head --

  attr :class, :any, default: []
  attr :rest, :global
  slot :inner_block, required: true

  def table_head(assigns) do
    assigns =
      assign(assigns, :computed_class, cn([
        "text-foreground h-10 px-2 text-left align-middle font-medium whitespace-nowrap",
        "[&:has([role=checkbox])]:pr-0 [&>[role=checkbox]]:translate-y-[2px]",
        assigns.class
      ]))

    ~H"""
    <th data-slot="table-head" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </th>
    """
  end

  # -- table_cell --

  attr :class, :any, default: []
  attr :rest, :global
  slot :inner_block, required: true

  def table_cell(assigns) do
    assigns =
      assign(assigns, :computed_class, cn([
        "p-2 align-middle whitespace-nowrap",
        "[&:has([role=checkbox])]:pr-0 [&>[role=checkbox]]:translate-y-[2px]",
        assigns.class
      ]))

    ~H"""
    <td data-slot="table-cell" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </td>
    """
  end

  # -- table_caption --

  attr :class, :any, default: []
  attr :rest, :global
  slot :inner_block, required: true

  def table_caption(assigns) do
    assigns =
      assign(assigns, :computed_class, cn(["text-muted-foreground mt-4 text-sm", assigns.class]))

    ~H"""
    <caption data-slot="table-caption" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </caption>
    """
  end
end
