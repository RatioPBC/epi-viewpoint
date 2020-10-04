defmodule Epicenter.Accounts.MultifactorAuthTest do
  use Epicenter.SimpleCase, async: true

  import Mox
  setup :verify_on_exit!

  alias Epicenter.Accounts.MultifactorAuth
  alias Epicenter.Test

  @secret Test.TOTPStub.raw_secret()

  setup do
    stub_with(Test.TOTPMock, Test.TOTPStub)
    :ok
  end

  describe "check_totp" do
    test "returns :ok when the totp matches the secret" do
      MultifactorAuth.check(@secret, "123456")
      |> assert_eq(:ok)
    end

    test "returns :error when the totp is not 6 characters" do
      MultifactorAuth.check(@secret, "12345")
      |> assert_eq({:error, "The six-digit code must be exactly 6 numbers"})

      MultifactorAuth.check(@secret, "1234567")
      |> assert_eq({:error, "The six-digit code must be exactly 6 numbers"})
    end

    test "returns :error when the totp is not a number" do
      MultifactorAuth.check(@secret, "Z23456")
      |> assert_eq({:error, "The six-digit code must only contain numbers"})
    end

    test "returns :error when the top does not match the secret" do
      MultifactorAuth.check(@secret, "000000")
      |> assert_eq({:error, "The six-digit code was incorrect"})
    end
  end
end
