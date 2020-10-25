defmodule EpicenterWeb.FormHelpers do
  use Phoenix.HTML

  @doc """
  Returns an HTML element that contains a list of checkboxes to be used as a multi-select for a single form field.
  Automatically marks the appropriate checkboxes as checked based on the values in the form data.
  """
  def checkbox_list(form, field, values, html_opts \\ []) when is_list(values) do
    opts = [class: "checkbox-list"] |> Keyword.merge(html_opts)

    content_tag :div, opts do
      for value <- values do
        label do
          [checkbox_list_checkbox(form, field, value), " ", value]
        end
      end
    end
  end

  @doc """
  Returns a checkbox that is meant to be part of a multi-select checkbox control.
  Automatically marks the checkbox as checked if its value is in the form data's list of values.
  """
  def checkbox_list_checkbox(form, field, value) do
    checkbox(
      form,
      field,
      name: checkbox_list_input_name(form, field),
      checked: value in input_value(form, field),
      checked_value: value,
      hidden_input: false
    )
  end

  @doc """
  Returns an input name meant for each checkbox in a list of checkboxes.
  Just appends `[]` to whatever `Phoenix.HTML.Form.input_name` returns.
  """
  def checkbox_list_input_name(form, field) do
    input_name(form, field) <> "[]"
  end

  @doc """
  Returns an HTML element that contains a list of radio buttons.
  Automatically marks the appropriate radio button as checked based on the value in the form data.
  """
  def radio_button_list(form, field, values, html_opts) when is_list(values) do
    opts = [class: "radio-button-list"] |> Keyword.merge(html_opts)

    content_tag :div, opts do
      for value <- values do
        label do
          [radio_button(form, field, value), " ", value]
        end
      end
    end
  end
end
