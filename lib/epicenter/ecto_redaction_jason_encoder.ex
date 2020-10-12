defmodule Epicenter.EctoRedactionJasonEncoder do
  defmacro derive_jason_encoder(opts \\ []) do
    quote do
      import Epicenter.EctoRedactionJasonEncoder, only: [__derive_jason_encoder__: 2]

      __derive_jason_encoder__(__MODULE__, unquote(opts))
    end
  end

  defmacro __derive_jason_encoder__(mod, opts) do
    except = Keyword.get(opts, :except, [])
    quote bind_quoted: [mod: mod, except: except] do
      def __nonredacted_fields__(), do: @ecto_fields |> Keyword.keys() |> Kernel.--(@ecto_redact_fields) |> Kernel.--(unquote(except))


      defimpl Jason.Encoder, for: __MODULE__ do
        def encode(value, opts) do
          value |> Map.take(unquote(mod).__nonredacted_fields__()) |> Jason.Encode.map(opts)
        end
      end
    end
  end
end
