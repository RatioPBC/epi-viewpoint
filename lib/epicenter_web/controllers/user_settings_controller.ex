defmodule EpicenterWeb.UserSettingsController do
  use EpicenterWeb, :controller

  import EpicenterWeb.ControllerHelpers, only: [assign_defaults: 2]

  alias Epicenter.Accounts
  alias Epicenter.AuditLog
  alias EpicenterWeb.Session
  alias EpicenterWeb.UserAuth

  plug :assign_email_and_password_changesets

  @common_assigns [page_title: "Settings"]

  def edit(conn, _params),
    do: conn |> assign_defaults(@common_assigns) |> render("edit.html")

  def update_email(conn, %{"current_password" => password, "user" => user_params}) do
    user = conn.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        {:ok, %{to: to, body: body}} =
          Accounts.deliver_update_email_instructions(
            applied_user,
            user.email,
            &Routes.user_settings_url(conn, :confirm_email, &1)
          )

        conn
        |> Session.append_fake_mail(to, body)
        |> put_flash(:extra, "(Check your mail in /fakemail)")
        |> put_flash(:info, "A link to confirm your email change has been sent to the new address.")
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      {:error, changeset} ->
        conn |> assign_defaults(@common_assigns) |> render("edit.html", email_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    user = conn.assigns.current_user

    case Accounts.update_user_email(
           user,
           {token,
            %AuditLog.Meta{
              author_id: user.id,
              reason_action: AuditLog.Revision.update_user_email_action(),
              reason_event: AuditLog.Revision.update_user_email_event()
            }}
         ) do
      :ok ->
        conn
        |> put_flash(:info, "Email changed successfully")
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      :error ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired")
        |> redirect(to: Routes.user_settings_path(conn, :edit))
    end
  end

  def update_password(conn, %{"current_password" => password, "user" => user_params}) do
    user = conn.assigns.current_user

    case Accounts.update_user_password(
           user,
           password,
           {user_params,
            %AuditLog.Meta{
              author_id: user.id,
              reason_action: AuditLog.Revision.update_user_password_action(),
              reason_event: AuditLog.Revision.update_user_password_event()
            }}
         ) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Password updated successfully")
        |> put_session(:user_return_to, Routes.user_settings_path(conn, :edit))
        |> UserAuth.log_in_user(user)

      {:error, changeset} ->
        conn |> assign_defaults(@common_assigns) |> render("edit.html", password_changeset: changeset)
    end
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    user = conn.assigns.current_user

    conn
    |> assign(:email_changeset, Accounts.change_user_email(user))
    |> assign(:password_changeset, Accounts.change_user_password(user))
  end
end
