defmodule Epicenter.DateParsingError do
  @moduledoc """
  Raised when we cannot parse a date due to
  formatting.
  """
  defexception [:user_readable]

  def message(%{user_readable: user_readable}), do: user_readable
end

defmodule Epicenter.AdminRequiredError do
  @moduledoc """
  Raised when an unprivileged user attempts to perform an admin action.
  """
  defexception []
  def message(%{}), do: "Action can only be performed by administrators"
end

defmodule Epicenter.CaseInvestigationFilterError do
  @moduledoc """
  Raised when we cannot match a given filter for case investigation status.
  """
  defexception [:user_readable]
  def message(%{user_readable: user_readable}), do: user_readable
end
