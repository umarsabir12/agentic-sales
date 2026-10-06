import { Controller } from "@hotwired/stimulus"

// Switches between the light and dark theme. The choice is kept in a cookie so the
// server renders the right theme on the next page load (no flash of the wrong theme).
export default class extends Controller {
  toggle() {
    const root = document.documentElement
    const theme = root.dataset.theme === "dark" ? "light" : "dark"
    root.dataset.theme = theme
    document.cookie = `theme=${theme}; path=/; max-age=31536000; samesite=lax`
  }
}
