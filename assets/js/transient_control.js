export let TransientControl = {
  setup() {
    const elements = TransientControl.elements();

    if (elements.length > 0) {
      elements.forEach(function (element) {
        element.addEventListener("click", TransientControl.toggleActivation)
      });

      document.addEventListener("click", TransientControl.deactivate);
    }
  },

  toggleActivation(event) {
    event.stopPropagation();
    if (this.dataset.active === "true") {
      delete this.dataset.active;
    } else {
      this.dataset.active = "true";
    }
  },

  deactivate() {
    TransientControl.elements().forEach(function (element) {
      delete element.dataset.active;
    });
  },

  elements() {
    return document.querySelectorAll("[data-transient-control] button");
  }
};


