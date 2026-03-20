# PhxShadcn

Phoenix LiveView component library mirroring [shadcn/ui](https://ui.shadcn.com) — visually faithful, LiveView-native.

39 components, 22 JS hooks, 3-mode state ownership (client/hybrid/server).

## Installation

Add `phx_shadcn` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:phx_shadcn, "~> 0.1.0"},
    {:igniter, "~> 0.5"}  # optional, enables automatic setup
  ]
end
```

### Automatic setup (recommended)

```bash
mix igniter.install phx_shadcn
```

This patches your web module, CSS, and JavaScript automatically. Done.

### Manual setup

If you prefer not to use Igniter, follow these steps:

#### 1. Web module

In your `lib/my_app_web.ex`, update `html_helpers`:

```elixir
defp html_helpers do
  quote do
    use Gettext, backend: MyAppWeb.Gettext
    import Phoenix.HTML
    # Exclude components that PhxShadcn replaces
    import MyAppWeb.CoreComponents, except: [button: 1, input: 1, table: 1]
    # Import all PhxShadcn components
    use PhxShadcn

    alias Phoenix.LiveView.JS
    # ...
  end
end
```

PhxShadcn provides `button/1`, `input/1`, and `table/1` (plus sub-components) that replace
Phoenix's default CoreComponents versions. All other CoreComponents (`flash/1`, `header/1`,
`icon/1`, `simple_form/1`, etc.) remain available.

#### 2. CSS theme

Copy the shadcn theme into your `assets/css/app.css`. The full template is at
`deps/phx_shadcn/priv/templates/phx_shadcn.css` after running `mix deps.get`.

The key pieces:

```css
/* Add after your @import "tailwindcss" line */

/* Scan phx_shadcn components for Tailwind classes */
@source "../../deps/phx_shadcn/lib";

/* shadcn theme — colors, radius, animations, custom variants */
@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-primary: var(--primary);
  /* ... see full template for all colors, radius, animations */
}

/* Light/dark color values */
:root {
  --radius: 0.625rem;
  --background: oklch(1 0 0);
  --foreground: oklch(0.145 0 0);
  /* ... see full template */
}

.dark {
  --background: oklch(0.145 0 0);
  --foreground: oklch(0.985 0 0);
  /* ... see full template */
}

/* Required custom variants */
@custom-variant data-open { ... }
@custom-variant data-closed { ... }
@custom-variant data-checked { ... }
@custom-variant phx-click-loading (.phx-click-loading&, .phx-click-loading &);
@custom-variant phx-submit-loading (.phx-submit-loading&, .phx-submit-loading &);
@custom-variant dark (&:where(.dark, .dark *));

/* Base body styles */
body {
  @apply bg-background text-foreground;
}
```

The `@source` directive is critical — without it, Tailwind won't see the classes used inside
PhxShadcn components.

#### 3. JavaScript hooks

In `assets/js/app.js`:

```js
import { hooks as phxShadcnHooks, PhxShadcn } from "phx_shadcn";

// Optional: expose vanilla JS helpers for inline onclick handlers
PhxShadcn.init();

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: { ...phxShadcnHooks, /* your hooks */ },
  // ...
});
```

One spread covers all interactive components. Hook names are prefixed with `PhxShadcn` to
avoid clashes with your own hooks.

#### 4. Dark mode

Add `class="dark"` to your `<html>` tag. The theme uses the `.dark` class strategy
(not `prefers-color-scheme`), so you control it however you like — a toggle, a cookie,
user preference, etc.

## Components

### T1 — Static (15)
Badge, Button, Card, Separator, Skeleton, Alert, Avatar, AspectRatio, Label,
Input, Textarea, Table, Breadcrumb, Pagination, Checkbox

### T2 — Interactive (11)
Accordion, Collapsible, Tabs, Toggle, ToggleGroup, Switch, RadioGroup,
Progress, Slider, ScrollArea, Form + FormField

### T3 — Advanced (13)
Dialog, AlertDialog, Sheet, Popover, Tooltip, HoverCard, DropdownMenu,
ContextMenu, Menubar, Select, InputOTP, Toast

## State Modes

Every interactive component supports 3 state modes, determined by which assigns you pass:

| Mode | Assigns | Behavior |
|------|---------|----------|
| **Client** | _(none)_ | Pure JS toggling. Server is unaware. Zero latency. |
| **Hybrid** | `on_value_change` | JS toggles instantly, then pushes event to server. |
| **Server** | `value` | Server owns the state. Clicks push events, server re-renders. |

```heex
<%!-- Client-only --%>
<.accordion id="faq" type="single" collapsible>
  ...
