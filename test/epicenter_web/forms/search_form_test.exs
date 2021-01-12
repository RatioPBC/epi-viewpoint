defmodule EpicenterWeb.Forms.SearchFormTest do
  use Epicenter.DataCase, async: true

  alias EpicenterWeb.Forms.SearchForm

  describe "changeset" do
    test "term is required" do
      assert_invalid(SearchForm.changeset(%SearchForm{}, %{term: nil}))
    end
  end
end
