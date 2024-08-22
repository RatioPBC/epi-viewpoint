defmodule EpiViewpointWeb.Test.Pages.Root do
  alias EpiViewpointWeb.Test.Pages

  def visit(%Plug.Conn{} = conn) do
    conn |> Pages.visit("/", :follow_redirect)
  end
end