</.accordion>

<%!-- Hybrid --%>
<.accordion id="faq" type="single" collapsible on_value_change="accordion:change">
  ...
</.accordion>

<%!-- Server-controlled --%>
<.accordion id="faq" type="single" collapsible value={@open_value} on_value_change="accordion:change">
  ...
</.accordion>
```

## Event System

### Callbacks (client -> server)

The `on_value_change` / `on_open_change` attr accepts either a **string** (event name) or a **`Phoenix.LiveView.JS`** struct.

#### String callbacks

String callbacks push the event to your LiveView with a standardized payload:

```elixir
# Accordion — on_value_change="accordion:change"
def handle_event("accordion:change", %{"id" => id, "value" => value, "action" => action}, socket)
```

| Key | Type | Description |
|-----|------|-------------|
| `id` | string | The component's DOM id |
| `value` | string or list | The affected item value(s) |
| `action` | `"open"` or `"close"` | What happened |

#### JS struct callbacks

Pass a `Phoenix.LiveView.JS` struct for client-side command chains without a server round-trip:

```heex
<.accordion
  id="faq"
  type="single"
  collapsible
  on_value_change={JS.dispatch("my-custom-event", to: "#analytics")}
/>
```

### Push Events (server -> client)

The server can command any interactive component via `push_event/3`:

```elixir
# Open a specific accordion item
push_event(socket, "phx_shadcn:command", %{id: "faq", command: "open", value: "q1"})

# Close it
push_event(socket, "phx_shadcn:command", %{id: "faq", command: "close", value: "q1"})

# Toggle
push_event(socket, "phx_shadcn:command", %{id: "faq", command: "toggle", value: "q1"})
```

### JS Commands (`PhxShadcn.JS`)

Control components from HEEx templates using chainable `%Phoenix.LiveView.JS{}` structs:

```elixir
alias PhxShadcn.JS, as: SJS

# Accordion / Collapsible
<button phx-click={SJS.open("my-accordion", "q1")}>Open Q1</button>
<button phx-click={SJS.close("my-accordion", "q1")}>Close Q1</button>

# Toggle / Switch
<button phx-click={SJS.press("bold-toggle")}>Press</button>
<button phx-click={SJS.toggle("my-switch")}>Toggle</button>

# Overlays
<button phx-click={SJS.show("my-dialog")}>Open Dialog</button>
<button phx-click={SJS.hide("my-popover")}>Close Popover</button>

# Chain with LiveView JS commands
<button phx-click={JS.push("track") |> SJS.open("faq", "q1")}>Track & Open</button>
```

### Vanilla JS Helpers

For non-LiveView JavaScript (Alpine, Stimulus, inline handlers):

```js
import { PhxShadcn } from "phx_shadcn/priv/static/phx-shadcn.js";

PhxShadcn.open("my-accordion", "q1")
PhxShadcn.press("bold-toggle")
PhxShadcn.show("my-dialog")
PhxShadcn.set("my-progress", 75)
```

### Custom Events (low-level)

Components listen for inbound events and emit outbound events:

```js
// Inbound (command)
el.dispatchEvent(new CustomEvent("phx-shadcn:open", { detail: { value: "q1" } }));

// Outbound (notification, past tense)
el.addEventListener("phx-shadcn:opened", (e) => {
  console.log("opened:", e.detail.id, e.detail.value);
});
```

## Class Overrides

All components use `cn()` (powered by TailwindMerge) — your `class` assign always wins:

```heex
<%!-- Your mt-8 overrides the component's default margin --%>
<.button class="mt-8">Click me</.button>

<%!-- Works with conditional classes too --%>
<.card class={["mt-4", @highlighted && "ring-2 ring-primary"]}>
  ...
</.card>
```

## License

MIT
