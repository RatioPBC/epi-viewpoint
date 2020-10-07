defmodule Epicenter.Accounts.UserTokenTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Accounts
  alias Epicenter.Accounts.UserToken
  alias Epicenter.Test

  describe "token_validity_status" do
    test "with a new token" do
      now = NaiveDateTime.local_now()
      before_now = now |> NaiveDateTime.add(-60 * 60, :second)
      after_now = now |> NaiveDateTime.add(60 * 60, :second)

      token = %UserToken{
        inserted_at: before_now,
        expires_at: after_now
      }

      assert UserToken.token_validity_status(token) == :valid
    end

    test "with a very old token that hasn't reached its expiration date" do
      now = NaiveDateTime.local_now()
      longer_than_max_token_lifetime = UserToken.max_token_lifetime() + 1
      back_back_way_back = now |> NaiveDateTime.add(-longer_than_max_token_lifetime, :second)
      after_now = now |> NaiveDateTime.add(60 * 60, :second)

      token = %UserToken{
        inserted_at: back_back_way_back,
        expires_at: after_now
      }

      assert UserToken.token_validity_status(token) == :expired
    end

    test "with a relatively new token that has reached expiration time" do
      now = NaiveDateTime.local_now()
      before_now = now |> NaiveDateTime.add(-60 * 60, :second)
      slighty_before_now = now |> NaiveDateTime.add(-1, :second)

      token = %UserToken{
        inserted_at: before_now,
        expires_at: slighty_before_now
      }

      assert UserToken.token_validity_status(token) == :expired
    end
  end
end
