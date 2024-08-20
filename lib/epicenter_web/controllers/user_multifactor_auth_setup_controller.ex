defmodule EpicenterWeb.UserMultifactorAuthSetupController do
  use EpicenterWeb, :controller
  import EpicenterWeb.ControllerHelpers, only: [assign_defaults: 1]

  alias Epicenter.Accounts
  alias Epicenter.Accounts.MultifactorAuth
  alias Epicenter.AuditLog
  alias EpicenterWeb.Session

  @common_assigns [page_title: "Multi-factor authentication"]

  def new(conn, _params),
    do: render_with_common_assigns(conn, "new.html", error_message: nil)

  def create(conn, %{"mfa" => %{"passcode" => passcode}}) do
    secret = Session.get_multifactor_auth_secret(conn)

    case MultifactorAuth.check(secret, passcode) do
      :ok ->
        user = conn.assigns.current_user

        user
        |> Accounts.update_user_mfa!(
          {MultifactorAuth.encode_secret(secret),
           %AuditLog.Meta{
             author_id: user.id,
             reason_action: AuditLog.Revision.update_user_mfa_action(),
             reason_event: AuditLog.Revision.update_user_mfa_event()
           }}
        )

        conn |> Session.put_multifactor_auth_success(true) |> redirect(to: ~p"/")

      {:error, message} ->
        conn
        |> put_flash(:error, "There was an error—see below")
        |> render_with_common_assigns("new.html", error_message: message)
    end
  end

  defp render_with_common_assigns(conn, template, assigns) do
    conn
    |> assign_defaults()
    |> Session.ensure_multifactor_auth_secret(if_nil: &MultifactorAuth.generate_secret/0)
    |> assign_multifactor_auth_key()
    |> assign_multifactor_qr_code_svg()
    |> merge_assigns(assigns)
    |> merge_assigns(@common_assigns)
    |> render(template)
  end

  defp assign_multifactor_auth_key(conn) do
    base_32_encoded_secret = conn |> Session.get_multifactor_auth_secret() |> MultifactorAuth.encode_secret()
    conn |> assign(:secret, base_32_encoded_secret)
  end

  defp assign_multifactor_qr_code_svg(conn) do
    secret = conn |> Session.get_multifactor_auth_secret()
    uri = MultifactorAuth.auth_uri(conn.assigns.current_user, secret)
    svg = uri |> EQRCode.encode() |> EQRCode.svg(viewbox: true)
    conn |> assign(:svg, svg)
  end
end
