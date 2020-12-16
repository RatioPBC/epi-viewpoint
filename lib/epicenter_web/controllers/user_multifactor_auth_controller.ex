defmodule EpicenterWeb.UserMultifactorAuthController do
  use EpicenterWeb, :controller

  alias Epicenter.Accounts
  alias EpicenterWeb.Session

  @common_assigns [body_class: "body-background-color", page_title: "Multi-factor auth", show_nav: false]

  def new(conn, _params),
    do: render_with_common_assigns(conn, "new.html", error_message: nil)

  def create(conn, %{"user" => %{"passcode" => passcode}}) do
    user = conn.assigns.current_user

    {:ok, decoded_secret} = Accounts.MultifactorAuth.decode_secret(user.mfa_secret)
    user_return_to = get_session(conn, :user_return_to)

    case Accounts.MultifactorAuth.check(decoded_secret, passcode) do
      :ok -> conn |> Session.put_multifactor_auth_success(true) |> redirect(to: user_return_to || "/")
      {:error, message} -> render_with_common_assigns(conn, "new.html", error_message: message)
    end
  end

  defp render_with_common_assigns(conn, template, assigns),
    do: render(conn, template, Keyword.merge(@common_assigns, assigns))
end
