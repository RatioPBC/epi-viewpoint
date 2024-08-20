defmodule EpicenterWeb.UserSessionController do
  use EpicenterWeb, :controller
  import EpicenterWeb.ControllerHelpers, only: [assign_defaults: 2]

  alias Epicenter.Accounts
  alias Epicenter.AuditLog
  alias EpicenterWeb.UserAuth

  @common_assigns [body_class: "body-background-color", page_title: "Log in", show_nav: false]

  def new(conn, _params) do
    case {Accounts.count_users(), Application.get_env(:epicenter, :initial_user_email)} do
      {0, nil} ->
        conn |> assign_defaults(@common_assigns) |> render("new.html", error_message: "No users have been set up")

      {0, initial_user_email} ->
        conn |> register_initial_user(initial_user_email)

      _ ->
        conn |> assign_defaults(@common_assigns) |> render("new.html", error_message: nil)
    end
  end

  def create(conn, %{"user" => %{"email" => email, "password" => password} = user_params}) do
    if user = Accounts.get_user(email: email, password: password),
      do: UserAuth.log_in_user(conn, user, user_params),
      else: conn |> assign_defaults(@common_assigns) |> render("new.html", error_message: "Invalid email or password")
  end

  def delete(conn, _params),
    do: conn |> UserAuth.log_out_user()

  # # #

  defp register_initial_user(conn, initial_user_email) do
    new_user_attrs = %{email: initial_user_email, password: Euclid.Extra.Random.string(), name: "Initial Admin User", admin: true}

    audit_meta = %AuditLog.Meta{
      author_id: Application.get_env(:epicenter, :unpersisted_admin_id),
      reason_action: AuditLog.Revision.create_user_action(),
      reason_event: AuditLog.Revision.initial_user_creation_event()
    }

    with {:user, {:ok, user}} <- {:user, Accounts.register_user({new_user_attrs, audit_meta})},
         {:token, {:ok, token}} <- {:token, Accounts.generate_user_reset_password_token(user)} do
      conn |> redirect(to: ~p"/users/reset-password/#{token}")
    else
      {:user, {:error, %Ecto.Changeset{valid?: false} = changeset}} ->
        error_message =
          case Keyword.get_values(changeset.errors, :email) do
            [] ->
              "There was an error creating the initial user"

            errors ->
              validation_errors = Enum.map(errors, fn {message, _} -> message end) |> Enum.join(", ")
              "Initial user email address “#{initial_user_email}” is invalid: #{validation_errors}"
          end

        conn |> assign_defaults(@common_assigns) |> render("new.html", error_message: error_message)
    end
  end
end
