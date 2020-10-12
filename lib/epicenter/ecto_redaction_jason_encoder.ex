defmodule Epicenter.EctoRedactionJasonEncoder do
  defmacro derive_jason_encoder(mod) do
    quote do
      def __nonredacted_fields__(), do: @ecto_fields |> Keyword.keys() |> Kernel.--(@ecto_redact_fields)

      defimpl Jason.Encoder, for: __MODULE__ do
        def encode(value, opts) do
          value |> Map.take(unquote(mod).__nonredacted_fields__()) |> Jason.Encode.map(opts)
        end
      end
    end
  end
end
