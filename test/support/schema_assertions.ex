defmodule Epicenter.Test.SchemaAssertions do
  import ExUnit.Assertions

  alias Epicenter.Test.SchemaAssertions.Database
  alias Epicenter.Test.SchemaAssertions.Schema

  @doc """
  Assert that the given schema module exists, it has a corresponding table, and its fields are correct.

  See `assert_schema_fields/2` for details about field assertion.
  """
  def assert_schema(schema_module, field_tuples) when is_list(field_tuples) do
    assert_schema_module_exists(schema_module, field_tuples)
    assert_table_exists(schema_module, field_tuples)
    assert_schema_fields(schema_module, field_tuples)
  end

  def assert_schema_module_exists(schema_module, field_tuples) do
    if not Schema.module_exists?(schema_module) do
      """
      Expected schema module “#{Schema.module_name(schema_module)}” to exist, but it doesn’t.

      A possible remedy is to run this on the command line:

        mix phx.gen.schema #{Schema.module_name(schema_module, :drop_prefix)} #{Schema.table_name(schema_module)} #{colon_separated(field_tuples)}
      """
      |> flunk()
    end
  end

  def assert_table_exists(schema_module, field_tuples) do
    table_name = Schema.table_name(schema_module)

    if not Schema.table_exists?(schema_module) do
      """
      Expected database table “#{table_name}” to exist, but it doesn’t.

      1. You could create a new migration with this mix task:

         mix ecto.gen.migration create_#{table_name}

      2. Your migration could look like this:

         def change() do
           create table(:#{table_name}) do
      #{field_tuples |> Enum.map(&"add #{inspect_contents(&1)}") |> indented_list(7)}

             timestamps()
           end
         end
      """
      |> flunk()
    end
  end

  @doc """
  Assert that a schema and its corresponding database table have the correct fields.

  Currently the error message is pretty generic, but there is probably enough information to provide the exact steps
  for fixing any problems.

  ## Example

      assert_schema_fields(Person, [{:id, :id}, {:first_name, :string}, {:age, :integer}])

  Fields are tuples to allow for asserting on extra metadata in the future, like:
  `[{:first_name, :string, :required}, ...]`
  """
  def assert_schema_fields(schema_module, field_tuples) when is_list(field_tuples) do
    table_name = Schema.table_name(schema_module)

    assertion_fields = field_tuples
    database_fields = schema_module |> Schema.table_name() |> Database.fields()
    schema_fields = schema_module |> Schema.fields_with_types()

    all_field_names =
      for field_set <- [assertion_fields, database_fields, schema_fields],
          field <- field_set,
          uniq: true,
          do: field |> elem(0)

    table_rows =
      for field_name <- all_field_names |> Enum.sort() do
        [
          field_name,
          assertion_fields |> field_metadata(field_name),
          database_fields |> field_metadata(field_name),
          schema_fields |> field_metadata(field_name)
        ]
      end

    if table_rows |> List.flatten() |> Enum.any?(&(&1 == nil)) do
      table =
        TableRex.Table.new(table_rows, ["", "ASSERTION", "DATABASE", "SCHEMA"])
        |> TableRex.Table.render!(horizontal_style: :off, vertical_style: :off)

      """
      Mismatch between asserted fields, fields in database, and fields in schema:

      #{table}

      1. To add to or remove from the assertion, edit the test.

      2. To add to or remove from the database:

         a. Create a migration with one of:
            *  mix ecto.gen.migration add_column1_column2_to_#{table_name}
            *  mix ecto.gen.migration remove_column1_column_2_from_#{table_name}

         b. In the newly-generated migration, modify the change function:

            def change() do
              alter table(:#{table_name}) do
                add :column_name, :type # [, options]
                remove :column_name, :type # [, options]
              end
            end

      3. To add to or remove from the schema, edit the “#{inspect(schema_module)}” schema.
      """
      |> flunk()
    end
  end

  defp colon_separated(tuples),
    do: tuples |> Enum.map(fn {k, v} -> "#{k}:#{v}" end) |> Enum.join(" ")

  defp field_metadata(field_list, field_name) do
    Enum.find_value(field_list, fn field ->
      if elem(field, 0) == field_name,
        do: Tuple.delete_at(field, 0) |> inspect(),
        else: nil
    end)
  end

  defp indent(string, indent_size),
    do: String.duplicate(" ", indent_size) <> string

  defp indented_list(list, indent_size, trailing_character \\ ""),
    do: list |> Enum.map(&indent(&1, indent_size)) |> Enum.join(trailing_character <> "\n")

  defp inspect_contents(tuple) when is_tuple(tuple) do
    tuple |> Tuple.to_list() |> Enum.map(&inspect/1) |> Enum.join(", ")
  end

  defmodule Database do
    alias Epicenter.Repo

    def fields(table_name) do
      for [name, type] <- field_query(table_name),
          do: {Euclid.Extra.Atom.from_string(name), type}
    end

    defp field_query(table_name),
      do: query("select column_name, data_type from information_schema.columns where table_name = $1", [table_name])

    def table_names(),
      do: "select table_name from information_schema.tables where table_schema = 'public'" |> query() |> List.flatten()

    def has_table?(table_name),
      do: table_name in table_names()

    def query(string, args \\ []),
      do: Repo.query!(string, args).rows
  end

  defmodule Schema do
    def field_type(module, field),
      do: module.__schema__(:type, field)

    def fields(module),
      do: module.__schema__(:fields) |> Enum.sort()

    def fields_with_types(module),
      do: for(field <- fields(module), do: {field, field_type(module, field)})

    def module_exists?(module),
      do: function_exported?(module, :__info__, 1)

    def module_name(module),
      do: inspect(module)

    def module_name(module, :drop_prefix),
      do: module |> module_name() |> String.split(".") |> Enum.slice(1..-1) |> Enum.join(".")

    def table_exists?(module),
      do: module |> table_name() |> Database.has_table?()

    def table_name(module),
      do: module |> module_name() |> String.split(".") |> List.last() |> Inflex.underscore() |> Inflex.pluralize()
  end
end
