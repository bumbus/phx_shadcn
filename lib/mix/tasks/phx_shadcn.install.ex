if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.PhxShadcn.Install do
    @shortdoc "Sets up PhxShadcn in your Phoenix project"
    @moduledoc """
    Installs PhxShadcn into your Phoenix project.

        $ mix phx_shadcn.install

    This will:

    - Add `use PhxShadcn` to your web module's html_helpers
    - Add exclusions for conflicting CoreComponents functions (button, input, table)
    - Inject the shadcn/ui CSS theme into `assets/css/app.css`
    - Patch `assets/js/app.js` with hook imports
    - Add base body styles (`bg-background text-foreground`)

    ## Options

    - `--no-css` — Skip CSS theme injection
    - `--no-js` — Skip JavaScript hook patching
    """
    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :phx_shadcn,
        adds_deps: [],
        installs: [],
        example: "mix phx_shadcn.install"
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      opts = igniter.args.argv
      skip_css = "--no-css" in opts
      skip_js = "--no-js" in opts

      app_name = Igniter.Project.Application.app_name(igniter)
      web_module = Module.concat([Macro.camelize(to_string(app_name)) <> "Web"])

      igniter
      |> patch_web_module(web_module)
      |> then(fn ig -> if skip_css, do: ig, else: patch_css(ig) end)
      |> then(fn ig -> if skip_js, do: ig, else: patch_js(ig) end)
      |> patch_esbuild_config(app_name)
      |> patch_body_styles()
      |> Igniter.add_notice("""
      PhxShadcn installed successfully!

      Next steps:
        1. Run `mix deps.get` if you haven't already
        2. Add `class="dark"` to your <html> tag to enable dark mode
        3. Visit https://github.com/phx-shadcn/phx_shadcn for component docs
      """)
    end

    # ── Elixir: patch web module ──────────────────────────────────────

    defp patch_web_module(igniter, web_module) do
      web_module_path = Igniter.Project.Module.proper_location(igniter, web_module)

      igniter
      |> Igniter.update_elixir_file(web_module_path, fn zipper ->
        # Find the html_helpers function and inject `use PhxShadcn`
        with {:ok, zipper} <- find_html_helpers_quote(zipper) do
          # Check if `use PhxShadcn` already exists
          source = Sourceror.Zipper.root(zipper) |> Sourceror.to_string()

          if String.contains?(source, "use PhxShadcn") do
            {:ok, zipper}
          else
            inject_use_and_fix_core_components(zipper, source)
          end
        else
          _ ->
            {:warning,
             """
             Could not find `html_helpers` in #{inspect(web_module)}.
             Please manually add `use PhxShadcn` to your html_helpers function.

             If your CoreComponents module defines button/1, input/1, or table/1,
             add exclusions:

                 import #{inspect(web_module)}.CoreComponents, except: [button: 1, input: 1, table: 1]
             """}
          end
      end)
    end

    defp find_html_helpers_quote(zipper) do
      # Look for `defp html_helpers do` containing a `quote do` block
      # Phoenix generates this as a private function
      case Igniter.Code.Function.move_to_defp(zipper, :html_helpers, 0) do
        {:ok, _} = ok -> ok
        _ -> Igniter.Code.Function.move_to_def(zipper, :html_helpers, 0)
      end
    end

    defp inject_use_and_fix_core_components(_zipper, source) do
      # We'll use text-based patching since AST manipulation of `quote` blocks
      # with import/use is tricky. We modify the source and re-parse.

      new_source =
        source
        |> maybe_add_core_components_exclusions()
        |> inject_use_phx_shadcn()

      {:ok, Sourceror.parse_string!(new_source) |> Sourceror.Zipper.zip()}
    end

    defp maybe_add_core_components_exclusions(source) do
      # Match `import SomeModule.CoreComponents` without an `except:` clause
      core_import_regex = ~r/(import\s+\S+\.CoreComponents)(?!\s*,\s*except:)/

      if Regex.match?(core_import_regex, source) do
        Regex.replace(core_import_regex, source, "\\1, except: [button: 1, input: 1, table: 1]")
      else
        source
      end
    end

    defp inject_use_phx_shadcn(source) do
      # Insert `use PhxShadcn` after the CoreComponents import line,
      # or after `import Phoenix.HTML` if no CoreComponents import
      cond do
        String.contains?(source, "CoreComponents") ->
          String.replace(
            source,
            ~r/(import\s+\S+\.CoreComponents[^\n]*\n)/,
            "\\1      use PhxShadcn\n",
            global: false
          )

        String.contains?(source, "import Phoenix.HTML") ->
          String.replace(
            source,
            ~r/(import Phoenix\.HTML\n)/,
            "\\1      use PhxShadcn\n",
            global: false
          )

        true ->
          # Fallback: insert after `quote do`
          String.replace(
            source,
            ~r/(quote do\n)/,
            "\\1      use PhxShadcn\n",
            global: false
          )
      end
    end

    # ── CSS: inject theme into app.css ────────────────────────────────

    defp patch_css(igniter) do
      css_path = "assets/css/app.css"
      template_path = Application.app_dir(:phx_shadcn, "priv/templates/phx_shadcn.css")

      if Igniter.exists?(igniter, css_path) do
        igniter
        |> Igniter.update_file(css_path, fn source ->
          content = Rewrite.Source.get(source, :content)

          if String.contains?(content, "phx_shadcn") || String.contains?(content, "--color-background") do
            # Already has phx_shadcn theme — skip
            source
          else
            theme_css = File.read!(template_path)

            # Insert after the @import "tailwindcss" line and any existing @source directives
            new_content = inject_css_after_imports(content, theme_css)
            Rewrite.Source.update(source, :content, new_content)
          end
        end)
      else
        Igniter.add_notice(igniter, """
        Could not find #{css_path}.
        Please manually copy the PhxShadcn CSS theme from:
          #{template_path}
        """)
      end
    end

    defp inject_css_after_imports(content, theme_css) do
      # Find the insertion point after all top-level @import/@source/@plugin blocks.
      # Must account for multi-line @plugin blocks with { ... }.
      lines = String.split(content, "\n")

      {insert_idx, _depth} =
        lines
        |> Enum.with_index()
        |> Enum.reduce({0, 0}, fn {line, idx}, {last_directive_end, depth} ->
          trimmed = String.trim(line)
          opens = count_char(line, ?{)
          closes = count_char(line, ?})
          new_depth = depth + opens - closes

          cond do
            # Top-level directive line (not inside a block)
            depth == 0 && String.match?(trimmed, ~r/^@(import|source|plugin)\s/) ->
              if new_depth == 0 do
                # Single-line directive
                {idx + 1, 0}
              else
                # Opens a block — track it
                {idx + 1, new_depth}
              end

            # Inside a block opened by a directive
            depth > 0 ->
              if new_depth == 0 do
                # Block closed — this is where we can insert after
                {idx + 1, 0}
              else
                {last_directive_end, new_depth}
              end

            true ->
              {last_directive_end, new_depth}
          end
        end)

      {before, rest} = Enum.split(lines, insert_idx)
      Enum.join(before ++ ["", theme_css] ++ rest, "\n")
    end

    defp count_char(string, char) do
      string |> to_charlist() |> Enum.count(&(&1 == char))
    end

    # ── JS: patch app.js with hook imports ────────────────────────────

    defp patch_js(igniter) do
      js_path = "assets/js/app.js"

      if Igniter.exists?(igniter, js_path) do
        igniter
        |> Igniter.update_file(js_path, fn source ->
          content = Rewrite.Source.get(source, :content)

          if String.contains?(content, "phx_shadcn") || String.contains?(content, "phxShadcnHooks") do
            # Already patched — skip
            source
          else
            new_content =
              content
              |> inject_js_import()
              |> inject_js_hooks()

            Rewrite.Source.update(source, :content, new_content)
          end
        end)
      else
        Igniter.add_notice(igniter, """
        Could not find #{js_path}.
        Please manually add to your JavaScript entry point:

            import { hooks as phxShadcnHooks, PhxShadcn } from "phx_shadcn";
            PhxShadcn.init();

        And spread `...phxShadcnHooks` into your LiveSocket hooks.
        """)
      end
    end

    defp inject_js_import(content) do
      import_line = ~s|import { hooks as phxShadcnHooks, PhxShadcn } from "phx_shadcn";\nPhxShadcn.init();|

      # Insert after the last import line
      lines = String.split(content, "\n")

      last_import_idx =
        lines
        |> Enum.with_index()
        |> Enum.reverse()
        |> Enum.find_value(0, fn {line, idx} ->
          if String.match?(line, ~r/^import\s/) do
            idx
          end
        end)

      {before, rest} = Enum.split(lines, last_import_idx + 1)
      Enum.join(before ++ [import_line] ++ rest, "\n")
    end

    defp inject_js_hooks(content) do
      # Find `hooks: {` or `hooks:{` and add `...phxShadcnHooks,` after it
      # Handles both multiline `hooks: {\n` and single-line `hooks: {...foo}`
      cond do
        String.match?(content, ~r/hooks:\s*\{[^\n}]/) ->
          # Single-line: hooks: {...colocatedHooks} → hooks: {...phxShadcnHooks, ...colocatedHooks}
          Regex.replace(
            ~r/(hooks:\s*\{)/,
            content,
            "\\1...phxShadcnHooks, ",
            global: false
          )

        String.match?(content, ~r/hooks:\s*\{\n/) ->
          # Multiline: hooks: {\n → hooks: {\n    ...phxShadcnHooks,\n
          Regex.replace(
            ~r/(hooks:\s*\{)\n/,
            content,
            "\\1\n    ...phxShadcnHooks,\n",
            global: false
          )

        true ->
          content
      end
    end

    # ── Esbuild: ensure NODE_PATH includes deps for package resolution ─

    defp patch_esbuild_config(igniter, app_name) do
      config_path = "config/config.exs"

      if Igniter.exists?(igniter, config_path) do
        igniter
        |> Igniter.update_file(config_path, fn source ->
          content = Rewrite.Source.get(source, :content)

          # Check if NODE_PATH already includes deps (Phoenix 1.8+ does this by default)
          if String.contains?(content, "NODE_PATH") do
            source
          else
            # Add NODE_PATH to esbuild config so it can resolve phx_shadcn
            app_str = to_string(app_name)

            new_content =
              Regex.replace(
                ~r/(config\s+:esbuild,[^[]*#{Regex.escape(app_str)}:\s*\[[^\]]*\benv:\s*%\{)/,
                content,
                ~s|\\1"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()], |,
                global: false
              )

            if new_content == content do
              # Couldn't find env: in esbuild config — skip
              source
            else
              Rewrite.Source.update(source, :content, new_content)
            end
          end
        end)
      else
        igniter
      end
    end

    # ── Body styles ───────────────────────────────────────────────────

    defp patch_body_styles(igniter) do
      css_path = "assets/css/app.css"

      if Igniter.exists?(igniter, css_path) do
        igniter
        |> Igniter.update_file(css_path, fn source ->
          content = Rewrite.Source.get(source, :content)

          if String.contains?(content, "bg-background") do
            source
          else
            body_style = "\nbody {\n  @apply bg-background text-foreground;\n}\n"
            Rewrite.Source.update(source, :content, content <> body_style)
          end
        end)
      else
        igniter
      end
    end
  end
else
  defmodule Mix.Tasks.PhxShadcn.Install do
    @shortdoc "Sets up PhxShadcn in your Phoenix project"
    @moduledoc """
    Installs PhxShadcn into your Phoenix project.

    For the best experience, add `{:igniter, "~> 0.5"}` to your deps and run:

        $ mix igniter.install phx_shadcn

    Without Igniter, this task prints manual setup instructions.
    """
    use Mix.Task

    @impl true
    def run(_args) do
      Mix.shell().info("""
      PhxShadcn Manual Setup
      ======================

      Igniter is not installed. For automatic setup, add to your deps:

          {:igniter, "~> 0.5"}

      Then run: mix igniter.install phx_shadcn

      ── Manual Steps ──

      1. Add `use PhxShadcn` to your web module's html_helpers:

          defp html_helpers do
            quote do
              use Gettext, backend: MyAppWeb.Gettext
              import Phoenix.HTML
              import MyAppWeb.CoreComponents, except: [button: 1, input: 1, table: 1]
              use PhxShadcn
              # ...
            end
          end

      2. Copy the CSS theme to your assets/css/app.css.
         Template located at: deps/phx_shadcn/priv/templates/phx_shadcn.css

      3. Add hook imports to assets/js/app.js:

          import { hooks as phxShadcnHooks, PhxShadcn } from "phx_shadcn";
          PhxShadcn.init();

          const liveSocket = new LiveSocket("/live", Socket, {
            hooks: { ...phxShadcnHooks, /* your hooks */ },
            // ...
          });

      4. Add body styles to your app.css:

          body {
            @apply bg-background text-foreground;
          }

      5. For dark mode, add class="dark" to your <html> tag.

      See README.md for full documentation.
      """)
    end
  end
end
