defmodule PhxShadcn.Cn do
  @moduledoc """
  Class merge utility — the Elixir equivalent of shadcn's `cn()`.

  Combines `clsx`-style conditional class joining with `tailwind-merge`
  conflict resolution. User classes always win over component defaults.

  ## Examples

      iex> import PhxShadcn.Cn
      iex> cn("p-6 bg-card", "p-2")
      "bg-card p-2"

      iex> import PhxShadcn.Cn
      iex> cn("text-sm font-bold", nil)
      "text-sm font-bold"

      iex> import PhxShadcn.Cn
      iex> cn(["flex", nil, "items-center", false])
      "flex items-center"
  """

  # Extend default colors with shadcn's CSS variable-based theme colors
  @shadcn_colors ~w(
    background foreground
    card card-foreground
    popover popover-foreground
    primary primary-foreground
    secondary secondary-foreground
    muted muted-foreground
    accent accent-foreground
    destructive destructive-foreground
    border input ring
    chart-1 chart-2 chart-3 chart-4 chart-5
    sidebar-background sidebar-foreground sidebar-primary sidebar-primary-foreground
    sidebar-accent sidebar-accent-foreground sidebar-border sidebar-ring
  )

  existing_colors = TailwindMerge.Config.colors()
  # Add as both bare strings (bg-primary) and with opacity support (bg-primary/50)
  shadcn_bare = @shadcn_colors
  shadcn_with_opacity = Enum.map(@shadcn_colors, &{&1, [{TailwindMerge.Validator, :opacity?}]})
  all_colors = existing_colors ++ shadcn_bare ++ shadcn_with_opacity
  custom_class_groups = TailwindMerge.Config.class_groups(colors: all_colors)

  use TailwindMerge, config: TailwindMerge.Config.new(class_groups: custom_class_groups)

  @doc """
  Merges Tailwind CSS classes with conflict resolution.

  Accepts any combination of:
  - Strings: `"p-4 text-sm"`
  - nil / false: ignored
  - Lists: flattened and filtered

  Later arguments override conflicting classes from earlier arguments.
  """
  def cn(classes) when is_binary(classes), do: maybe_merge(classes)

  def cn(classes) when is_list(classes) do
    classes
    |> List.flatten()
    |> Enum.reject(&(!&1))
    |> Enum.join(" ")
    |> maybe_merge()
  end

  def cn(base, override) do
    cn([base, override])
  end

  def cn(a, b, c) do
    cn([a, b, c])
  end

  def cn(a, b, c, d) do
    cn([a, b, c, d])
  end

  defp maybe_merge(""), do: ""
  defp maybe_merge(classes), do: tw(classes)
end
