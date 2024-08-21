defmodule EpiViewpoint.Accounts.UserTokenTest do
  use EpiViewpoint.DataCase, async: true

  alias EpiViewpoint.Accounts.UserToken

  describe "token_validity_status" do
    test "with a new token" do
      now = DateTime.utc_now()
      before_now = now |> DateTime.add(-60 * 60, :second)
      after_now = now |> DateTime.add(60 * 60, :second)

      token = %UserToken{
        inserted_at: before_now,
        expires_at: after_now
      }

      assert UserToken.token_validity_status(token) == :valid
    end

    test "with a very old token that hasn't reached its expiration date" do
      now = DateTime.utc_now()

      longer_than_max_token_lifetime = UserToken.max_token_lifetime() + 1
      back_back_way_back = now |> DateTime.add(-longer_than_max_token_lifetime, :second)
      after_now = now |> DateTime.add(60 * 60, :second)

      token = %UserToken{
        inserted_at: back_back_way_back,
        expires_at: after_now
      }

      assert UserToken.token_validity_status(token) == :expired
    end

    test "with a relatively new token that has reached expiration time" do
      now = DateTime.utc_now()
      before_now = now |> DateTime.add(-60 * 60, :second)
      slighty_before_now = now |> DateTime.add(-1, :second)

      token = %UserToken{
        inserted_at: before_now,
        expires_at: slighty_before_now
      }

      assert UserToken.token_validity_status(token) == :expired
    end

    test "with a token that lacks an expiration time" do
      now = DateTime.utc_now()
      before_now = now |> DateTime.add(-60 * 60, :second)

      token = %UserToken{
        inserted_at: before_now,
        expires_at: nil
      }

      assert UserToken.token_validity_status(token) == :expired
    end
  end
end
