defmodule EpicenterWeb.Unknown do
  @unknown_text "Unknown"

  def string_or_unknown(value, text \\ @unknown_text) do
    if Euclid.Exists.present?(value),
      do: value,
      else: unknown_value(text)
  end

  def list_or_unknown(values) do
    with true <- Euclid.Exists.present?(values),
         values <- Enum.filter(values, &Euclid.Exists.present?/1),
         true <- Euclid.Exists.present?(values) do
      Phoenix.HTML.Tag.content_tag :ul do
        Enum.map(values, &Phoenix.HTML.Tag.content_tag(:li, &1))
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
