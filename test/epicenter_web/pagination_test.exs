defmodule EpicenterWeb.PaginationTest do
  use Epicenter.SimpleCase, async: true

  alias EpicenterWeb.Pagination

  defp list(count) when is_integer(count), do: list(1..count)
  defp list(range), do: Enum.into(range, [])

  describe "new" do
    defp new(count, opts \\ []),
      do: count |> list() |> Pagination.new(opts)

    test "creates a new pagination from a list of items" do
      assert new(7) == %Pagination{all: list(7), current: 1, next?: false, pages: 1..1, per_page: 10, prev?: false, total: 7, visible: list(1..7)}
      assert new(48) == %Pagination{all: list(48), current: 1, next?: true, pages: 1..5, per_page: 10, prev?: false, total: 48, visible: list(1..10)}
    end

    test "creates an empty pagination when there are no items" do
      assert Pagination.new(nil) == %Pagination{all: [], current: 1, next?: false, prev?: false, pages: 1..1, per_page: 10, visible: []}
      assert Pagination.new([]) == %Pagination{all: [], current: 1, next?: false, prev?: false, pages: 1..1, per_page: 10, visible: []}
    end

    test "takes a 'per_page' option" do
      assert %Pagination{per_page: 25, pages: 1..3} = new(51, per_page: 25)
    end
  end

  describe "goto" do
    defp goto(page),
      do: list(48) |> Pagination.new() |> Pagination.goto(page)

    test "goes to a page" do
      assert goto(1) == %Pagination{all: list(48), current: 1, next?: true, prev?: false, pages: 1..5, per_page: 10, total: 48, visible: list(1..10)}
      assert goto(4) == %Pagination{all: list(48), current: 4, next?: true, prev?: true, pages: 1..5, per_page: 10, total: 48, visible: list(31..40)}
      assert goto(5) == %Pagination{all: list(48), current: 5, next?: false, prev?: true, pages: 1..5, per_page: 10, total: 48, visible: list(41..48)}
    end
  end

  describe "next" do
    test "goes to the next page" do
      assert %Pagination{current: 3} = list(30) |> Pagination.new() |> Pagination.next() |> Pagination.next()
    end
  end

  describe "previous" do
    test "goes to the previous page" do
      assert %Pagination{current: 1} = list(30) |> Pagination.new() |> Pagination.goto(3) |> Pagination.previous() |> Pagination.previous()
    end
  end
end
