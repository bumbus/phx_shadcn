/**
 * Event bridge — shared utilities for hook ↔ LiveView communication.
 *
 * Every interactive hook imports these helpers instead of calling
 * pushEvent / execJS / handleEvent directly.
 */

/**
 * Detect whether a string is a serialized Phoenix.LiveView.JS struct.
 * JS structs serialize to JSON arrays like `[["push",{...}]]` in data attrs.
 */
export function isJsCommand(str) {
  return typeof str === "string" && str.trimStart().startsWith("[[");
}

/**
 * Notify the server (or execute a JS command) after a state change.
 *
 * - String callback → pushEvent with payload
 * - JS struct callback → execJS (user controls the entire command chain)
 */
export function notifyServer(hook, callbackStr, payload) {
  if (!callbackStr) return;

  if (isJsCommand(callbackStr)) {
    hook.liveSocket.execJS(hook.el, callbackStr);
  } else {
    hook.pushEvent(callbackStr, payload);
  }
}

/**
 * Register a handleEvent listener for server→client push_event commands.
 *
 * Server sends: push_event(socket, "phx_shadcn:command", %{id: "faq", command: "open", value: "q1"})
 * Only processes commands targeting this hook's element (matched by id).
 */
export function listenForCommands(hook, handler) {
  hook.handleEvent("phx_shadcn:command", (payload) => {
    if (payload.id === hook.el.id) {
      handler(payload);
    }
  });
}

/**
 * Sync hidden form input(s) and dispatch synthetic `input` events
 * so that `phx-change` on a parent <form> fires.
 *
 * Accepts a scalar value (single input) or an array (one input per value).
 */
export function syncFormInput(el, value) {
  const values = Array.isArray(value) ? value : [value];
  const inputs = el.querySelectorAll("input[type='hidden']");
  values.forEach((val, i) => {
    if (inputs[i]) {
      inputs[i].value = val;
      inputs[i].dispatchEvent(new Event("input", { bubbles: true }));
    }
  });
}
