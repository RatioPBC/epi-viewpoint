defmodule EpicenterWeb.IntegrationCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use EpicenterWeb.ConnCase
      use PhoenixIntegration
    end
  end
end
