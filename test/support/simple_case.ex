defmodule Epicenter.SimpleCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Euclid.Test.Extra.Assertions
    end
  end
end
