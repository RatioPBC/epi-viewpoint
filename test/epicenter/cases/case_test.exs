defmodule Epicenter.Cases.CaseTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Cases
  alias Epicenter.Cases.Case
  alias Epicenter.Test

  describe "new" do
    test "with a list of people" do
      alice = Test.Fixtures.person_attrs("alice", "01-01-2000") |> Cases.create_person!()
      billy = Test.Fixtures.person_attrs("billy", "01-02-2000") |> Cases.create_person!()

      [alice, billy]
      |> Case.new()
      |> assert_eq([
        %Case{dob: ~D[2000-01-01], first_name: "Alice", last_name: "Aliceblat"},
        %Case{dob: ~D[2000-01-02], first_name: "Billy", last_name: "Billyblat"}
      ])
    end
  end
end
