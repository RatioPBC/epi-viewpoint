defmodule EpicenterWeb.UserMfaController do
  use EpicenterWeb, :controller

  alias Epicenter.Accounts.MultifactorAuth

  @common_assigns [page_title: "Multi-factor authentication"]

  def new(conn, _params) do
    render_with_common_assigns(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"mfa" => %{"key" => encoded_secret, "totp" => totp}}) do
    case MultifactorAuth.check(encoded_secret, totp) do
      :ok -> conn |> redirect(to: Routes.root_path(conn, :show))
      {:error, message} -> conn |> render_with_common_assigns("new.html", error_message: message)
    end
  end

  defp render_with_common_assigns(conn, template, assigns) do
    {secret, key} = MultifactorAuth.generate_secret()
    uri = MultifactorAuth.auth_uri(conn.assigns.current_user, secret)
    svg = uri |> EQRCode.encode() |> EQRCode.svg(viewbox: true)

    render(conn, template, @common_assigns |> Keyword.merge(key: key, svg: svg) |> Keyword.merge(assigns))
  end
end
