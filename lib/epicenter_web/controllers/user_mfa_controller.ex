defmodule EpicenterWeb.UserMfaController do
  use EpicenterWeb, :controller

  alias Epicenter.Accounts.MultifactorAuth
  alias EpicenterWeb.Session

  @common_assigns [page_title: "Multi-factor authentication"]

  def new(conn, _params) do
    render_with_common_assigns(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"mfa" => %{"totp" => totp}}) do
    {_secret, key} = Session.get_multifactor_auth_secret(conn)

    case MultifactorAuth.check(key, totp) do
      :ok -> conn |> redirect(to: Routes.root_path(conn, :show))
      {:error, message} -> conn |> render_with_common_assigns("new.html", error_message: message)
    end
  end

  defp render_with_common_assigns(conn, template, assigns) do
    conn
    |> Session.ensure_multifactor_auth_secret(if_nil: &MultifactorAuth.generate_secret/0)
    |> assign_multifactor_auth_key()
    |> assign_multifactor_qr_code_svg()
    |> merge_assigns(assigns)
    |> merge_assigns(@common_assigns)
    |> render(template)
  end

  defp assign_multifactor_auth_key(conn) do
    {_secret, key} = conn |> Session.get_multifactor_auth_secret()
    conn |> assign(:key, key)
  end

  defp assign_multifactor_qr_code_svg(conn) do
    {secret, _key} = conn |> Session.get_multifactor_auth_secret()
    uri = MultifactorAuth.auth_uri(conn.assigns.current_user, secret)
    svg = uri |> EQRCode.encode() |> EQRCode.svg(viewbox: true)
    conn |> assign(:svg, svg)
  end
end
