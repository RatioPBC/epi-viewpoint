import { describe, test } from "@jest/globals";
import { MultiselectHook } from "../js/multiselect";

function buildContainer(html) {
  const template = document.createElement("template");
  template.innerHTML = html.trim();
  return template.content.firstChild;
}

function values(container) {
  return childValues(container, {});
}

function childValues(node, acc) {
  if (node.hasChildNodes()) {
    return Array.from(node.childNodes).reduce((acc, child) => {
      if (child.tagName === "INPUT") {
        acc[child.value] = child.checked;
      }
      Object.assign(acc, childValues(child, {}));
      return acc;
    }, acc);
  } else {
    return acc;
  }
}

function inputWithValue(container, type, value) {
  return container.querySelector(`input[type=${type}][value=${value}]`);
}

function isChecked(container, type, value) {
  return inputWithValue(container, type, value).checked;
}

function isDisabled(container, type, value) {
  return inputWithValue(container, type, value).disabled;
}

describe("radioWasClicked", () => {
  test("unchecks siblings", () => {
    let container = buildContainer(`
      <div data-multiselect="container">
        <label data-multiselect="parent"><input data-multiselect-parent-id type="radio" value="r1"></label>
        <label data-multiselect="parent"><input data-multiselect-parent-id type="radio" value="r2" checked></label>
        <label data-multiselect="parent"><input data-multiselect-parent-id type="checkbox" value="c1" checked></label>
      </div>
      `);

    expect(isChecked(container, "radio", "r2")).toBe(true);
    expect(isChecked(container, "checkbox", "c1")).toBe(true);

    MultiselectHook.radioWasClicked(container, null, inputWithValue(container, "radio", "r1"));

    expect(isChecked(container, "radio", "r2")).toBe(false);
    expect(isChecked(container, "checkbox", "c1")).toBe(false);
  });

  test("enables its 'other' text field, and disables siblings' 'other' text fields", () => {
    let container = buildContainer(`
      <div data-multiselect="container">
        <label data-multiselect="parent">
          <input id="form_r1" data-multiselect-parent-id type="radio" value="r1">
          <div><input data-multiselect-parent-id="form_r1" disabled type="text" value="r1"></div>
        </label>
        
        <label data-multiselect="parent">
          <input id="form_r2" data-multiselect-parent-id type="radio" value="r2">
          <div><input data-multiselect-parent-id="form_r2" type="text" value="r2"></div>
        </label>
      </div>
      `);

    expect(isDisabled(container, "text", "r1")).toBe(true);
    expect(isDisabled(container, "text", "r2")).toBe(false);

    MultiselectHook.radioWasClicked(container, null, inputWithValue(container, "radio", "r1"));

    expect(isDisabled(container, "text", "r1")).toBe(false);
    expect(isDisabled(container, "text", "r2")).toBe(true);
  });
});
