defmodule EpicenterWeb.Router do
  use EpicenterWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {EpicenterWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :protected_via_basic_auth
  end

  scope "/", EpicenterWeb do
    pipe_through :browser

    get "/", SessionController, :new
    live "/admin", AdminLive
    live "/import", ImportLive
    get "/import/complete", ImportController, :show
    post "/import/upload", ImportController, :create
    live "/people", PeopleLive.Index, :index
    live "/people/:id", PeopleLive.Show, :show
    live "/page", PageLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", EpicenterWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: EpicenterWeb.Telemetry
    end
  end

  def protected_via_basic_auth(conn, _opts) do
    basic_auth_username = System.get_env("BASIC_AUTH_USERNAME")
    basic_auth_password = System.get_env("BASIC_AUTH_PASSWORD")

    if Euclid.Exists.present?(basic_auth_username),
      do: Plug.BasicAuth.basic_auth(conn, username: basic_auth_username, password: basic_auth_password),
      else: conn
  end
end
