defmodule Epicenter.Extra.NaiveDateTime do
  def is_before?(a,b) do
    NaiveDateTime.compare(a, b) == :lt
  end
end
