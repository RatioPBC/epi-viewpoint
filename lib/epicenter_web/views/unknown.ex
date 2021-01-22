defmodule EpicenterWeb.Unknown do
  @unknown_text "Unknown"

  def string_or_unknown(value, text \\ @unknown_text) do
    if Euclid.Exists.present?(value),
      do: value,
      else: unknown_value(text)
  end

  def list_or_unknown(values, opts \\ []) do
    pre_fun = Keyword.get(opts, :pre, &Function.identity/1)
    post_fun = Keyword.get(opts, :post, &Function.identity/1)
    transform_fun = Keyword.get(opts, :transform, &Function.identity/1)

    with true <- Euclid.Exists.present?(values),
         values <- Enum.filter(values, &Euclid.Exists.present?/1),
         true <- Euclid.Exists.present?(values) do
      Phoenix.HTML.Tag.content_tag :ul do
        values
        |> pre_fun.()
        |> Enum.map(transform_fun)
        |> post_fun.()
        |> Enum.map(&Phoenix.HTML.Tag.content_tag(:li, &1))
      end
    else
      _ ->
        unknown_value()
    end
  end

  def unknown_value(text \\ @unknown_text) do
    Phoenix.HTML.Tag.content_tag(:span, text, class: "unknown")
  end
end
