defmodule Epicenter.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Epicenter.Accounts` context.
  """

  alias Epicenter.Accounts
  alias Epicenter.Test

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "password123"

  def user_fixture(attrs \\ %{}) do
    Test.Fixtures.user_attrs("user", attrs) |> Accounts.register_user!()
  end

  def extract_user_token(fun) do
    {:ok, captured} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token, _] = String.split(captured.body, "[TOKEN]")
    token
  end
end
