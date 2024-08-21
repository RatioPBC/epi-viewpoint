defmodule EpiViewpointWeb.IntegrationCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use EpiViewpointWeb.ConnCase
      use PhoenixIntegration
    end
  end
end
