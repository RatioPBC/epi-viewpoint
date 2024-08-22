defmodule EpiViewpointWeb.ConfirmationModal do
  def abandon_changes_confirmation_text(), do: "Your updates have not been saved. Discard updates?"

  def confirmation_prompt(nil), do: nil

  def confirmation_prompt(%{changes: changes}) when changes == %{}, do: nil

  def confirmation_prompt(_changeset) do
    abandon_changes_confirmation_text()
  end
end
