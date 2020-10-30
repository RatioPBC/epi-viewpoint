defmodule Epicenter.Test.Html do
  def all(html, css_query, as: :text) when not is_binary(html),
    do: html |> all(css_query, &Floki.text/1)

  def all(html, css_query, as: :tids) when not is_binary(html),
    do: html |> all(css_query, &tid/1) |> List.flatten()

  def all(html, css_query, attr: attr) when not is_binary(html),
    do: html |> all(css_query, &Floki.attribute(&1, Euclid.Extra.Atom.to_string(attr))) |> List.flatten()

  def all(html, css_query, fun) when not is_binary(html) and is_function(fun),
    do: html |> find(css_query) |> Enum.map(fun)

  def attr(html, css_query \\ "*", attr_name) when not is_binary(html),
    do: html |> Floki.attribute(css_query, attr_name)

  def find(html, css_query) when not is_binary(html),
    do: html |> Floki.find(css_query)

  def find!(html, css_query) when not is_binary(html),
    do: html |> find(css_query) |> assert_found(html, css_query)

  def has_role?(html, role),
    do: html |> find("[data-role=#{role}]") |> Euclid.Exists.present?()

  def html(html) when not is_binary(html),
    do: html |> Floki.raw_html()

  def html(html, css_query) when not is_binary(html),
    do: html |> find(css_query) |> Enum.map(&Floki.raw_html/1)

  def meta_contents(html, name) when not is_binary(html),
    do: html |> Floki.attribute("meta[name=#{name}]", "content") |> Enum.join("")

  def normalize(html_string) when is_binary(html_string),
    do: html_string |> parse() |> Floki.raw_html()

  def parse(html_string),
    do: html_string |> Floki.parse_fragment!()

  def parse_doc(html_string),
    do: html_string |> Floki.parse_document!()

  def page_title(html) when not is_binary(html),
    do: html |> html("title") |> Euclid.Extra.Enum.first!() |> parse() |> Floki.text()

  def present?(html, role: role) when not is_binary(html),
    do: html |> find("[data-role=#{role}]") |> Euclid.Exists.present?()

  def role_text(html, role),
    do: html |> text("[data-role=#{role}]")

  def role_texts(html, role),
    do: html |> all("[data-role=#{role}]", as: :text)

  def text(html) when not is_binary(html) or is_tuple(html),
    do: html |> Floki.text(sep: " ")

  def text(html, role: role) when not is_binary(html),
    do: html |> text("[data-role=#{role}]")

  def text(html, css_query) when not is_binary(html),
    do: html |> find(css_query) |> Floki.text()

  def tid(html),
    do: html |> Floki.attribute("data-tid")

  # # #

  defp assert_found([], html, css_query),
    do: raise("CSS query “#{css_query}” did not find anything in: \n\n#{Floki.raw_html(html)}")

  defp assert_found(found, _html, _css_query),
    do: found
end
