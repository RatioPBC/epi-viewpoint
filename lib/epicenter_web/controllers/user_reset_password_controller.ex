defmodule EpicenterWeb.UserResetPasswordController do
  use EpicenterWeb, :controller

  import EpicenterWeb.ControllerHelpers, only: [assign_defaults: 2]

  alias Epicenter.Accounts
  alias EpicenterWeb.Session
  alias Epicenter.AuditLog

  plug :get_user_by_reset_password_token when action in [:edit, :update]

  @common_assigns [show_nav: false, body_class: "body-background-color", page_title: "Reset Password"]

  def new(conn, _params),
    do: conn |> assign_defaults(@common_assigns) |> render("new.html")

  def create(conn, %{"user" => %{"email" => email}}) do
    # Regardless of the outcome, show an impartial success/error message.
    message = "An email with instructions was sent"

    if user = Accounts.get_user(email: email) do
      {:ok, %{to: to, body: body}} =
        Accounts.deliver_user_reset_password_instructions(
          user,
          &Routes.user_reset_password_url(conn, :edit, &1)
        )

      conn
      |> Session.append_fake_mail(to, body)
      |> put_flash(:extra, "(Check your mail in /fakemail)")
    else
      conn
    end
    |> put_flash(:info, message)
    |> redirect(to: "/")
  end

  def edit(conn, _params),
    do: conn |> assign_defaults(@common_assigns) |> render("edit.html", changeset: Accounts.change_user_password(conn.assigns.user))

  # Do not log in the user after reset password to avoid a
  # leaked token giving the user access to the account.
  def update(conn, %{"user" => user_params}) do
    user = conn.assigns.user

    case Accounts.reset_user_password(
           user,
           user_params,
           %AuditLog.Meta{
             author_id: user.id,
             reason_action: AuditLog.Revision.reset_password_action(),
             reason_event: AuditLog.Revision.reset_password_submit_event()
           }
         ) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Password reset successfully — please log in")
        |> redirect(to: Routes.user_session_path(conn, :new))

      {:error, changeset} ->
        conn |> assign_defaults(@common_assigns) |> render("edit.html", changeset: changeset)
    end
  end

  defp get_user_by_reset_password_token(conn, _opts) do
    %{"token" => token} = conn.params

    if user = Accounts.get_user_by_reset_password_token(token) do
      conn |> assign(:user, user) |> assign(:token, token)
    else
      conn
      |> put_flash(:error, "Reset password link is invalid or it has expired.")
      |> redirect(to: "/")
      |> halt()
    end
  end
end
