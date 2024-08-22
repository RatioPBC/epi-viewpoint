defmodule EpiViewpoint.Test.TableTest do
  use EpiViewpoint.SimpleCase, async: true

  alias EpiViewpoint.Test

  @table """
  <table class="test-table" data-role="table-for-test">
    <thead>
      <tr><th colspan="3">Title</th></tr>
      <tr data-role="table-column-names"><th>Col 0</th><th>Col 1</th><th>Col 2</th></tr>
    <thead>
    <tbody>
      <tr data-tid="tid-1"><td>0,0</td><td>1,0</td><td>2,0</td></tr>
      <tr><td>0,1</td><td>1,1</td><td>2,1</td></tr>
    </tbody>
  </table>
  """

  describe "table_contents" do
    import EpiViewpoint.Test.Table, only: [table_contents: 2]

    test "gets table contents by css" do
      @table
      |> Test.Html.parse()
      |> table_contents(css: ".test-table")
      |> assert_eq([
        ["Col 0", "Col 1", "Col 2"],
        ["0,0", "1,0", "2,0"],
        ["0,1", "1,1", "2,1"]
      ])
    end

    test "gets table contents by role" do
      @table
      |> Test.Html.parse()
      |> table_contents(role: "table-for-test")
      |> assert_eq([
        ["Col 0", "Col 1", "Col 2"],
        ["0,0", "1,0", "2,0"],
        ["0,1", "1,1", "2,1"]
      ])
    end

    test "can include tids" do
      @table
      |> Test.Html.parse()
      |> table_contents(css: ".test-table", columns: ["Col 0", "Col 1"], tids: true)
      |> assert_eq([
        ["Col 0", "Col 1", :tid],
        ["0,0", "1,0", "tid-1"],
        ["0,1", "1,1", ""]
      ])
    end

    test "can extract certain columns" do
      @table
      |> Test.Html.parse()
      |> table_contents(css: ".test-table", columns: ["Col 0", "Col 2"])
      |> assert_eq([
        ["Col 0", "Col 2"],
        ["0,0", "2,0"],
        ["0,1", "2,1"]
      ])
    end

    test "can hide column headers" do
      @table
      |> Test.Html.parse()
      |> table_contents(css: ".test-table", columns: ["Col 0", "Col 2"], headers: false)
      |> assert_eq([
        ["0,0", "2,0"],
        ["0,1", "2,1"]
      ])
    end

    test "can extract a single row as a map" do
      @table
      |> Test.Html.parse()
      |> table_contents(css: ".test-table", row: 1, columns: ["Col 0", "Col 2"])
      |> assert_eq(%{
        "Col 0" => "0,1",
        "Col 2" => "2,1"
      })
    end

    test "doesn't include column names if there aren't any" do
      """
      <table class="test-table">
        <thead>
          <tr colspan="2"><th>Title</th></tr>
        <thead>
        <tbody>
          <tr><td>0,0</td><td>1,0</td></tr>
          <tr><td>0,1</td><td>1,1</td></tr>
        </tbody>
      </table>
      """
      |> Test.Html.parse()
      |> table_contents(css: ".test-table")
      |> assert_eq([
        ["0,0", "1,0"],
        ["0,1", "1,1"]
      ])
    end
  end
end
