defmodule EpiViewpoint.Extra do
  def tap(input, func) do
    func.(input)
    input
  end
end
