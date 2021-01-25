defmodule EpicenterWeb.Forms.ResolveConflictsFormTest do
  use Epicenter.SimpleCase, async: true

  import Epicenter.Test.ChangesetAssertions

  alias EpicenterWeb.Forms.ResolveConflictsForm

  describe "changeset validation" do
    test "is valid when there are no conflicts" do
      ResolveConflictsForm.changeset(%{first_name: [], dob: [], preferred_language: []}, %{})
      |> assert_valid()
    end

    test "requires a value for fields that have conflicts" do
      ResolveConflictsForm.changeset(%{first_name: ["a"], dob: [], preferred_language: ["b"]}, %{})
      |> assert_invalid(%{first_name: ["can't be blank"], preferred_language: ["can't be blank"]})
    end

    test "is valid when there are values for all fields that have conflicts" do
      ResolveConflictsForm.changeset(%{first_name: ["a"], dob: [], preferred_language: ["b"]}, %{first_name: "y", preferred_language: "z"})
      |> assert_valid()
    end
  end
end
