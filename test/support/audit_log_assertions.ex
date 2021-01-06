defmodule Epicenter.Test.AuditLogAssertions do
  import ExUnit.Assertions

  def assert_viewed_people(log_output, user, people) when length(people) > 0 do
    Enum.each(people, &assert(log_output =~ "User(#{user.id}) viewed Person(#{&1.id})"))
  end

  def assert_viewed_people(_log_output, _user, _people),
    do: raise("assert_viewed_people(log_output, user, people) requires people to have at least one element")
end
