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

  describe "latest_result" do
    setup %{} do
      person = @admin |> Test.Fixtures.person_attrs("person") |> Cases.create_person!()

      [person: person]
    end

    test "when the person has no lab results", %{person: person} do
      person = person |> Cases.preload_lab_results()
      assert PeoplePresenter.latest_result(person) == ""
    end

    test "when there is a result and a sample date", %{person: person} do
      Test.Fixtures.lab_result_attrs(person, @admin, "lab-result", ~D[2020-01-01], result: "positive") |> Cases.create_lab_result!()
      person = person |> Cases.preload_lab_results()
      assert PeoplePresenter.latest_result(person) =~ ~r|positive, \d+ days ago|
    end

    test "when there is a lab result and a sample date, but the lab result lacks a result value", %{person: person} do
      Test.Fixtures.lab_result_attrs(person, @admin, "lab-result", ~D[2020-01-01], result: nil) |> Cases.create_lab_result!()
      person = person |> Cases.preload_lab_results()
      assert PeoplePresenter.latest_result(person) =~ ~r|unknown, \d+ days ago|
    end

    test "when there is a result and no sample date", %{person: person} do
      Test.Fixtures.lab_result_attrs(person, @admin, "lab-result", nil, result: "positive") |> Cases.create_lab_result!()
      person = person |> Cases.preload_lab_results()
      assert PeoplePresenter.latest_result(person) =~ ~r|positive, unknown date|
    end

    test "when there is a lab result and no result or sample date", %{person: person} do
      Test.Fixtures.lab_result_attrs(person, @admin, "lab-result", nil, result: nil) |> Cases.create_lab_result!()
      person = person |> Cases.preload_lab_results()
      assert PeoplePresenter.latest_result(person) =~ ~r|unknown, unknown date|
    end
  end
end
