defmodule PhxShadcn do
  @moduledoc """
  Phoenix LiveView component library mirroring shadcn/ui.

  ## Usage

      use PhxShadcn

  This imports all PhxShadcn components into your module.
  """

  defmacro __using__(_opts) do
    quote do
      import PhxShadcn.Components.Accordion
      import PhxShadcn.Components.Alert
      import PhxShadcn.Components.AlertDialog
      import PhxShadcn.Components.AspectRatio
      import PhxShadcn.Components.Avatar
      import PhxShadcn.Components.Badge
      import PhxShadcn.Components.Breadcrumb
      import PhxShadcn.Components.Checkbox
      import PhxShadcn.Components.Collapsible
      import PhxShadcn.Components.Dialog
      import PhxShadcn.Components.ContextMenu
      import PhxShadcn.Components.DropdownMenu
      import PhxShadcn.Components.Menubar
      import PhxShadcn.Components.Popover
      import PhxShadcn.Components.Tooltip
      import PhxShadcn.Components.HoverCard
      import PhxShadcn.Components.Sheet
      import PhxShadcn.Components.Button
      import PhxShadcn.Components.Form
      import PhxShadcn.Components.FormField
      import PhxShadcn.Components.Card
      import PhxShadcn.Components.Input
      import PhxShadcn.Components.InputOTP
      import PhxShadcn.Components.Label
      import PhxShadcn.Components.Pagination
      import PhxShadcn.Components.Progress
      import PhxShadcn.Components.Slider
      import PhxShadcn.Components.Separator
      import PhxShadcn.Components.Skeleton
      import PhxShadcn.Components.Switch
      import PhxShadcn.Components.Table
      import PhxShadcn.Components.Textarea
      import PhxShadcn.Components.Tabs
      import PhxShadcn.Components.RadioGroup
      import PhxShadcn.Components.ScrollArea
      import PhxShadcn.Components.Toggle
      import PhxShadcn.Components.ToggleGroup
      import PhxShadcn.Components.NativeSelect
      import PhxShadcn.Components.Select
      import PhxShadcn.Components.Toast
    end
  end
end
