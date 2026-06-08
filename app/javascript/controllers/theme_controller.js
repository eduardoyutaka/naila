import { Controller } from "@hotwired/stimulus"

// Toggles the light/dark theme by adding/removing `.dark` on <html>, persists the
// choice to localStorage, and dispatches a `theme:changed` event so canvas-based
// widgets (ECharts charts, the OpenLayers map) can re-render with the new palette.
//
// Default is light. An inline script in the admin layout <head> applies the saved
// choice before first paint to avoid a flash of the wrong theme. Sun/moon icons in
// the button switch purely via CSS (`dark:` variants) — no JS needed for icon state.
export default class extends Controller {
  toggle() {
    const isDark = document.documentElement.classList.toggle("dark")
    try {
      localStorage.setItem("theme", isDark ? "dark" : "light")
    } catch (e) {
      // localStorage unavailable (private mode) — theme still applies for this page.
    }
    window.dispatchEvent(new CustomEvent("theme:changed", { detail: { theme: isDark ? "dark" : "light" } }))
  }
}
