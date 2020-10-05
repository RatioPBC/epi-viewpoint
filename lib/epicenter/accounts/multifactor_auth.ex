defmodule Epicenter.Accounts.MultifactorAuth do
  @totp Application.compile_env(:epicenter, :totp, Epicenter.Accounts.TOTP)
  @issuer Application.compile_env(:epicenter, :mfa_issuer, "Viewpoint")

  alias Epicenter.Accounts.User
  alias Epicenter.Extra

  def auth_uri(%User{email: email}, secret),
    do: @totp.otpauth_uri("Viewpoint:#{email}", secret, issuer: @issuer)

  def check(secret, passcode) when is_binary(secret) and is_binary(passcode) do
    passcode = Extra.String.remove_non_numbers(passcode)

    if String.length(passcode) == 6 do
      if @totp.valid?(secret, passcode),
        do: :ok,
        else: {:error, "The six-digit code was incorrect"}
    else
      {:error, "The six-digit code must be exactly 6 numbers"}
    end
  end

  def decode_secret(base_32_encoded_secret),
    do: base_32_encoded_secret |> Base.decode32()

  def encode_secret(secret),
    do: secret |> Base.encode32(padding: false)

  def generate_secret(),
    do: @totp.secret()
end
