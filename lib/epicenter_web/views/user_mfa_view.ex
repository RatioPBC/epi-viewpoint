defmodule EpicenterWeb.UserMfaView do
  use EpicenterWeb, :view

  import EpicenterWeb.IconView, only: [error_icon: 0]

  def colorize_key(key) do
    key
    |> String.split("", trim: true)
    |> Enum.map(&wrap/1)
    |> Enum.join()
  end

  defp wrap(character) do
    if number?(character),
      do: ~s|<span class="number">#{character}</span>|,
      else: ~s|<span class="letter">#{character}</span>|
  end

  defp number?(string) do
    case Integer.parse(string) do
      {integer, _} when is_integer(integer) -> true
      _ -> false
    end
  end
end
