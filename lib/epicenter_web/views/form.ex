defmodule EpicenterWeb.Form do
  use Phoenix.HTML

  import EpicenterWeb.ErrorHelpers
  import EpicenterWeb.FormHelpers

  alias EpicenterWeb.FormHelpers

  alias EpicenterWeb.Form

  defstruct ~w{f safe}a

  defmodule Line do
    defstruct ~w{column f safe}a
  end

  def new(f),
    do: %Form{f: f, safe: []}

  def safe(%Form{safe: safe}),
    do: {:safe, safe}

  def line(%Form{} = form, fun) do
    line = %Line{column: 1, f: form.f, safe: []} |> fun.()
    %{form | safe: merge_safe(form.safe, content_tag(:fieldset, line.safe))}
  end

  # # #

  def checkbox_list_field(%Form.Line{f: f} = line, field, name, values, span \\ 2) do
    [
      label(f, field, name, data: grid_data(1, line, span)),
      error_tag(f, field, data: grid_data(2, line, span)),
      checkbox_list(f, field, values, data: grid_data(3, line, span))
    ]
    |> add_to_line(line, span)
  end

  def content_div(%Form.Line{} = line, content, span \\ 2) do
    [
      content_tag(:div, content, data: grid_data(1, line, span)),
    ]
    |> add_to_line(line, span)
  end

  def date_field(%Form.Line{f: f} = line, field, name, span \\ 2) do
    [
      label(f, field, name, data: grid_data(1, line, span)),
      content_tag(:div, "MM/DD/YYYY", data: grid_data(2, line, span)),
      error_tag(f, field, data: grid_data(3, line, span)),
      text_input(f, field, data: grid_data(4, line, span))
    ]
    |> add_to_line(line, span)
  end

  def footer(%Form.Line{} = line, error_message, span \\ 2) do
    content_tag :footer do
      [
        submit("Save"),
        content_tag(:div, error_message, class: "form-error-message", "data-form-error-message": error_message)
      ]
    end
    |> add_to_line(line, span)
  end

  def radio_button_list(%Form.Line{f: f} = line, field, name, values, opts \\ [], span \\ 2) do
    [
      label(f, field, name, data: grid_data(1, line, span)),
      error_tag(f, field, data: grid_data(2, line, span)),
      FormHelpers.radio_button_list(f, field, values, opts, data: grid_data(3, line, span))
    ]
    |> add_to_line(line, span)
  end

  def save_button(%Form.Line{} = line, span \\ 2) do
    submit("Save", data: grid_data(1, line, span))
    |> add_to_line(line, span)
  end

  def select(%Form.Line{f: f} = line, field, name, options, span \\ 2) do
    [
      label(f, field, name, data: grid_data(1, line, span)),
      error_tag(f, field, data: grid_data(2, line, span)),
      FormHelpers.select_with_wrapper(f, field, options, data: grid_data(3, line, span))
    ]
    |> add_to_line(line, span)
  end

  def text_field(%Form.Line{f: f} = line, field, name, span \\ 2) do
    [
      label(f, field, name, data: grid_data(1, line, span)),
      error_tag(f, field, data: grid_data(2, line, span)),
      text_input(f, field, data: grid_data(3, line, span))
    ]
    |> add_to_line(line, span)
  end

  # # #

  defp grid_data(row, %Form.Line{column: column}, span),
    do: [grid: [row: row, col: column, span: span]]

  defp add_to_line(contents, %Form.Line{column: column, safe: safe} = line, span),
    do: %{line | column: column + span, safe: safe ++ contents}

  defp merge_safe({:safe, left}, {:safe, right}), do: left ++ right
  defp merge_safe(left, {:safe, right}), do: left ++ right
  defp merge_safe({:safe, left}, right), do: left ++ right
end
