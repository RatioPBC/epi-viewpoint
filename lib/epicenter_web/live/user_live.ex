defmodule EpicenterWeb.UserLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [authenticate_admin_user!: 2, assign_page_title: 2, noreply: 1, ok: 1]

  alias Epicenter.Accounts
  alias Epicenter.Accounts.User
  alias Epicenter.AuditLog
  alias EpicenterWeb.Form

  defmodule UserForm do
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false

    embedded_schema do
      field :email, :string
      field :name, :string
      field :status, :string
      field :type, :string
    end

    @required_attrs ~w{email name status type}a
    @optional_attrs ~w{}a

    def changeset(form_attrs) do
      %UserForm{}
      |> cast(form_attrs, @required_attrs ++ @optional_attrs)
      |> validate_required(@required_attrs)
    end

    def user_attrs(%Ecto.Changeset{} = form_changeset) do
      case apply_action(form_changeset, :create) do
        {:ok, user_form} -> {:ok, user_attrs(user_form)}
        other -> other
      end
    end

    def user_attrs(%UserForm{} = user_form) do
      user_form
      |> Map.from_struct()
    end

    def user_form_attrs(%User{} = user) do
      user
      |> Map.from_struct()
    end
  end

  def mount(_params, session, socket) do
    socket
    |> authenticate_admin_user!(session)
    |> assign_page_title("User")
    |> assign_form_changeset(UserForm.changeset(%{type: "member", status: "active"}))
    |> ok()
  end

  def handle_event("save", %{"user_form" => params}, socket) do
    form_changeset = UserForm.changeset(params)

    with {:form, {:ok, user_attrs}} <- {:form, UserForm.user_attrs(form_changeset)},
         {:user, {:ok, _user}} <- {:user, register_user(socket, user_attrs)} do
      socket
      |> push_redirect(to: Routes.users_path(socket, EpicenterWeb.UsersLive))
      |> noreply()
    else
      {:form, {:error, %Ecto.Changeset{valid?: false} = invalid_form_changeset}} ->
        socket |> assign_form_changeset(invalid_form_changeset, "Check the errors above") |> noreply()

      {:user, {:error, _error}} ->
        socket |> assign_form_changeset(form_changeset, "An unexpected error occurred") |> noreply()
    end
  end

  defp register_user(socket, attrs) do
    Accounts.register_user({
      Map.put(attrs, :password, Euclid.Extra.Random.string()),
      %Epicenter.AuditLog.Meta{
        author_id: socket.assigns.current_user.id,
        reason_action: AuditLog.Revision.register_user_action(),
        reason_event: AuditLog.Revision.admin_create_user_event()
      }
    })
  end

  def user_form_builder(changeset, form_error) do
    Form.new(changeset)
    |> Form.line(&Form.text_field(&1, :name, "Name", 4))
    |> Form.line(&Form.text_field(&1, :email, "Email", 4))
    |> Form.line(&Form.select(&1, :type, "Type", [{"Admin", "admin"}, {"Member", "member"}]))
    |> Form.line(&Form.select(&1, :status, "Status", [{"Active", "active"}, {"Inactive", "inactive"}]))
    |> Form.line(&Form.footer(&1, form_error, 4))
    |> Form.safe()
  end

  # # #

  defp assign_form_changeset(socket, form_changeset, form_error \\ nil) do
    socket |> assign(form_changeset: form_changeset, form_error: form_error)
  end
end
