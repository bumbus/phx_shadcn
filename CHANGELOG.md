# Changelog

## v0.1.0 (2026-03-20)

Initial release.

### Components

**T1 — Static (15):**
Badge, Button, Card, Separator, Skeleton, Alert, Avatar, AspectRatio, Label,
Input, Textarea, Table, Breadcrumb, Pagination, Checkbox

**T2 — Interactive (11):**
Accordion, Collapsible, Tabs, Toggle, ToggleGroup, Switch, RadioGroup,
Progress, Slider, ScrollArea, Form + FormField

**T3 — Advanced (13):**
Dialog, AlertDialog, Sheet, Popover, Tooltip, HoverCard, DropdownMenu,
ContextMenu, Menubar, Select, InputOTP, Toast

### Hooks

22 JS hooks shipped in `priv/static/hooks/`:
Collapsible, Toggle, ToggleGroup, Switch, Tabs, Progress, RadioGroup, Slider,
ScrollArea, Dialog, Floating, RovingFocus, DropdownMenu, ContextMenu, Menubar,
Select, InputOTP, Toast, EventBridge

Vendored Floating UI (`priv/static/vendor/floating-ui.dom.esm.js`).

### Features

- 3-mode state ownership (client / hybrid / server) on all interactive components
- Form integration with hidden inputs and synthetic events
- TailwindMerge-based class overrides via `cn/1`
- `data-slot`, `data-variant`, `data-size` on every component
- `phx-click-loading` / `phx-submit-loading` styles baked in
- Custom event system with inbound/outbound bridging

### Known Issues

- Toast: swipe-to-dismiss can be finicky with 3+ simultaneous toasts
