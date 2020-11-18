defmodule Epicenter.HealthCheck do
  @callback database() :: {:ok, any()} | {:error, any()}
  def database do
    Epicenter.Repo.query("SELECT 1")
  end
end
