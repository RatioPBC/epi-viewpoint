defmodule Epicenter.Cases.CaseTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Cases.Case
  alias Epicenter.Test

  describe "new" do
    test "with a list of people, creates cases with person and lab_results" do
      user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      Test.Fixtures.lab_result_attrs(alice, "alice_result_1", "06-01-2020", result: "negative") |> Cases.create_lab_result!()
      Test.Fixtures.lab_result_attrs(alice, "alice_result_2", "06-02-2020", result: "positive") |> Cases.create_lab_result!()

      billy = Test.Fixtures.person_attrs(user, "billy") |> Cases.create_person!()
      Test.Fixtures.lab_result_attrs(billy, "billy_result_1", "07-01-2020", result: "negative") |> Cases.create_lab_result!()

      [alice, billy]
      |> Case.new()
      |> assert_eq([
        %Case{
          dob: ~D[2000-01-01],
          first_name: "Alice",
          last_name: "Testuser",
          latest_result: "positive",
          latest_sample_date: ~D[2020-06-02],
          tid: "alice"
        },
        %Case{
          dob: ~D[2000-01-01],
          first_name: "Billy",
          last_name: "Testuser",
          latest_result: "negative",
          latest_sample_date: ~D[2020-07-01],
          tid: "billy"
        }
      ])
    end

    test "does not blow up if the person has no lab results" do
      user = Test.Fixtures.user_attrs("user") |> Accounts.create_user!()
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()

      assert Case.new(alice) == %Case{
               dob: ~D[2000-01-01],
               first_name: "Alice",
               last_name: "Testuser",
               latest_result: nil,
               latest_sample_date: nil,
               tid: "alice"
             }
    end
  end
end
