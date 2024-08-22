defmodule Superhero do
  @moduledoc """
  This is an example consumption of EctoRedactionJasonEncoder, used for its test.
  """

  use Ecto.Schema
  import EpiViewpoint.EctoRedactionJasonEncoder

  schema "superhero" do
    field :moniker, :string
    field :secret_identity, :string, redact: true
    field :created_by
  end

  derive_jason_encoder(except: [:created_by])
end
