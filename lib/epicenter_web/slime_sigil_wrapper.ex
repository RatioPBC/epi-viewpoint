defmodule EpicenterWeb.SlimeSigilWrapper do
  defmacro sigil_H({:<<>>, meta, [expr]}, _opts) do
    ast =
      expr
      |> Slime.Renderer.precompile()
      |> EEx.compile_string(engine: Phoenix.LiveView.Engine, file: "inline slime", line: Keyword.get(meta, :line))

    quote do
      unquote(ast)
    end
  end
end
