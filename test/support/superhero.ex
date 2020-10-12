defmodule Superhero do
  @moduledoc """
  This is an example consumption of EctoRedactionJasonEncoder, used for its test.
  """

  use Ecto.Schema
  import Epicenter.EctoRedactionJasonEncoder

  schema "superhero" do
    field :moniker, :string
    field :secret_identity, :string, redact: true
  end

  derive_jason_encoder(Superhero)
end
