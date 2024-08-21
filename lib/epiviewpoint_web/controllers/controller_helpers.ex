defmodule EpiViewpointWeb.ControllerHelpers do
  @default_assigns [body_class: "body-background-none", show_nav: true]

  def assign_defaults(%Plug.Conn{} = conn, overrides \\ []) do
    new_assigns =
      @default_assigns
      |> Keyword.merge(overrides)
      |> Enum.reject(fn {key, _value} -> Map.has_key?(conn.assigns, key) end)

    Plug.Conn.merge_assigns(conn, new_assigns)
  end
end
