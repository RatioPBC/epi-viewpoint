export let TransientControl = {
  setup() {
    const elements = document.querySelectorAll("[data-transient-control] button");

    if (elements.length > 0) {
      elements.forEach(function (element) {
        element.addEventListener("click", function (event) {
          event.stopPropagation();
          if (element.dataset.active === "true") {
            delete element.dataset.active;
          } else {
            element.dataset.active = "true";
          }
        });
      });

      document.addEventListener("click", function (event) {
        elements.forEach(function (element) {
          delete element.dataset.active;
        });
      });
    }
  }
};
