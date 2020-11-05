/*
 * Prototype for a simple autocomplete with keyboard accessibility.
 * Relies on LiveView for populating results.
 */
Hooks.AutocompleteInput = {
  mounted() {
    this.el.addEventListener("keyup", (e) => {
      switch (e.code) {
        case "ArrowLeft":
        case "ArrowRight":
        case "ArrowUp":
        case "Escape":
        case "Shift":
        case "Space":
          // ignore
          break;

        case "ArrowDown":
          let listbox = this.el.parentNode.querySelector("[role=listbox]");
          let firstItem = listbox.children[0];
          firstItem.focus();
          firstItem.setAttribute("aria-selected", "true");
          break;

        default:
          break;
      }
    });
  }
};

Hooks.AutocompleteList = {
  mounted() {
    document.addEventListener("keydown", (e) => {
      let listbox = document.querySelector("[role=listbox]");
      if (listbox && listbox.hasChildNodes()) {
        if (["ArrowUp", "ArrowDown"].indexOf(e.code) > -1) {
          e.preventDefault();
        }
      }
    });

    document.addEventListener("click", (e) => {
      if (e.target.getAttribute("role") !== "option") {
        while (this.el.firstChild) {
          this.el.removeChild(this.el.firstChild);
        }
      }
    });

    this.el.addEventListener("keyup", (e) => {
      let select = function (listbox, direction) {
        let selectedItem = listbox.querySelector("[aria-selected=true]");
        let toSelect;

        if (direction === "down") {
          toSelect = selectedItem.nextElementSibling;
        } else {
          toSelect = selectedItem.previousElementSibling;
        }

        if (toSelect) {
          selectedItem.setAttribute("aria-selected", "false");
          toSelect.focus();
          toSelect.setAttribute("aria-selected", "true");
        }

        e.preventDefault();
        e.stopPropagation();
      };

      switch (e.code) {
        case "ArrowDown":
          select(this.el, "down");
          break;

        case "ArrowUp":
          select(this.el, "up");
          break;

        case "Enter":
          this.el.querySelector("[aria-selected=true]").click();
          break;

        default:
          break;
      }
    });
  }
};
