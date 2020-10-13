defmodule EctoRedactionJasonEncoderTest do
  use ExUnit.Case, async: true

  test "redacts fields that are marked to be redacted" do
    encoded = Jason.encode!(%Superhero{id: "abc123", moniker: "Superman", secret_identity: "Clark Kent"})
    assert encoded =~ ~r/abc123/
    assert encoded =~ ~r/Superman/
    refute encoded =~ ~r/Clark Kent/
  end

  test "omits `except` fields" do
    encoded = Jason.encode!(%Superhero{moniker: "Superman", created_by: "Jerry Seigel"})
    assert encoded =~ ~r/Superman/
    refute encoded =~ ~r/Jerry Seigel/
  end
end
