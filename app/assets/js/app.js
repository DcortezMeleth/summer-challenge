// If you use a controller-based workflow, you'll need to import
// "phoenix_html" to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";

import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";

const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content");

const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
});

// Connect if any LiveViews are present on the page.
liveSocket.connect();

// Expose liveSocket on window for web console debugging.
window.liveSocket = liveSocket;


