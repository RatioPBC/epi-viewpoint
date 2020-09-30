defmodule Epicenter.Extra.Tuple do
  def append(tuple, value) when is_tuple(tuple) do
    Tuple.append(tuple, value)
  end

  def append(not_a_tuple, value) do
    {not_a_tuple, value}
  end
end
