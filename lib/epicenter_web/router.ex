defmodule EpicenterWeb.Router do
  use EpicenterWeb, :router

  import EpicenterWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {EpicenterWeb.LayoutView, :root}
    plug :protect_from_forgery

    plug :put_secure_browser_headers, %{
      "content-security-policy" =>
        "default-src 'self'; style-src 'self' 'unsafe-inline' 'unsafe-eval' fonts.googleapis.com; script-src 'self' 'unsafe-inline' 'unsafe-eval'; font-src fonts.gstatic.com; connect-src 'self' ws: wss:;"
    }

    plug :fetch_current_user
    plug :protected_via_basic_auth
  end

  scope "/", EpicenterWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/healthcheck", HealthCheckController, :show
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
      live "/user", UserLive, as: :new_user
      live "/user/:id", UserLive, as: :user
      live "/user/:id/logins", UserLoginsLive, as: :user_logins
      live "/users", UsersLive, as: :users
    end

    get "/", RootController, :show, as: :root
    live "/contacts", ContactsLive, as: :contacts

    live "/import/start", ImportLive, as: :import_start
    get "/import/complete", ImportController, :show
    post "/import/upload", ImportController, :create

    live "/case-investigations/:case_investigation_id/contact", CaseInvestigationContactLive, as: :create_case_investigation_contact
    live "/case-investigations/:case_investigation_id/contact/:id", CaseInvestigationContactLive, as: :edit_case_investigation_contact
    live "/case-investigations/:id/clinical-details", CaseInvestigationClinicalDetailsLive, as: :case_investigation_clinical_details

    live "/case-investigations/:id/complete-interview", InvestigationCompleteInterviewLive, :complete_case_investigation,
      as: :case_investigation_complete_interview

    live "/case-investigations/:id/conclude-isolation-monitoring", CaseInvestigationConcludeIsolationMonitoringLive,
      as: :case_investigation_conclude_isolation_monitoring

    live "/case-investigations/:id/discontinue", CaseInvestigationDiscontinueLive, as: :case_investigation_discontinue
    live "/case-investigations/:id/isolation-monitoring", CaseInvestigationIsolationMonitoringLive, as: :case_investigation_isolation_monitoring
    live "/case-investigations/:id/isolation-order", CaseInvestigationIsolationOrderLive, as: :case_investigation_isolation_order
    live "/case-investigations/:id/start-interview", CaseInvestigationStartInterviewLive, as: :case_investigation_start_interview

    live "/contact-investigations/:id/clinical-details", ContactInvestigationClinicalDetailsLive, as: :contact_investigation_clinical_details

    live "/contact-investigations/:id/complete-interview", InvestigationCompleteInterviewLive, :complete_contact_investigation,
      as: :contact_investigation_complete_interview

    live "/contact-investigations/:id/discontinue", ContactInvestigationDiscontinueLive, as: :contact_investigation_discontinue

    live "/contact-investigations/:id/conclude-quarantine-monitoring", ContactInvestigationConcludeQuarantineMonitoringLive,
      as: :contact_investigation_conclude_quarantine_monitoring

    live "/contact-investigations/:id/quarantine-monitoring", ContactInvestigationQuarantineMonitoringLive,
      as: :contact_investigation_quarantine_monitoring

    live "/contact-investigations/:id/start-interview", ContactInvestigationStartInterviewLive, as: :contact_investigation_start_interview

    live "/people", PeopleLive, as: :people
    live "/people/:id", ProfileLive, as: :profile
    live "/people/:id/edit", ProfileEditLive, as: :profile_edit
    live "/people/:id/edit-demographics", DemographicsEditLive, as: :demographics_edit

    live "/people/:id/potential-duplicates", PotentialDuplicatesLive, as: :potential_duplicates

    live "/resolve-conflicts", ResolveConflictsLive, as: :resolve_conflicts

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings/update-password", UserSettingsController, :update_password
  end

  scope "/", EpicenterWeb do
    pipe_through [:browser]

    live "/styleguide", Styleguide.StyleguideLive, as: :styleguide
    live "/styleguide/form-builder", Styleguide.FormBuilderLive, as: :styleguide_form_builder
    live "/styleguide/form-multiselect", Styleguide.FormMultiselectLive, as: :styleguide_form_multiselect
    live "/styleguide/investigation-notes-section", Styleguide.InvestigationNotesSectionLive, as: :styleguide_investigation_notes_section
    delete "/users/log-out", UserSessionController, :delete
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
