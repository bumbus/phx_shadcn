import { PhxShadcnCollapsible } from "./collapsible.js";
import { PhxShadcnDialog } from "./dialog.js";
import { PhxShadcnContextMenu } from "./context-menu.js";
import { PhxShadcnDropdownMenu } from "./dropdown-menu.js";
import { PhxShadcnFloating } from "./floating.js";
import { PhxShadcnMenubar } from "./menubar.js";
import { PhxShadcnProgress } from "./progress.js";
import { PhxShadcnRovingFocus } from "./roving-focus.js";
import { PhxShadcnSwitch } from "./switch.js";
import { PhxShadcnTabs } from "./tabs.js";
import { PhxShadcnToggle } from "./toggle.js";
import { PhxShadcnRadioGroup } from "./radio-group.js";
import { PhxShadcnToggleGroup } from "./toggle-group.js";
import { PhxShadcnScrollArea } from "./scroll-area.js";
import { PhxShadcnSlider } from "./slider.js";
import { PhxShadcnSelect } from "./select.js";
import { PhxShadcnInputOTP } from "./input-otp.js";
import { PhxShadcnToast } from "./toast.js";

// Individual named exports (for selective import)
export { PhxShadcnCollapsible, PhxShadcnContextMenu, PhxShadcnDialog, PhxShadcnDropdownMenu, PhxShadcnFloating, PhxShadcnInputOTP, PhxShadcnMenubar, PhxShadcnProgress, PhxShadcnRadioGroup, PhxShadcnRovingFocus, PhxShadcnScrollArea, PhxShadcnSelect, PhxShadcnSlider, PhxShadcnToast, PhxShadcnSwitch, PhxShadcnTabs, PhxShadcnToggle, PhxShadcnToggleGroup };

// All hooks as a single object (for easy spread into LiveSocket)
export const hooks = { PhxShadcnCollapsible, PhxShadcnContextMenu, PhxShadcnDialog, PhxShadcnDropdownMenu, PhxShadcnFloating, PhxShadcnInputOTP, PhxShadcnMenubar, PhxShadcnProgress, PhxShadcnRadioGroup, PhxShadcnRovingFocus, PhxShadcnScrollArea, PhxShadcnSelect, PhxShadcnSlider, PhxShadcnToast, PhxShadcnSwitch, PhxShadcnTabs, PhxShadcnToggle, PhxShadcnToggleGroup };

// Utilities
export { isJsCommand, notifyServer, listenForCommands, syncFormInput } from "./event-bridge.js";

// Vanilla JS helpers (re-export for convenience)
export { PhxShadcn } from "../phx-shadcn.js";
