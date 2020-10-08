defmodule Epicenter.Extra.DateTime do
  def is_before?(a, b) do
    DateTime.compare(a, b) == :lt
  end
end
