defmodule Epicenter.Extra.ChangesetTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.Extra.Changeset

  describe "clear_validation_errors" do
    test "drops errors from top level changes" do
      %Ecto.Changeset{errors: [address: {"can't be blank", [validation: :required]}]}
      |> Changeset.clear_validation_errors()
      |> assert_eq(%Ecto.Changeset{errors: []}, :simple)
    end

    test "drops errors from child changeset" do
      %Ecto.Changeset{
        errors: [first_name: {"can't be blank", [validation: :required]}],
        changes: %{
          language: %Ecto.Changeset{errors: [name: {"can't be blank", [validation: :required]}]}
        }
      }
      |> Changeset.clear_validation_errors()
      |> assert_eq(%Ecto.Changeset{errors: [], changes: %{language: %Ecto.Changeset{errors: []}}}, :simple)
    end

    test "drops errors from list of child changesets" do
      %Ecto.Changeset{
        errors: [first_name: {"can't be blank", [validation: :required]}],
        changes: %{
          emails: [
            %Ecto.Changeset{errors: [name: {"can't be blank", [validation: :required]}]},
            %Ecto.Changeset{errors: [name: {"can't be blank", [validation: :required]}]}
          ],
          foo: [1, 2]
        }
      }
      |> Changeset.clear_validation_errors()
      |> assert_eq(%Ecto.Changeset{errors: [], changes: %{emails: [%Ecto.Changeset{errors: []}, %Ecto.Changeset{errors: []}], foo: [1, 2]}}, :simple)
    end
  end
end
