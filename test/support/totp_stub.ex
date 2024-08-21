defmodule EpiViewpoint.Test.TOTPStub do
  @behaviour EpiViewpoint.Accounts.TOTP

  def raw_secret, do: <<244, 132, 168, 148, 98, 100, 231, 92, 100, 208>>
  def encoded_secret, do: Base.encode32(raw_secret(), padding: false)
  def valid_passcode, do: "123456"

  def otpauth_uri(_label, secret, _uri_params),
    do: "otpauth://totp/test?#{Base.encode32(secret, padding: false)}"

  def secret(),
    do: raw_secret()

  def valid?(secret, passcode),
    do: secret == raw_secret() && passcode == valid_passcode()
end
