defmodule Epicenter.EctoRedactionJasonEncoder do
  @moduledoc """
  Usage:
  Provides a macro for implementing the Jason.Encoder protocol in a way that respects Ecto's redaction system.

  This macro must be invoked _after_ the Ecto.Schema.schema definition, else the requisite redaction information is unavailable.
  """

  defmacro derive_jason_encoder(opts \\ []) do
    except = Keyword.get(opts, :except, [])
    quote do
      invoking_module = __MODULE__

      def __nonredacted_fields__(), do: @ecto_fields |> Keyword.keys() |> Kernel.--(@ecto_redact_fields) |> Kernel.--(unquote(except))

      defimpl Jason.Encoder, for: __MODULE__ do
        @invoking_module invoking_module

        def encode(value, opts) do
          value |> Map.take(@invoking_module.__nonredacted_fields__()) |> Jason.Encode.map(opts)
        end
      end
    end
  end
end
