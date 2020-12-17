defmodule EpicenterWeb.Form do
  use Phoenix.HTML

  import EpicenterWeb.ErrorHelpers

  alias EpicenterWeb.Form
  alias EpicenterWeb.FormHelpers
  alias EpicenterWeb.Multiselect

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

  @doc "opts: span"
  def content_div(%Form.Line{} = line, content, opts \\ []) do
    [content_tag(:div, content, data: grid_data(line, opts))]
    |> add_to_line(line, opts)
  end

  @doc "opts: span"
  def date_field(%Form.Line{f: f} = line, field, label_text, opts \\ []) do
    [
      label(f, field, label_text, data: grid_data(1, line, opts)),
      content_tag(:div, date_explanation_text(opts), data: grid_data(2, line, opts)),
      error_tag(f, field, data: grid_data(3, line, opts)),
      text_input(f, field, data: grid_data(4, line, opts))
    ]
    |> add_to_line(line, opts)
  end

  defp date_explanation_text(opts) do
    explanation_text = Keyword.get(opts, :explanation_text, "MM/DD/YYYY")
    attributes = Keyword.get(opts, :attributes, [])
    text_to_html(explanation_text, wrapper_tag: :div, attributes: attributes)
  end

  @doc "opts: span"
  def footer(%Form.Line{} = line, error_message, opts \\ []) do
    opts = opts |> Keyword.put_new(:span, 8)

    content_tag :footer, data: grid_data(1, line, opts) ++ [sticky: Keyword.get(opts, :sticky, false)] do
      [
        content_tag(:div, id: "form-footer-content") do
          [
            submit("Save"),
            content_tag(:div, error_message, class: "form-error-message", data: [form_error_message: error_message])
          ]
        end
      ]
    end
    |> add_to_line(line, Keyword.put_new(opts, :span, 8))
  end

  @doc """
  Creates a multiselect that can contain inputs that are checkboxes and/or radio buttons.
  Any of the inputs can have an associated free text field for "other value" functionality.
  Any of the top-level inputs can also have a list of children.

  The `values` parameter is a list of tuples in the form {type, label, value} or {type, label, value, [children]},
  where `children` is another list of tuples.

  `type` can be: `:checkbox`, `:radio`, `:other_checkbox`, or `:other_radio`

  The form field ecto type can be: `:string` (for radios), `{:array, :string}` (for checkboxes),
  or `:map` (for fields with children or with an "other" field). When it's a map, it should be
  in the shape returned by `MajorDetailed.for_form`. When putting the resulting data into a model,
  use `MajorDetailed.for_model(:map)` if the model's ecto type is `:map`, or `MajorDetailed.for_model(:list)`
  if the model's ecto type is `{:array, :string}`.

  ## Options

    * `:span` - the number of grid columns the field should span
  """
  def multiselect(%Form.Line{f: f} = line, field, label_text, specs, opts \\ []) do
    [
      label(f, field, label_text, data: grid_data(1, line, opts)),
      error_tag(f, field, data: grid_data(2, line, opts)),
      content_tag(
        :div,
        Multiselect.multiselect_inputs(f, field, specs, nil),
        data: grid_data(3, line, opts) ++ [multiselect: "container"]
      )
    ]
    |> add_to_line(line, opts)
  end

  @doc "opts: other, span"
  def radio_button_list(%Form.Line{f: f} = line, field, label_text, values, opts \\ []) do
    [
      label(f, field, label_text, data: grid_data(1, line, opts)),
      error_tag(f, field, data: grid_data(2, line, opts)),
      FormHelpers.radio_button_list(f, field, values, opts, data: grid_data(3, line, opts))
    ]
    |> add_to_line(line, opts)
  end

  @doc "opts: span"
  def checkbox_field(%Form.Line{f: f} = line, field, label_text, checkbox_text, opts \\ []) do
    label = if label_text, do: [label([data: grid_data(1, line, opts)], do: [label_text])], else: []

    (label ++
       [
         error_tag(f, field, data: grid_data(2, line, opts)),
         label(f, field, data: grid_data(3, line, opts), class: "checkbox-label") do
           [
             checkbox(f, field),
             checkbox_text
           ]
         end
       ])
    |> add_to_line(line, opts)
  end

  @doc "opts: other, span"
  def checkbox_list(%Form.Line{f: f} = line, field, label_text, values, opts \\ []) do
    [
      label(f, field, label_text, data: grid_data(1, line, opts)),
      error_tag(f, field, data: grid_data(2, line, opts)),
      FormHelpers.checkbox_list(f, field, values, opts, data: grid_data(3, line, opts))
    ]
    |> add_to_line(line, opts)
  end

  @doc "opts: span, sticky"
  def save_button(%Form.Line{} = line, opts \\ []) do
    data_opts = grid_data(1, line, opts) |> Keyword.put(:role, "save-button")

    submit("Save", data: data_opts)
    |> add_to_line(line, opts)
  end

  @doc "opts: span"
  def select(%Form.Line{f: f} = line, field, label_text, options, opts \\ []) do
    [
      label(f, field, label_text, data: grid_data(1, line, opts)),
      error_tag(f, field, data: grid_data(2, line, opts)),
      FormHelpers.select_with_wrapper(f, field, options, data: grid_data(3, line, opts))
    ]
    |> add_to_line(line, opts)
  end

  @doc "opts: span"
  def textarea_field(%Form.Line{f: f} = line, field, label_text, opts \\ []) do
    [
      label(f, field, label_text, data: grid_data(1, line, opts)),
      error_tag(f, field, data: grid_data(2, line, opts)),
      textarea(f, field, rows: Keyword.get(opts, :rows, 4), data: grid_data(3, line, opts), placeholder: Keyword.get(opts, :placeholder))
    ]
    |> add_to_line(line, opts)
  end

  @doc "opts: span"
  def text_field(%Form.Line{f: f} = line, field, label_text, opts \\ []) do
    [
      label(f, field, label_text, data: grid_data(1, line, opts)),
      error_tag(f, field, data: grid_data(2, line, opts)),
      text_input(f, field, data: grid_data(3, line, opts))
    ]
    |> add_to_line(line, opts)
  end

  def hidden_field(%Form.Line{f: f} = line, field) do
    [
      hidden_input(f, field)
    ]
    |> add_to_line(line, [])
  end

  # # #

  defp grid_data(row, %Form.Line{column: column}, opts),
    do: [grid: [row: row, col: column, span: Keyword.get(opts, :span, 2)]]

  defp grid_data(%Form.Line{column: column}, opts),
    do: [grid: [row: Keyword.get(opts, :row, 1), col: column, span: Keyword.get(opts, :span, 2)]]

  defp add_to_line(contents, %Form.Line{column: column, safe: safe} = line, opts),
    do: %{line | column: column + Keyword.get(opts, :span, 2), safe: safe ++ contents}

  defp merge_safe({:safe, left}, {:safe, right}), do: left ++ right
  defp merge_safe(left, {:safe, right}), do: left ++ right
  defp merge_safe({:safe, left}, right), do: left ++ right
end
