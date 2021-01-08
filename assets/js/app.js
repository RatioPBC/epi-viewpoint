// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.sass";

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"

//
// User menu
//
import { TransientControl } from "./transient_control";
document.addEventListener("DOMContentLoaded", TransientControl.setup);

//
// LiveView
//
import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket, Browser } from "phoenix_live_view";

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: {
    BodyClass: {
      mounted() {
        document.getElementsByTagName("body")[0].className = this.el.dataset.bodyClass;
      }
    },
    CopyToClipboard: {
      mounted() {
        this.el.addEventListener("click", (event) => {
          const input = document.querySelector(`input[value="${this.el.dataset.clipboardValue}"]`);
          if (input) {
            input.select();
            input.setSelectionRange(0, input.value.length);
            document.execCommand("copy");
            document.activeElement.blur();
            window.getSelection().removeAllRanges();
          }
        });
      }
    },
    TransientControlHook: {
      mounted() {
        TransientControl.setup();
      }
    }
  },
  params: { _csrf_token: csrfToken }
});

window.addEventListener("phx:page-loading-stop", (info) => {
  let hashEl = Browser.getHashTargetEl(window.location.hash);
  if (hashEl) {
    hashEl.scrollIntoView();
  }
});

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

document.body.addEventListener(
  "phoenix.link.click",
  function (e) {
    if (e.target.dataset["phxLink"] !== "redirect") return true;
    var message = document
      .querySelector("[data-confirm-navigation]")
      ?.getAttribute("data-confirm-navigation");
    if (!message) {
      return true;
    }
    if (!window.confirm(message)) {
      e.preventDefault();
    }
  },
  false
);
