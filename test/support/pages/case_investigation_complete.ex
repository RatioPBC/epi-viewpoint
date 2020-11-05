defmodule EpicenterWeb.Test.Pages.CaseInvestigationComplete do

  alias EpicenterWeb.Test.Pages

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("case-investigation-complete")
  end
end
