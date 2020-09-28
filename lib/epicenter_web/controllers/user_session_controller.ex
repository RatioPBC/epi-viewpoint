defmodule EpicenterWeb.UserSessionController do
  use EpicenterWeb, :controller

  alias Epicenter.Accounts
  alias EpicenterWeb.UserAuth

  @common_assigns [body_background: "color", page_title: "Log in"]

  def new(conn, _params) do
    render_with_common_assigns(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      UserAuth.log_in_user(conn, user, user_params)
    else
      render_with_common_assigns(conn, "new.html", error_message: "Invalid email or password")
    end
  end

  def delete(conn, _params) do
    conn |> UserAuth.log_out_user()
  end

  defp render_with_common_assigns(conn, template, assigns) do
    render(conn, template, Keyword.merge(@common_assigns, assigns))
  end
end
