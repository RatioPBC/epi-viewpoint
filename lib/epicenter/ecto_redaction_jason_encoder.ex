defmodule Epicenter.EctoRedactionJasonEncoder do
  defmacro derive_jason_encoder() do
    quote do
      import Epicenter.EctoRedactionJasonEncoder, only: [__derive_jason_encoder__: 1]

      __derive_jason_encoder__(__MODULE__)
    end
  end

  defmacro __derive_jason_encoder__(mod) do
    quote bind_quoted: [mod: mod] do
      def __nonredacted_fields__(), do: @ecto_fields |> Keyword.keys() |> Kernel.--(@ecto_redact_fields)


      defimpl Jason.Encoder, for: __MODULE__ do
        def encode(value, opts) do
          value |> Map.take(unquote(mod).__nonredacted_fields__()) |> Jason.Encode.map(opts)
        end
      end
    end
  end
end
