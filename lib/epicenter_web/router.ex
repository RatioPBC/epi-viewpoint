defmodule EpicenterWeb.Router do
  use EpicenterWeb, :router

  import EpicenterWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {EpicenterWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug :protected_via_basic_auth
  end

  scope "/", EpicenterWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/login", UserSessionController, :new
    post "/users/login", UserSessionController, :create
    #    get "/users/reset-password", UserResetPasswordController, :new
    #    post "/users/reset-password", UserResetPasswordController, :create
    get "/users/reset-password/:token", UserResetPasswordController, :edit
    put "/users/reset-password/:token", UserResetPasswordController, :update
  end

  scope "/", EpicenterWeb do
    pipe_through [:browser, :require_authenticated_user_without_mfa]

    get "/users/mfa-setup", UserMultifactorAuthSetupController, :new
    post "/users/mfa-setup", UserMultifactorAuthSetupController, :create
    get "/users/mfa", UserMultifactorAuthController, :new
    post "/users/mfa", UserMultifactorAuthController, :create
  end

  scope "/", EpicenterWeb do
    pipe_through [:browser, :require_authenticated_user]

    scope "/admin" do
      pipe_through [:require_admin]
      live "/user", UserLive, as: :user
      live "/users", UsersLive, as: :users
    end

    get "/", RootController, :show, as: :root
    live "/import/start", ImportLive, as: :import_start
    get "/import/complete", ImportController, :show
    post "/import/upload", ImportController, :create
    live "/people", PeopleLive, as: :people
    live "/people/:id", ProfileLive, as: :profile
    live "/people/:id/case_investigations/todo/start", CaseInvestigationStartLive, as: :case_investigation_start
    live "/people/:id/edit", ProfileEditLive, as: :profile_edit
    live "/people/:id/edit-demographics", DemographicsEditLive, as: :demographics_edit
    get "/users/settings", UserSettingsController, :edit
    put "/users/settings/update_password", UserSettingsController, :update_password
    put "/users/settings/update_email", UserSettingsController, :update_email
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
  end

  scope "/", EpicenterWeb do
    pipe_through [:browser]

    get "/fakemail", FakeMailController, :show
    live "/styleguide", Styleguide.StyleguideLive, as: :styleguide
    live "/styleguide/form", Styleguide.FormLive, as: :styleguide_form
    live "/styleguide/form-builder", Styleguide.FormBuilderLive, as: :styleguide_form_builder
    delete "/users/log_out", UserSessionController, :delete
  end

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
