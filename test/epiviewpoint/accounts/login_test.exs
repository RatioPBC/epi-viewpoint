defmodule EpiViewpoint.Accounts.LoginTest do
  use EpiViewpoint.DataCase, async: true

  alias EpiViewpoint.Accounts
  alias EpiViewpoint.Accounts.Login

  describe "schema" do
    test "fields" do
      assert_schema(
        Login,
        [
          {:id, :binary_id},
          {:inserted_at, :utc_datetime},
          {:seq, :integer},
          {:session_id, :binary_id},
          {:tid, :string},
          {:updated_at, :utc_datetime},
          {:user_agent, :string},
          {:user_id, :binary_id}
        ]
      )
    end
  end

  describe "changeset" do
    defp new_changeset(attr_updates \\ []) do
      default_attrs = %{
        session_id: "session_id",
        user_agent: "best-browser",
        user_id: "user_id"
      }

      Accounts.change_login(Map.merge(default_attrs, attr_updates |> Enum.into(%{})))
    end

    test "creating log with all required fields", do: assert_valid(new_changeset())
    test "user_id is required", do: assert_invalid(new_changeset(user_id: nil))
    test "session_id is required", do: assert_invalid(new_changeset(session_id: nil))
  end
end
