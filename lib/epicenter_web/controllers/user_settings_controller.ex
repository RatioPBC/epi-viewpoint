defmodule EpicenterWeb.UserSettingsController do
  use EpicenterWeb, :controller

  import EpicenterWeb.ControllerHelpers, only: [assign_defaults: 2]

  alias Epicenter.Accounts
  alias Epicenter.AuditLog
  alias EpicenterWeb.UserAuth

  plug :assign_password_changeset

  @common_assigns [page_title: "Settings"]

  def edit(conn, _params),
    do: conn |> assign_defaults(@common_assigns) |> render("edit.html")

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

  defp assign_password_changeset(conn, _opts),
    do: conn |> assign(:password_changeset, Accounts.change_user_password(conn.assigns.current_user))
end
