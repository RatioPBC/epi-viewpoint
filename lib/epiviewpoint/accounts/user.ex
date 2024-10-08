defmodule EpiViewpoint.Accounts.User do
  use Ecto.Schema

  import Ecto.Changeset

  import EpiViewpoint.EctoRedactionJasonEncoder

  alias EpiViewpoint.Accounts.User
  alias EpiViewpoint.Cases.Person
  alias EpiViewpoint.Validation

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :admin, :boolean, read_after_writes: true
    field :confirmed_at, :utc_datetime
    field :email, :string
    field :hashed_password, :string, redact: true
    field :mfa_secret, :string, redact: true
    field :name, :string
    field :password, :string, virtual: true, redact: true
    field :disabled, :boolean, read_after_writes: true
    field :seq, :integer, read_after_writes: true
    field :tid, :string

    timestamps(type: :utc_datetime)

    has_many :assignments, Person, foreign_key: :assigned_to_id
  end

  derive_jason_encoder(except: [:seq])

  @required_attrs ~w{name}a
  @optional_attrs ~w{admin disabled email tid}a
  @registration_attrs ~w{email password disabled}a
  @mfa_attrs ~w{mfa_secret}a

  def changeset(user, attrs) do
    user
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> unique_constraint(:id, name: :users_pkey)
  end

  def mfa_changeset(user, attrs) do
    user
    |> cast(attrs, @mfa_attrs)
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, @required_attrs ++ @optional_attrs ++ @registration_attrs)
    |> validate_required(@required_attrs)
    |> validate_email()
    |> validate_password()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> Validation.validate_email_format(:email)
    |> unsafe_validate_unique(:email, EpiViewpoint.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 10, max: 80, message: "must be between 10 and 80 characters")
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> prepare_changes(&hash_password/1)
  end

  defp hash_password(changeset) do
    password = get_change(changeset, :password)

    changeset
    |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
    |> delete_change(:password)
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_email()
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.
  """
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password()
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Disables or enables the user by setting `disabled`
  """
  def disable_changeset(user, attrs), do: cast(user, Enum.into(attrs, %{}), [:disabled])

  @doc """
  Verifies the password.

  If there is no user, the user doesn't have a password, or the user is
  disabled, we call `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%EpiViewpoint.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  def filter_by_valid_password(nil, _password),
    do: nil

  def filter_by_valid_password(%User{} = user, password) when is_binary(password),
    do: if(valid_password?(user, password), do: user, else: nil)

  defmodule Query do
    import Ecto.Query

    def all() do
      from user in User, order_by: [asc: fragment("lower(?)", user.name), asc: user.seq]
    end
  end
end
