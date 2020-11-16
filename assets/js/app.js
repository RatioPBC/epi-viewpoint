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
import { UserMenu } from "./user_menu";
document.addEventListener("DOMContentLoaded", UserMenu.setup);

//
// LiveView
//
import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket, Browser } from "phoenix_live_view";
import { MultiselectHook } from "./multiselect";

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: {
    Multiselect: MultiselectHook
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

document.body.addEventListener('phoenix.link.click', function (e) {
  if (e.target.dataset["phx-link"] !== "redirect") return true;
  var message = document.querySelector("[data-confirm-navigation]")?.getAttribute("data-confirm-navigation");
  if (!message) { return true; }
  if (!window.confirm(message)) {
    e.preventDefault();
  }
}, false);