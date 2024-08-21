defmodule EpiViewpointWeb.Unknown do
  @unknown_text "Unknown"

  def string_or_unknown(value, opts \\ []) do
    transform_fun = Keyword.get(opts, :transform, &Function.identity/1)
    unknown_text = Keyword.get(opts, :unknown_text, @unknown_text)

    if Euclid.Exists.present?(value),
      do: value |> transform_fun.(),
      else: unknown_value(unknown_text)
  end

  def list_or_unknown(values, opts \\ []) do
    pre_fun = Keyword.get(opts, :pre, &Function.identity/1)
    post_fun = Keyword.get(opts, :post, &Function.identity/1)
    transform_fun = Keyword.get(opts, :transform, &Function.identity/1)
    unknown_text = Keyword.get(opts, :unknown_text, @unknown_text)

    with true <- Euclid.Exists.present?(values),
         values <- Enum.filter(values, &Euclid.Exists.present?/1),
         true <- Euclid.Exists.present?(values) do
      PhoenixHTMLHelpers.Tag.content_tag :ul do
        values
        |> pre_fun.()
        |> Enum.map(transform_fun)
        |> post_fun.()
        |> Enum.map(&PhoenixHTMLHelpers.Tag.content_tag(:li, &1))
      end
    else
      _ ->
        unknown_value(unknown_text)
    end
  end

  def unknown_value(text \\ @unknown_text) do
    PhoenixHTMLHelpers.Tag.content_tag(:span, text, class: "unknown")
  end
end
