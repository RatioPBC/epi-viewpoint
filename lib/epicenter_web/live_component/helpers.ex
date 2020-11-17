defmodule EpicenterWeb.LiveComponent.Helpers do
  require Phoenix.LiveView.Helpers

  defmacro component(socket, module, id, opts \\ [], do_block \\ []) do
    quote do
      is_stateful =
        Enum.member?(unquote(module).__info__(:functions), {:handle_event, 3}) || Enum.member?(unquote(module).__info__(:functions), {:preload, 1})

      opts =
        case is_stateful do
          true -> [{:id, unquote(id)} | unquote(opts)]
          false -> [{:key, unquote(id)} | unquote(opts)]
        end

      Phoenix.LiveView.Helpers.live_component(unquote(socket), unquote(module), opts, unquote(do_block))
    end
  end
end
