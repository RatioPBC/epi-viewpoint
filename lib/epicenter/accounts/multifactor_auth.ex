defmodule Epicenter.Accounts.MultifactorAuth do
  @totp Application.compile_env(:epicenter, :totp, Epicenter.Accounts.TOTP)

  alias Epicenter.Accounts.User

  def auth_uri(%User{email: email}, secret) do
    @totp.otpauth_uri("Viewpoint:#{email}", secret, issuer: "Viewpoint")
  end

  def check(encoded_secret, one_time_password)
      when is_binary(encoded_secret) and is_binary(one_time_password) do
    with {:decode_secret, {:ok, secret}} when is_binary(secret) <- {:decode_secret, Base.decode32(encoded_secret)},
         {:check_length, one_time_password} when byte_size(one_time_password) == 6 <- {:check_length, one_time_password},
         {:parse_totp, {integer, _}} when is_integer(integer) <- {:parse_totp, Integer.parse(one_time_password)},
         {:validate_totp, true} <- {:validate_totp, @totp.valid?(secret, one_time_password)} do
      :ok
    else
      {:decode_secret, _} -> {:error, "Internal error"}
      {:check_length, _} -> {:error, "The six-digit code must be exactly 6 numbers"}
      {:parse_totp, _} -> {:error, "The six-digit code must only contain numbers"}
      {:validate_totp, _} -> {:error, "The six-digit code was incorrect"}
    end
  end

  def generate_secret() do
    secret = @totp.secret()
    encoded_secret = Base.encode32(secret, padding: false)
    {secret, encoded_secret}
  end
end
