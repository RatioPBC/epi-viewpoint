defmodule EpiViewpointWeb.Presenters.LabResultPresenterTest do
  use EpiViewpoint.DataCase, async: true

  alias EpiViewpoint.Cases
  alias EpiViewpoint.Test
  alias EpiViewpointWeb.Presenters.LabResultPresenter

  @admin Test.Fixtures.admin()

  describe "latest_positive" do
    setup do
      person = @admin |> Test.Fixtures.person_attrs("person") |> Cases.create_person!()

      [person: person]
    end

    test "when the person has no positive lab results", %{person: person} do
      Test.Fixtures.lab_result_attrs(person, @admin, "lab-result", ~D[2020-01-01], result: nil) |> Cases.create_lab_result!()
      person = person |> Cases.preload_lab_results()
      assert LabResultPresenter.latest_positive(person.lab_results) == ""
    end

    test "when there is a result and a sample date", %{person: person} do
      Test.Fixtures.lab_result_attrs(person, @admin, "lab-result", ~D[2020-01-01], result: "positive") |> Cases.create_lab_result!()
      person = person |> Cases.preload_lab_results()
      assert LabResultPresenter.latest_positive(person.lab_results) == "01/01/2020"
    end

    test "when there is a result and no sample date", %{person: person} do
      Test.Fixtures.lab_result_attrs(person, @admin, "lab-result", nil, result: "positive") |> Cases.create_lab_result!()
      person = person |> Cases.preload_lab_results()
      assert LabResultPresenter.latest_positive(person.lab_results) == "Unknown date"
    end
  end
end
