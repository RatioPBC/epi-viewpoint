defmodule Epicenter.Cases.CaseTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Cases
  alias Epicenter.Cases.Case
  alias Epicenter.Test

  describe "new" do
    test "with a list of people" do
      alice = Test.Fixtures.person_attrs("alice", "06-01-2020") |> Cases.create_person!()
      billy = Test.Fixtures.person_attrs("billy", "06-02-2020") |> Cases.create_person!()

      [alice, billy]
      |> Case.new()
      |> assert_eq([
        %Case{dob: ~D[2020-06-01], first_name: "Alice", last_name: "Aliceblat"},
        %Case{dob: ~D[2020-06-02], first_name: "Billy", last_name: "Billyblat"}
      ])
    end
  end
end
