defmodule EpiViewpointWeb.UserMultifactorAuthSetupViewTest do
  use EpiViewpointWeb.ConnCase, async: true

  import EpiViewpointWeb.UserMultifactorAuthSetupView, only: [colorize_alphanumeric_string: 1]

  describe "colorize_alphanumeric_string" do
    test "wraps each character in a span with a 'letter' or 'number' class" do
      assert colorize_alphanumeric_string("abc123DEF") ==
               ~s|<span class="letter">a</span>| <>
                 ~s|<span class="letter">b</span>| <>
                 ~s|<span class="letter">c</span>| <>
                 ~s|<span class="number">1</span>| <>
                 ~s|<span class="number">2</span>| <>
                 ~s|<span class="number">3</span>| <>
                 ~s|<span class="letter">D</span>| <>
                 ~s|<span class="letter">E</span>| <>
                 ~s|<span class="letter">F</span>|
    end
  end
end
