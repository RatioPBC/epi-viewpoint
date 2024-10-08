defmodule EpiViewpoint.Accounts.UserToken do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias EpiViewpoint.Extra.DateTime, as: Extra

  @hash_algorithm :sha256
  @rand_size 32

  # It is very important to keep the reset password token expiry short,
  # since someone with access to the email may take over the account.
  @reset_password_validity_in_days 1
  @confirm_validity_in_days 3
  @change_email_validity_in_days 3
  @session_validity_in_days 60

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users_tokens" do
    field :token, :binary
    field :context, :string
    field :expires_at, :utc_datetime
    field :sent_to, :string
    belongs_to :user, EpiViewpoint.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(user_token, attrs) do
    user_token |> cast(attrs, [:expires_at])
  end

  @doc """
  Generates a token that will be stored in a signed place,
  such as session or cookie. As they are signed, those
  tokens do not need to be hashed.
  """
  def build_session_token(user) do
    db_now = DateTime.utc_now() |> DateTime.truncate(:second)
    expires_at = db_now |> DateTime.add(default_token_lifetime())
    token = :crypto.strong_rand_bytes(@rand_size)

    {token,
     %EpiViewpoint.Accounts.UserToken{
       token: token,
       context: "session",
       expires_at: expires_at,
       user_id: user.id
     }}
  end

  def default_token_lifetime(), do: 60 * 60 * 3
  def max_token_lifetime(), do: 60 * 60 * 23

  def token_validity_status(user_token) do
    db_now = DateTime.utc_now()

    cond do
      is_nil(user_token.expires_at) -> :expired
      Extra.before?(user_token.inserted_at, db_now |> DateTime.add(-max_token_lifetime())) -> :expired
      Extra.before?(user_token.expires_at, db_now) -> :expired
      true -> :valid
    end
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the user found by the token.
  """
  def verify_session_token_query(token) do
    query =
      from token in token_and_context_query(token, "session"),
        join: user in assoc(token, :user),
        where: token.inserted_at > ago(@session_validity_in_days, "day"),
        select: user

    {:ok, query}
  end

  @doc """
  Builds a token with a hashed counter part.

  The non-hashed token is sent to the user email while the
  hashed part is stored in the database, to avoid reconstruction.
  The token is valid for a week as long as users don't change
  their email.
  """
  def build_email_token(user, context) do
    build_hashed_token(user, context, user.email)
  end

  defp build_hashed_token(user, context, sent_to) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     %EpiViewpoint.Accounts.UserToken{
       token: hashed_token,
       context: context,
       sent_to: sent_to,
       user_id: user.id
     }}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the user found by the token.
  """
  def verify_email_token_query(token, context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)
        days = days_for_context(context)

        query =
          from token in token_and_context_query(hashed_token, context),
            join: user in assoc(token, :user),
            where: token.inserted_at > ago(^days, "day") and token.sent_to == user.email,
            select: user

        {:ok, query}

      :error ->
        :error
    end
  end

  defp days_for_context("confirm"), do: @confirm_validity_in_days
  defp days_for_context("reset_password"), do: @reset_password_validity_in_days

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the user token record.
  """
  def verify_change_email_token_query(token, context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query =
          from token in token_and_context_query(hashed_token, context),
            where: token.inserted_at > ago(@change_email_validity_in_days, "day")

        {:ok, query}

      :error ->
        :error
    end
  end

  @doc """
  Returns the given token with the given context.
  """
  def token_and_context_query(token, context) do
    from EpiViewpoint.Accounts.UserToken, where: [token: ^token, context: ^context]
  end

  @doc """
  Gets all tokens for the given user for the given contexts.
  """
  def user_and_contexts_query(user, :all) do
    from t in EpiViewpoint.Accounts.UserToken, where: t.user_id == ^user.id
  end

  def user_and_contexts_query(user, [_ | _] = contexts) do
    from t in EpiViewpoint.Accounts.UserToken, where: t.user_id == ^user.id and t.context in ^contexts
  end

  def fetch_user_token_query(token) do
    from t in EpiViewpoint.Accounts.UserToken, where: t.token == ^token
  end
end
