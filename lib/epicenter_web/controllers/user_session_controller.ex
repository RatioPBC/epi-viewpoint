defmodule EpicenterWeb.UserSessionController do
  use EpicenterWeb, :controller

  import EpicenterWeb.ControllerHelpers, only: [assign_defaults: 2]

  alias Epicenter.Accounts
  alias EpicenterWeb.UserAuth

  @common_assigns [body_class: "body-background-color", page_title: "Log in", show_nav: false]

  def new(conn, _params),
    do: conn |> assign_defaults(@common_assigns) |> render("new.html", error_message: nil)

  def create(conn, %{"user" => %{"email" => email, "password" => password} = user_params}) do
    if user = Accounts.get_user(email: email, password: password),
      do: UserAuth.log_in_user(conn, user, user_params),
      else: conn |> assign_defaults(@common_assigns) |> render("new.html", error_message: "Invalid email or password")
  end

  def delete(conn, _params),
    do: conn |> UserAuth.log_out_user()
end
