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
document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll("#user-menu").forEach((userMenu) => {
    userMenu.addEventListener("click", (event) => {
      let target = document.querySelector("#user-menu-list");
      target.style.display = target.style.display === "block" ? "none" : "block";
    });
  });

  document.addEventListener("click", (e) => {
    document.querySelectorAll("#user-menu").forEach((userMenu) => {
      if (!userMenu.contains(e.target)) {
        document.querySelectorAll("[role=menu]").forEach((menu) => {
          if (menu.style.display === "block") {
            menu.style.display = "none";
          }
        });
      }
    });
  });
});

//
// LiveView
//
import "phoenix_html";
import { Socket } from "phoenix";
import NProgress from "nprogress";
import { LiveSocket, Browser } from "phoenix_live_view";

let Hooks = {};

Hooks.Multiselect = {
  mounted() {}
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
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
