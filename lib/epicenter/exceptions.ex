defmodule Epicenter.DateParsingError do
  @moduledoc """
  Raised when we cannot parse a date due to
  formatting.
  """
  defexception [:user_readable]
end
