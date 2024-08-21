defmodule EpiViewpoint.SimpleCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import EpiViewpoint.Test.HtmlAssertions
      import Euclid.Test.Extra.Assertions
    end
  end
end
