defmodule PhxShadcn.Components.Avatar do
  @moduledoc """
  Avatar component mirroring shadcn/ui Avatar.

  Displays a user avatar with image and fallback. The fallback is always
  rendered behind the image — if the image fails to load, the fallback
  shows through automatically (no JS needed).

  Includes AvatarBadge for status indicators, AvatarGroup for stacking
  multiple avatars, and AvatarGroupCount for overflow counts.

  ## Examples

      <.avatar>
        <.avatar_image src="/images/user.jpg" alt="User" />
        <.avatar_fallback>JD</.avatar_fallback>
      </.avatar>

      <.avatar size="sm">
        <.avatar_fallback>AB</.avatar_fallback>
      </.avatar>

      <.avatar_group>
        <.avatar>
          <.avatar_image src="/images/u1.jpg" alt="User 1" />
          <.avatar_fallback>U1</.avatar_fallback>
        </.avatar>
        <.avatar>
          <.avatar_image src="/images/u2.jpg" alt="User 2" />
          <.avatar_fallback>U2</.avatar_fallback>
        </.avatar>
        <.avatar_group_count>+3</.avatar_group_count>
      </.avatar_group>
  """

  use Phoenix.Component
  import PhxShadcn.Cn

  # -- Avatar --

  @avatar_base "group/avatar relative flex shrink-0 overflow-hidden rounded-full select-none"

  @avatar_sizes %{
    "default" => "size-8",
    "sm" => "size-6",
    "lg" => "size-10"
  }

  attr :size, :string, default: "default", values: ~w(default sm lg)
  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def avatar(assigns) do
    assigns =
      assign(assigns, :computed_class,
        cn([
          @avatar_base,
          Map.fetch!(@avatar_sizes, assigns.size),
          assigns.class
        ])
      )

    ~H"""
    <span data-slot="avatar" data-size={@size} class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  # -- AvatarImage --

  attr :src, :string, required: true
  attr :alt, :string, default: ""
  attr :class, :any, default: []
  attr :rest, :global

  def avatar_image(assigns) do
    assigns =
      assign(assigns, :computed_class, cn(["aspect-square size-full", assigns.class]))

    ~H"""
    <img
      data-slot="avatar-image"
      src={@src}
      alt={@alt}
      class={@computed_class}
      onerror="this.style.display='none'"
      {@rest}
    />
    """
  end

  # -- AvatarFallback --

  @fallback_classes [
    "bg-muted text-muted-foreground flex size-full items-center justify-center rounded-full text-sm",
    "group-data-[size=sm]/avatar:text-xs"
  ]

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def avatar_fallback(assigns) do
    assigns =
      assign(assigns, :computed_class, cn([@fallback_classes, assigns.class]))

    ~H"""
    <span data-slot="avatar-fallback" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  # -- AvatarBadge --

  @badge_classes [
    "bg-primary text-primary-foreground ring-background",
    "absolute right-0 bottom-0 z-10 inline-flex items-center justify-center rounded-full ring-2 select-none",
    "group-data-[size=sm]/avatar:size-2 group-data-[size=sm]/avatar:[&>svg]:hidden",
    "group-data-[size=default]/avatar:size-2.5 group-data-[size=default]/avatar:[&>svg]:size-2",
    "group-data-[size=lg]/avatar:size-3 group-data-[size=lg]/avatar:[&>svg]:size-2"
  ]

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block

  def avatar_badge(assigns) do
    assigns =
      assign(assigns, :computed_class, cn([@badge_classes, assigns.class]))

    ~H"""
    <span data-slot="avatar-badge" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  # -- AvatarGroup --

  @group_classes "*:data-[slot=avatar]:ring-background group/avatar-group flex -space-x-2 *:data-[slot=avatar]:ring-2"

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def avatar_group(assigns) do
    assigns =
      assign(assigns, :computed_class, cn([@group_classes, assigns.class]))

    ~H"""
    <div data-slot="avatar-group" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # -- AvatarGroupCount --

  @group_count_classes [
    "bg-muted text-muted-foreground ring-background",
    "relative flex size-8 shrink-0 items-center justify-center rounded-full text-sm ring-2",
    "[&>svg]:size-4",
    "group-has-data-[size=lg]/avatar-group:size-10 group-has-data-[size=lg]/avatar-group:[&>svg]:size-5",
    "group-has-data-[size=sm]/avatar-group:size-6 group-has-data-[size=sm]/avatar-group:[&>svg]:size-3"
  ]

  attr :class, :any, default: []
  attr :rest, :global

  slot :inner_block, required: true

  def avatar_group_count(assigns) do
    assigns =
      assign(assigns, :computed_class, cn([@group_count_classes, assigns.class]))

    ~H"""
    <div data-slot="avatar-group-count" class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
