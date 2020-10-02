defmodule EpicenterWeb.Test.Pages.Root do
  alias EpicenterWeb.Test.Pages

  def visit(%Plug.Conn{} = conn) do
    conn |> Pages.visit("/", :follow_redirect)
  end
end
