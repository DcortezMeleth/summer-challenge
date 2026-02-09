// If you use a controller-based workflow, you'll need to import
// "phoenix_html" to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";

import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";

const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content");

// Custom hooks
const Hooks = {
  Flash: {
    mounted() {
      // Add fade-in animation
      this.el.classList.add("fade-in-scale");

      // Auto-dismiss after 10 seconds with animation
      this.timer = setTimeout(() => {
        this.dismiss();
      }, 10000);
    },

    destroyed() {
      // Clear timer if element is destroyed
      if (this.timer) {
        clearTimeout(this.timer);
      }
    },

    updated() {
      // Reset timer when flash is updated
      if (this.timer) {
        clearTimeout(this.timer);
      }
      this.timer = setTimeout(() => {
        this.dismiss();
      }, 10000);
    },

    dismiss() {
      // Clear timer
      if (this.timer) {
        clearTimeout(this.timer);
        this.timer = null;
      }

      // Add fade-out animation
      this.el.classList.add("fade-out-scale");

      // Remove element after animation completes
      setTimeout(() => {
        this.el.remove();
      }, 200); // Match the animation duration
    }
  }
};

const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: Hooks
});

// Connect if any LiveViews are present on the page.
liveSocket.connect();

// Expose liveSocket on window for web console debugging.
window.liveSocket = liveSocket;


