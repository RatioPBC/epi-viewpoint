export let MultiselectHook = {
  mounted() {
    this.el.addEventListener("change", (e) => {
      const container = e.target.closest("[data-multiselect=container]");
      const parent = document.getElementById(e.target.getAttribute("data-multiselect-parent-id"));

      switch (e.target.getAttribute("type")) {
        case "radio":
          this.radioWasClicked(container, parent, e.target);
          break;

        case "checkbox":
          this.checkboxWasClicked(container, parent, e.target);
          break;
      }
    });
  },

  checkboxWasClicked(container, parent, checkbox) {
    if (checkbox.checked) {
      this.checkboxWasChecked(container, parent, checkbox);
    } else {
      this.checkboxWasUnchecked(container, parent, checkbox);
    }
  },

  radioWasClicked(container, _parent, radio) {
    this.topLevelInputs(container).forEach((input) => {
      if (input !== radio) {
        input.checked = false;
        this.uncheckAllChildren(container, input);
      }
    });
  },

  // // //

  checkboxWasChecked(container, parent, _checkbox) {
    if (parent) {
      parent.checked = true;
    }

    container.querySelectorAll("input[type=radio]").forEach((radio) => {
      if (radio === parent) {
        radio.checked = true;
      } else {
        radio.checked = false;
        this.uncheckAllChildren(container, radio);
      }
    });
  },

  checkboxWasUnchecked(container, _parent, checkbox) {
    this.uncheckAllChildren(container, checkbox);
  },

  // // //

  topLevelInputs(container) {
    return container.querySelectorAll(
      "input[type=checkbox][data-multiselect-parent-id=''], input[type=radio][data-multiselect-parent-id='']"
    );
  },

  uncheckAllChildren(container, parent) {
    if (parent) {
      container
        .querySelectorAll(`input[data-multiselect-parent-id=${parent.id}]`)
        .forEach((child) => (child.checked = false));
    }
  }
};
