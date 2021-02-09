defmodule EpicenterWeb.Pagination do
  alias EpicenterWeb.Pagination

  defstruct all: [],
            current: 1,
            next?: false,
            pages: nil,
            per_page: 10,
            prev?: false,
            total: 0,
            visible: []

  def new(list, opts \\ [])

  def new(nil, opts),
    do: new([], opts)

  def new(list, opts) when is_list(list),
    do: %Pagination{all: list, total: length(list), per_page: Keyword.get(opts, :per_page, 10)} |> goto(1)

  def goto(%Pagination{all: all, per_page: per_page, total: total} = pagination, current) do
    pages = Range.new(1, Integer.floor_div(total, per_page) + 1)
    visible = Enum.slice(all, (current - 1) * per_page, per_page)

    %{pagination | current: current, next?: current < pages.last, pages: pages, prev?: current > 1, visible: visible}
  end

  def next(%Pagination{current: current} = pagination),
    do: goto(pagination, current + 1)
end
