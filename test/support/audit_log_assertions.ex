defmodule Epicenter.Test.AuditLogAssertions do
  import Euclid.Test.Extra.Assertions
  import ExUnit.Assertions
  import Mox

  alias Epicenter.Extra
  alias Epicenter.Test

  def expect_phi_view_logs(count) do
    Mox.verify_on_exit!()
    log_level = :info

    Test.PhiLoggerMock
    |> expect(log_level, count, fn message, metadata, unlogged_metadata ->
      Process.put(:phi_logger_messages, phi_logger_messages() ++ [{message, metadata, Keyword.put(unlogged_metadata, :log_level, log_level)}])
      :ok
    end)
  end

  def inspect_logs() do
    phi_logger_messages() |> IO.inspect(label: "phi_logger_messages")
  end

  def verify_phi_view_logged(user, person_or_people, opts \\ []) do
    messages = phi_logger_messages() |> Enum.map(fn {message, _metadata, _unlogged_metadata} -> message end)
    people = List.wrap(person_or_people)
    expected_messages = people |> Enum.map(&"User(#{user.id}) viewed Person(#{&1.id})")

    if Enum.empty?(messages) do
      flunk """
      Nothing was logged to the PHI audit log. Make sure you call `#{__MODULE__}.expect_phi_view_logs`
      before calling code that writes to the PHI audit log.
      """
    end

    case Keyword.get(opts, :match, :subset) do
      :subset ->
        unless Extra.Enum.subset?(expected_messages, messages) do
          flunk """
          Expected phi logs to contain: #{inspect(expected_messages)}
          but got: #{inspect(messages)}
          """
        end

      :exact ->
        assert_eq(expected_messages, messages, ignore_order: true)
    end
  end

  def phi_logger_messages(),
    do: Process.get(:phi_logger_messages, [])
end
