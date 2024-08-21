defmodule EpiViewpoint.Accounts.MultifactorAuthTest do
  use EpiViewpoint.SimpleCase, async: true

  import Mox
  setup :verify_on_exit!

  alias EpiViewpoint.Accounts.MultifactorAuth
  alias EpiViewpoint.Test

  @secret Test.TOTPStub.raw_secret()

  setup do
    stub_with(Test.TOTPMock, Test.TOTPStub)
    :ok
  end

  describe "check_totp" do
    test "returns :ok when the passcode matches the secret" do
      MultifactorAuth.check(@secret, "123456") |> assert_eq(:ok)
    end

    test "returns :ok when the passcode matches the secret but with spaces and stuff" do
      MultifactorAuth.check(@secret, " 123456 ") |> assert_eq(:ok)
      MultifactorAuth.check(@secret, " 123 456 ") |> assert_eq(:ok)
      MultifactorAuth.check(@secret, " 123-456 ") |> assert_eq(:ok)
    end

    test "returns :error when the passcode is not 6 numbers" do
      MultifactorAuth.check(@secret, "12345")
      |> assert_eq({:error, "The six-digit code must be exactly 6 numbers"})

      MultifactorAuth.check(@secret, "1234567")
      |> assert_eq({:error, "The six-digit code must be exactly 6 numbers"})

      MultifactorAuth.check(@secret, "1X3X56")
      |> assert_eq({:error, "The six-digit code must be exactly 6 numbers"})
    end

    test "returns :error when the passcode does not match the secret" do
      MultifactorAuth.check(@secret, "000000")
      |> assert_eq({:error, "The six-digit code was incorrect"})
    end
  end
end
