defmodule EpicenterWeb.UserLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.ConfirmationModal, only: [confirmation_prompt: 1]
  import EpicenterWeb.LiveHelpers, only: [authenticate_admin_user!: 2, assign_page_title: 2, noreply: 1, ok: 1]

  alias Epicenter.Accounts
  alias Epicenter.Accounts.User
  alias Epicenter.AuditLog
  alias Epicenter.Validation
  alias EpicenterWeb.Endpoint
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

    def changeset(user, attrs) do
      struct(__MODULE__, user_form_attrs(user))
      |> cast(attrs, @required_attrs ++ @optional_attrs)
      |> validate_required(@required_attrs)
      |> Validation.validate_email_format(:email)
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
      |> Map.put(:admin, user_form.type == "admin")
      |> Map.put(:disabled, user_form.status == "inactive")
    end

    defp user_form_attrs(nil), do: %{type: "member", status: "active", email: "", name: ""}

    defp user_form_attrs(%User{} = user) do
      %{
        type: if(user.admin, do: "admin", else: "member"),
        status: if(user.disabled, do: "inactive", else: "active"),
        email: user.email,
        name: user.name
      }
    end
  end

  def mount(params, session, socket) do
    user =
      case params do
        %{"id" => id} ->
          Accounts.get_user!(id)

        _ ->
          nil
      end

    socket
    |> authenticate_admin_user!(session)
    |> assign_page_title("User")
    |> assign(user: user)
    |> assign_form_changeset(UserForm.changeset(user, %{}))
    |> ok()
  end

  def handle_event("change", %{"user_form" => params}, socket) do
    changeset = socket.assigns.user |> UserForm.changeset(params)
    socket |> assign(form_changeset: changeset) |> noreply()
  end

  def handle_event("save", %{"user_form" => params}, socket) do
    form_changeset = UserForm.changeset(socket.assigns.user, params)
    user = socket.assigns.user

    with {:form, {:ok, user_attrs}} <- {:form, UserForm.user_attrs(form_changeset)},
         {:user, {:ok, user}} <- {:user, if(user, do: update_user(socket, user, user_attrs), else: register_user(socket, user_attrs))} do
      socket =
        if socket.assigns.user do
          socket
        else
          {:ok, encoded_token} = Accounts.generate_user_reset_password_token(user)

          socket
          |> put_flash(:password_reset, "Reset link for #{user.email}: #{Routes.user_reset_password_url(Endpoint, :edit, encoded_token)}")
        end

      socket
      |> push_redirect(to: Routes.users_path(socket, EpicenterWeb.UsersLive))
      |> noreply()
    else
      {:form, {:error, %Ecto.Changeset{valid?: false} = invalid_form_changeset}} ->
        socket |> assign_form_changeset(invalid_form_changeset, "Check the errors above") |> noreply()

      {:user, {:error, %{errors: [email: {email_error_message, _}]}}} ->
        socket
        |> assign_form_changeset(
          form_changeset
          |> Ecto.Changeset.add_error(:email, email_error_message)
          |> Map.put(:action, :insert),
          "Check the errors above"
        )
        |> noreply()

      {:user, {:error, changeset}} ->
        socket |> assign_form_changeset(form_changeset, changeset_with_errors_to_error_string(changeset)) |> noreply()
    end
  end

  defp changeset_with_errors_to_error_string(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map(fn {key, value} -> "#{key |> to_string() |> String.capitalize()} #{value}" end)
    |> Enum.join(", ")
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

  defp update_user(socket, user, attrs) do
    Accounts.update_user(
      user,
      attrs,
      %Epicenter.AuditLog.Meta{
        author_id: socket.assigns.current_user.id,
        reason_action: AuditLog.Revision.update_user_registration_action(),
        reason_event: AuditLog.Revision.admin_update_user_event()
      }
    )
  end

  def user_form_builder(changeset, form_error) do
    Form.new(changeset)
    |> Form.line(&Form.text_field(&1, :name, "Name", span: 4))
    |> Form.line(&Form.text_field(&1, :email, "Email", span: 4))
    |> Form.line(&Form.select(&1, :type, "Type", [{"Admin", "admin"}, {"Member", "member"}]))
    |> Form.line(&Form.select(&1, :status, "Status", [{"Active", "active"}, {"Inactive", "inactive"}]))
    |> Form.line(&Form.footer(&1, form_error, span: 4))
    |> Form.safe()
  end

  # # #

  defp assign_form_changeset(socket, form_changeset, form_error \\ nil) do
    socket |> assign(form_changeset: form_changeset, form_error: form_error)
  end
end
