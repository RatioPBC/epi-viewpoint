defmodule EpiViewpoint.HealthCheck do
  @callback database() :: {:ok, any()} | {:error, any()}
  def database do
    EpiViewpoint.Repo.query("SELECT 1")
  end
end
