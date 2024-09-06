defmodule Epiviewpoint.R4.TriggerDefinition do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :id,
    :name,
    :timing_date,
    :timing_date_time,
    :type
  ]
  @required_fields []

  embedded_schema do
    # Fields
    field(:name, :string)
    field(:timing_date, :string)
    field(:timing_date_time, :string)

    # Enum
    field(:type, Ecto.Enum,
      values: [
        :named_event,
        :periodic,
        :data_changed,
        :data_added,
        :data_modified,
        :data_removed,
        :data_accessed,
        :data_access_ended
      ]
    )

    # Embed One
    embeds_one(:condition, Epiviewpoint.R4.Expression)
    embeds_one(:timing_reference, Epiviewpoint.R4.Reference)
    embeds_one(:timing_timing, Epiviewpoint.R4.Timing)

    # Embed Many
    embeds_many(:data, Epiviewpoint.R4.DataRequirement)
    embeds_many(:extension, Epiviewpoint.R4.Extension)
  end

  def choices("timing") do
    [:timing_timing, :timing_reference, :timing_date, :timing_date_time]
  end

  def choices("timingTiming"), do: :error

  def choices("timingReference"), do: :error

  def choices("timingdate"), do: :error

  def choices("timingdateTime"), do: :error

  def choices(_), do: nil

  def version_namespace, do: Epiviewpoint.R4
  def version, do: "R4"

  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @fields)
    |> cast_embed(:condition)
    |> cast_embed(:timing_reference)
    |> cast_embed(:timing_timing)
    |> cast_embed(:data)
    |> cast_embed(:extension)
    |> validate_required(@required_fields)
  end
end