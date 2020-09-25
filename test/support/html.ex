defmodule Epicenter.Test.Html do
  def all(html, css_query, as: :text) when not is_binary(html),
    do: html |> all(css_query, &Floki.text/1)

  def all(html, css_query, as: :tids) when not is_binary(html),
    do: html |> all(css_query, &tid/1) |> List.flatten()

  def all(html, css_query, attr: attr) when not is_binary(html),
    do: html |> all(css_query, &Floki.attribute(&1, attr)) |> List.flatten()

  def all(html, css_query, fun) when not is_binary(html) and is_function(fun),
    do: html |> Floki.find(css_query) |> Enum.map(fun)

  def attr(html, css_query \\ "*", attr_name) when not is_binary(html),
    do: html |> Floki.attribute(css_query, attr_name)

  def has_role?(html, role),
    do: html |> Floki.find("[data-role=#{role}]") |> Euclid.Exists.present?()

  def html(html, css_query) when not is_binary(html),
    do: html |> Floki.find(css_query) |> Enum.map(&Floki.raw_html/1)

  def meta_contents(html, name) when not is_binary(html),
    do: html |> Floki.attribute("meta[name=#{name}]", "content") |> Enum.join("")

  def parse(html_string),
    do: html_string |> Floki.parse_fragment!()

  def parse_doc(html_string),
    do: html_string |> Floki.parse_document!()

  def page_title(html) when not is_binary(html),
    do: html |> html("title") |> Euclid.Extra.Enum.first!() |> parse() |> Floki.text()

  def role_text(html, role),
    do: html |> text("[data-role=#{role}]")

  def role_texts(html, role),
    do: html |> all("[data-role=#{role}]", as: :text)

  def text(html) when not is_binary(html) or is_tuple(html),
    do: html |> Floki.text(sep: " ")

  def text(html, css_query) when not is_binary(html),
    do: html |> Floki.find(css_query) |> Floki.text()

  defp tid(html),
    do: html |> Floki.attribute("data-tid")
end
