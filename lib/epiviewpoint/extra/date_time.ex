defmodule EpiViewpoint.Extra.DateTime do
  def before?(a, b) do
    DateTime.compare(a, b) == :lt
  end
end
