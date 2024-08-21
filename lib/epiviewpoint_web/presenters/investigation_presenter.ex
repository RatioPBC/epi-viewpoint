defmodule EpiViewpointWeb.Presenters.InvestigationPresenter do
  @symptoms_map %{
    "abdominal_pain" => "Abdominal pain",
    "chills" => "Chills",
    "cough" => "Cough",
    "diarrhea_gi" => "Diarrhea/GI",
    "fatigue" => "Fatigue",
    "fever" => "Fever > 100.4F",
    "headache" => "Headache",
    "loss_of_sense_of_smell" => "Loss of sense of smell",
    "loss_of_sense_of_taste" => "Loss of sense of taste",
    "muscle_ache" => "Muscle ache",
    "nasal_congestion" => "Nasal congestion",
    "shortness_of_breath" => "Shortness of breath",
    "sore_throat" => "Sore throat",
    "subjective_fever" => "Subjective fever (felt feverish)",
    "vomiting" => "Vomiting"
  }

  def displayable_clinical_status(%{clinical_status: nil}), do: "None"

  def displayable_clinical_status(%{clinical_status: clinical_status}),
    do: Gettext.gettext(EpiViewpoint.Gettext, clinical_status)

  def displayable_symptoms(%{symptoms: nil}),
    do: "None"

  def displayable_symptoms(%{symptoms: []}),
    do: "None"

  def displayable_symptoms(%{symptoms: symptoms}),
    do: Enum.map(symptoms, &Map.get(@symptoms_map, &1, &1)) |> Enum.join(", ")
end
