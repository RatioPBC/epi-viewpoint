defmodule EpicenterWeb.Presenters.PeoplePresenterTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Test

  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.Presenters.PeoplePresenter

  @admin Test.Fixtures.admin()

  describe "full_name" do
    defp wrap(demo_attrs) do
      {:ok, person} = Test.Fixtures.person_attrs(@admin, "test") |> Test.Fixtures.add_demographic_attrs(demo_attrs) |> Cases.create_person()
      person
    end

    test "renders first and last name",
      do: assert(PeoplePresenter.full_name(wrap(%{first_name: "First", last_name: "TestuserLast"})) == "First TestuserLast")

    test "when there's just a first name",
      do: assert(PeoplePresenter.full_name(wrap(%{first_name: "First", last_name: nil})) == "First")

    test "when there's just a last name",
      do: assert(PeoplePresenter.full_name(wrap(%{first_name: nil, last_name: "TestuserLast"})) == "TestuserLast")

    test "when first name is blank",
      do: assert(PeoplePresenter.full_name(wrap(%{first_name: "", last_name: "TestuserLast"})) == "TestuserLast")
  end
end
