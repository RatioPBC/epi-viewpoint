defmodule EpicenterWeb.Test.Pages.MfaSetup do
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  def assert_here(view_or_conn_or_html),
    do: view_or_conn_or_html |> Pages.assert_on_page("mfa-setup")

  def submit_passcode(conn, passcode \\ :default) do
    passcode = if passcode == :default, do: Test.TOTPStub.valid_passcode(), else: passcode
    conn |> Pages.submit_form(:post, "new-mfa-form", "mfa", %{"passcode" => passcode})
  end
end
