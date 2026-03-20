defmodule PhxShadcn.CnTest do
  use ExUnit.Case, async: true
  import PhxShadcn.Cn

  describe "cn/1 with list" do
    test "joins multiple class strings" do
      assert cn(["flex", "items-center"]) == "flex items-center"
    end

    test "filters out nil values" do
      assert cn(["flex", nil, "items-center"]) == "flex items-center"
    end

    test "filters out false values" do
      assert cn(["flex", false, "items-center"]) == "flex items-center"
    end

    test "handles nested lists" do
      assert cn([["flex", "gap-2"], "items-center"]) == "flex gap-2 items-center"
    end

    test "returns empty string for all-nil list" do
      assert cn([nil, nil, false]) == ""
    end

    test "returns empty string for empty list" do
      assert cn([]) == ""
    end
  end

  describe "cn/2 tailwind merge conflict resolution" do
    test "later padding overrides earlier" do
      assert cn("p-6", "p-2") == "p-2"
    end

    test "non-conflicting classes are preserved" do
      assert cn("p-6 bg-card", "p-2") == "bg-card p-2"
    end

    test "later rounding overrides earlier" do
      assert cn("rounded-xl", "rounded-none") == "rounded-none"
    end

    test "nil override is ignored" do
      assert cn("text-sm font-bold", nil) == "text-sm font-bold"
    end

    test "false override is ignored" do
      assert cn("base-class", false) == "base-class"
    end
  end

  describe "cn/3" do
    test "merges three class arguments" do
      result = cn("p-4", "text-sm", "p-2")
      assert result == "text-sm p-2"
    end
  end

  describe "cn/4" do
    test "merges four class arguments" do
      result = cn("p-4", "text-sm", "font-bold", "p-2")
      assert result == "text-sm font-bold p-2"
    end
  end

  describe "real-world shadcn patterns" do
    test "user class overrides component default padding" do
      component_default = "inline-flex items-center justify-center rounded-md p-4"
      user_class = "p-2"
      result = cn(component_default, user_class)
      assert result =~ "p-2"
      refute result =~ "p-4"
    end

    test "user class overrides component background" do
      component_default = "bg-primary text-primary-foreground"
      user_class = "bg-red-500"
      result = cn(component_default, user_class)
      assert result =~ "bg-red-500"
      refute result =~ "bg-primary"
    end

    test "conditional class via boolean" do
      variant = :destructive
      result = cn("base-class", variant == :destructive && "bg-destructive")
      assert result =~ "bg-destructive"
      assert result =~ "base-class"
    end

    test "conditional class false is excluded" do
      result = cn("base-class", false && "bg-destructive")
      assert result == "base-class"
    end
  end
end
