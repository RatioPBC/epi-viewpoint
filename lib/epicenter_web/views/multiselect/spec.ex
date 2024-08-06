defmodule EpicenterWeb.Multiselect.Spec do
  @moduledoc """
  Specs look like: `{type, display, value}` or `{type, display, value, children}`
  """

  def parent(child, spec) do
    Enum.find_value(spec, fn
      {_type, _display, _value} ->
        nil

      {_type, _display, parent, children} ->
        if Enum.any?(children, fn {_type, _display, value} -> value == child end),
          do: parent,
          else: nil
    end)
  end

  def type({keypath, value}, spec) when is_list(keypath),
    do: type(value, spec)

  def type(value, spec) do
    Enum.find_value(spec, fn
      {type, _display, spec_value} -> if spec_value == value, do: type, else: nil
      {type, _display, spec_value, children} -> if spec_value == value, do: type, else: type(value, children)
    end)
  end
end
