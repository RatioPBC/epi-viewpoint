defmodule Epicenter.Extra.ChangesetTest do
  use Epicenter.SimpleCase, async: true

  import Ecto.Changeset
  alias Epicenter.Extra.Changeset

  defmodule Post do
    use Ecto.Schema

    schema "posts" do
      field :title, :string
      field :body, :string
    end
  end

  defp changeset(%Post{} = schema, params),
    do: cast(schema, params, ~w(title body)a)

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
          foo_should_not_change: [1, 2]
        }
      }
      |> Changeset.clear_validation_errors()
      |> assert_eq(
        %Ecto.Changeset{errors: [], changes: %{emails: [%Ecto.Changeset{errors: []}, %Ecto.Changeset{errors: []}], foo_should_not_change: [1, 2]}},
        :simple
      )
    end
  end

  test "get_field_from_changeset" do
    changeset = changeset(%Post{body: "bar"}, %{"title" => "foo"})

    assert Changeset.get_field_from_changeset(changeset, :title) == "foo"
    assert Changeset.get_field_from_changeset(changeset, :body) == "bar"
  end

  test "rewrite_changeset_error_message" do
    %Ecto.Changeset{
      errors: [
        dob: {"is invalid", [type: :date, validation: :cast]},
        address: {"can't be blank", [validation: :required]}
      ]
    }
    |> Changeset.rewrite_changeset_error_message(:dob, "please enter dates as mm/dd/yyyy")
    |> assert_eq(
      %Ecto.Changeset{
        errors: [
          dob: {"please enter dates as mm/dd/yyyy", [type: :date, validation: :cast]},
          address: {"can't be blank", [validation: :required]}
        ]
      },
      :simple
    )
  end
end
