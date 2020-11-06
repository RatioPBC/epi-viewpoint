export let MultiselectHook = {
  mounted() {
    this.el.addEventListener("change", (e) => {
      const container = e.target.closest("[data-multiselect=container]");
      const parent = document.getElementById(e.target.getAttribute("data-multiselect-parent-id"));

      switch (e.target.getAttribute("type")) {
        case "checkbox":
          this.checkboxWasClicked(container, parent, e.target);
          break;

        case "radio":
          this.radioWasClicked(container, parent, e.target);
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
      if (input === radio) {
        this.enableChildTextField(container, input);
      } else {
        input.checked = false;
        this.disableChildTextField(container, input);
        this.uncheckAllChildren(container, input);
      }
    });
  },

  // // //

  checkboxWasChecked(container, parent, checkbox) {
    if (parent) {
      parent.checked = true;
    }

    this.enableChildTextField(container, checkbox);

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
    this.disableChildTextField(container, checkbox);
    this.uncheckAllChildren(container, checkbox);
  },

  // // //

  disableChildTextField(container, parent) {
    this.forEachChild(container, parent, "[type=text]", (child) => (child.disabled = true));
  },

  enableChildTextField(container, parent) {
    this.forEachChild(container, parent, "[type=text]", (child) => (child.disabled = false));
  },

  uncheckAllChildren(container, parent) {
    this.forEachChild(container, parent, "", (child) => (child.checked = false));
  },

  // // //

  forEachChild(container, parent, attributeSelector, callback) {
    if (parent) {
      container
        .querySelectorAll(`input${attributeSelector}[data-multiselect-parent-id=${parent.id}]`)
        .forEach(callback);
    }
  },

  topLevelInputs(container) {
    return container.querySelectorAll(
      "input[type=checkbox][data-multiselect-parent-id=''], input[type=radio][data-multiselect-parent-id='']"
    );
  }
};
