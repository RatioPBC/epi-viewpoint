defmodule EpicenterWeb.UserMultifactorAuthController do
  use EpicenterWeb, :controller

  import EpicenterWeb.ControllerHelpers, only: [assign_defaults: 2]

  alias Epicenter.Accounts
  alias EpicenterWeb.Session

  @common_assigns [
    body_class: "body-background-color",
    page_title: "Multi-factor auth",
    show_nav: false
  ]

  def new(conn, _params),
    do: conn |> assign_defaults(@common_assigns) |> render("new.html", error_message: nil)

  def create(conn, %{"user" => %{"passcode" => passcode}}) do
    user = conn.assigns.current_user

    {:ok, decoded_secret} = Accounts.MultifactorAuth.decode_secret(user.mfa_secret)
    user_return_to = get_session(conn, :user_return_to)

    case Accounts.MultifactorAuth.check(decoded_secret, passcode) do
      :ok ->
        conn |> Session.put_multifactor_auth_success(true) |> redirect(to: user_return_to || "/")

      {:error, message} ->
        conn |> assign_defaults(@common_assigns) |> render("new.html", error_message: message)
    end
  end
end
