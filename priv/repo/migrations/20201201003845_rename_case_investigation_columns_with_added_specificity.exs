defmodule EpiViewpoint.Repo.Migrations.RenameCaseInvestigationColumnsWithAddedSpecificity do
  use Ecto.Migration

  def change do
    rename table(:case_investigations), :completed_interview_at, to: :interview_completed_at
    rename table(:case_investigations), :discontinue_reason, to: :interview_discontinue_reason
    rename table(:case_investigations), :discontinued_at, to: :interview_discontinued_at

    rename table(:case_investigations), :isolation_clearance_order_sent_date,
      to: :isolation_clearance_order_sent_on

    rename table(:case_investigations), :isolation_monitoring_end_date,
      to: :isolation_monitoring_ended_on

    rename table(:case_investigations), :isolation_monitoring_start_date,
      to: :isolation_monitoring_started_on

    rename table(:case_investigations), :isolation_order_sent_date, to: :isolation_order_sent_on
    rename table(:case_investigations), :started_at, to: :interview_started_at
    rename table(:case_investigations), :symptom_onset_date, to: :symptom_onset_on
  end
end
