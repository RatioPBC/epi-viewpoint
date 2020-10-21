defmodule EpicenterWeb.Test.Pages.ForbiddenError do
  import Phoenix.ConnTest

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> text_response(403) =~ "Forbidden"
  end
end
