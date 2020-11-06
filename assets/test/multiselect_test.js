import { describe, test } from "@jest/globals";
import { MultiselectHook } from "../js/multiselect";

function buildContainer(html) {
  const template = document.createElement("template");
  template.innerHTML = html.trim();
  return template.content.firstChild;
}

function areChecked(container, ...typesAndValues) {
  return typesAndValues.map(([type, value]) => isChecked(container, type, value));
}

function areDisabled(container, ...typesAndValues) {
  return typesAndValues.map(([type, value]) => isDisabled(container, type, value));
}

function isChecked(container, type, value) {
  return inputWithValue(container, type, value).checked;
}

function isDisabled(container, type, value) {
  return inputWithValue(container, type, value).disabled;
}

function inputWithValue(container, type, value) {
  return container.querySelector(`input[type=${type}][value="${value}"]`);
}

function expectChange(value, before, action, after) {
  expect(value()).toStrictEqual(before);
  action();
  expect(value()).toStrictEqual(after);
}

describe("checkboxWasChecked", () => {
  test("checks parent", () => {
    let container = buildContainer(`
      <div data-multiselect="container">
        <label data-multiselect="parent"><input id="c1" data-multiselect-parent-id type="checkbox" value="c1"></label>
        <label data-multiselect="child"><input data-multiselect-parent-id="c1" type="checkbox" value="c1.1"></label>
      </div>
      `);

    const parent = inputWithValue(container, "checkbox", "c1");
    const checkbox = inputWithValue(container, "checkbox", "c1.1");

    expectChange(
      () => isChecked(container, "checkbox", "c1"),
      false,
      () => MultiselectHook.checkboxWasChecked(container, parent, checkbox),
      true
    );
  });

  test("enables its 'other' text field", () => {
    let container = buildContainer(`
      <div data-multiselect="container">
        <label data-multiselect="parent">
          <input id="form_r1" data-multiselect-parent-id type="checkbox" value="c1">
          <div><input data-multiselect-parent-id="form_r1" disabled type="text" value="r1"></div>
        </label>
      </div>
      `);

    const checkbox = inputWithValue(container, "checkbox", "c1");

    expectChange(
      () => isDisabled(container, "text", "r1"),
      true,
      () => MultiselectHook.checkboxWasChecked(container, parent, checkbox),
      false
    );
  });

  test("checks its parent radio button and unchecks other radio buttons and their children", () => {
    let container = buildContainer(`
      <div data-multiselect="container">
        <label data-multiselect="parent"><input id="r1" data-multiselect-parent-id type="radio" value="r1"></label>
        <label data-multiselect="parent"><input data-multiselect-parent-id="r1" type="checkbox" value="c1"></label>
        <label data-multiselect="parent"><input id="r2" data-multiselect-parent-id type="radio" value="r2" checked></label>
        <label data-multiselect="parent"><input data-multiselect-parent-id="r2" type="checkbox" value="c2" checked></label>
      </div>
      `);

    const c1 = inputWithValue(container, "checkbox", "c1");
    const parent = inputWithValue(container, "radio", "r1");

    expectChange(
      () => areChecked(container, ["radio", "r1"], ["radio", "r2"], ["checkbox", "c2"]),
      [false, true, true],
      () => MultiselectHook.checkboxWasChecked(container, parent, c1),
      [true, false, false]
    );
  });
});

describe("checkboxWasUnchecked", () => {
  test("disables its 'other' text field", () => {
    let container = buildContainer(`
      <div data-multiselect="container">
        <label data-multiselect="parent">
          <input id="form_r1" data-multiselect-parent-id type="checkbox" value="c1" checked>
          <div><input data-multiselect-parent-id="form_r1" type="text" value="r1"></div>
        </label>
      </div>
      `);

    const checkbox = inputWithValue(container, "checkbox", "c1");

    expectChange(
      () => isDisabled(container, "text", "r1"),
      false,
      () => MultiselectHook.checkboxWasUnchecked(container, parent, checkbox),
      true
    );
  });

  test("unchecks all of its children", () => {
    let container = buildContainer(`
      <div data-multiselect="container">
        <label data-multiselect="parent"><input id="c1" data-multiselect-parent-id type="checkbox" value="c1" checked></label>
        <label data-multiselect="parent"><input data-multiselect-parent-id="c1" type="checkbox" value="c1.1" checked></label>
        <label data-multiselect="parent"><input id="c2" data-multiselect-parent-id type="checkbox" value="c2" checked></label>
        <label data-multiselect="parent"><input data-multiselect-parent-id="c2" type="checkbox" value="c2.1" checked></label>
      </div>
      `);

    const c1 = inputWithValue(container, "checkbox", "c1");

    expectChange(
      () => areChecked(container, ["checkbox", "c1.1"], ["checkbox", "c2"], ["checkbox", "c2.1"]),
      [true, true, true],
      () => MultiselectHook.checkboxWasUnchecked(container, null, c1),
      [false, true, true]
    );
  });
});

describe("radioWasClicked", () => {
  test("unchecks siblings", () => {
    let container = buildContainer(`
      <div data-multiselect="container">
        <label data-multiselect="parent"><input data-multiselect-parent-id type="radio" value="r1"></label>
        <label data-multiselect="parent"><input data-multiselect-parent-id type="radio" value="r2" checked></label>
        <label data-multiselect="parent"><input data-multiselect-parent-id type="checkbox" value="c1" checked></label>
      </div>
      `);

    const r1 = inputWithValue(container, "radio", "r1");

    expectChange(
      () => areChecked(container, ["radio", "r2"], ["checkbox", "c1"]),
      [true, true],
      () => MultiselectHook.radioWasClicked(container, null, r1),
      [false, false]
    );
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

    const r1 = inputWithValue(container, "radio", "r1");

    expectChange(
      () => areDisabled(container, ["text", "r1"], ["text", "r2"]),
      [true, false],
      () => MultiselectHook.radioWasClicked(container, null, r1),
      [false, true]
    );
  });
});
