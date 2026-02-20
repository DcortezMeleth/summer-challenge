import "phoenix_html";

import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";

const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content");

const Hooks = {
  Flash: {
    mounted() {
      this.el.classList.add("fade-in-scale");
      this.timer = setTimeout(() => {
        this.dismiss();
      }, 10000);
    },

    destroyed() {
      if (this.timer) {
        clearTimeout(this.timer);
      }
    },

    updated() {
      if (this.timer) {
        clearTimeout(this.timer);
      }
      this.timer = setTimeout(() => {
        this.dismiss();
      }, 10000);
    },

    dismiss() {
      if (this.timer) {
        clearTimeout(this.timer);
        this.timer = null;
      }
      this.el.classList.add("fade-out-scale");
      setTimeout(() => {
        this.el.remove();
      }, 200);
    }
  }
};

const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: Hooks
});

liveSocket.connect();

window.liveSocket = liveSocket;
