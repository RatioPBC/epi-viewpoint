defmodule Epicenter.Cases.CaseTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Cases
  alias Epicenter.Cases.Case
  alias Epicenter.Test

  describe "new" do
    test "with a list of people, creates cases with person and lab_results" do
      alice = Test.Fixtures.person_attrs("alice", "01-01-2000") |> Cases.create_person!()
      Test.Fixtures.lab_result_attrs(alice, "alice_result_1", "06-01-2020", result: "negative") |> Cases.create_lab_result!()
      Test.Fixtures.lab_result_attrs(alice, "alice_result_2", "06-02-2020", result: "positive") |> Cases.create_lab_result!()

      billy = Test.Fixtures.person_attrs("billy", "01-02-2000") |> Cases.create_person!()
      Test.Fixtures.lab_result_attrs(billy, "billy_result_1", "07-01-2020", result: "negative") |> Cases.create_lab_result!()

      [alice, billy]
      |> Case.new()
      |> assert_eq([
        %Case{dob: ~D[2000-01-01], first_name: "Alice", last_name: "Aliceblat", latest_result: "positive", latest_sample_date: ~D[2020-06-02]},
        %Case{dob: ~D[2000-01-02], first_name: "Billy", last_name: "Billyblat", latest_result: "negative", latest_sample_date: ~D[2020-07-01]}
      ])
    end
  end
end
