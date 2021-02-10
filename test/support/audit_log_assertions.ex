defmodule Epicenter.Test.AuditLogAssertions do
  import ExUnit.Assertions
  import Mox

  alias Epicenter.Accounts.User
  alias Epicenter.Cases.Person
  alias Epicenter.Test

  def assert_viewed_nobody(log_output) do
    refute log_output =~ "viewed Person"
  end

  def assert_viewed_person(log_output, %User{} = user, %Person{} = person) do
    assert log_output =~ "User(#{user.id}) viewed Person(#{person.id})"
    log_output
  end

  def assert_viewed_people(log_output, user, people) when length(people) > 0 do
    Enum.each(people, &assert_viewed_person(log_output, user, &1))
  end

  def assert_viewed_people(_log_output, _user, _people),
    do: raise("assert_viewed_people(log_output, user, people) requires people to have at least one element")

  def expect_phi_view_logs(count) do
    Test.PhiLoggerMock
    |> expect(:info, count, fn message, _meta ->
      send(self(), {:logged, message})
      {:ok}
    end)
  end

  def verify_phi_view_logged(user, people) do
    for person <- List.wrap(people) do
      expected_log_text = "User(#{user.id}) viewed Person(#{person.id})"

      assert_receive({:logged, ^expected_log_text}, nil, "no view logged for person: #{person.tid}")
    end
  end
end
