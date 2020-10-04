defmodule Epicenter.Accounts.TOTP do
  @callback otpauth_uri(binary(), binary(), list()) :: binary()
  def otpauth_uri(label, secret, uri_params),
    do: NimbleTOTP.otpauth_uri(label, secret, uri_params)

  @callback secret() :: binary()
  def secret(),
    do: NimbleTOTP.secret()

  @callback valid?(binary(), binary()) :: boolean()
  def valid?(secret, otp),
    do: NimbleTOTP.valid?(secret, otp)
end
