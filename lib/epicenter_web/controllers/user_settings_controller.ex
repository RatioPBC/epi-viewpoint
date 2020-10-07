defmodule EpicenterWeb.UserSettingsController do
  use EpicenterWeb, :controller

  alias Epicenter.Accounts
  alias EpicenterWeb.Session
  alias EpicenterWeb.UserAuth

  plug :assign_email_and_password_changesets

  @common_assigns [page_title: "Settings"]

  def edit(conn, _params) do
    render_with_common_assigns(conn, "edit.html")
  end

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
        render_with_common_assigns(conn, "edit.html", email_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Accounts.update_user_email(conn.assigns.current_user, token) do
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

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Password updated successfully")
        |> put_session(:user_return_to, Routes.user_settings_path(conn, :edit))
        |> UserAuth.log_in_user(user)

      {:error, changeset} ->
        render_with_common_assigns(conn, "edit.html", password_changeset: changeset)
    end
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    user = conn.assigns.current_user

    conn
    |> assign(:email_changeset, Accounts.change_user_email(user))
    |> assign(:password_changeset, Accounts.change_user_password(user))
  end

  defp render_with_common_assigns(conn, template, assigns \\ []),
    do: render(conn, template, Keyword.merge(@common_assigns, assigns))
end
