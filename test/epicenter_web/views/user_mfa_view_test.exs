defmodule EpicenterWeb.UserMfaViewTest do
  use EpicenterWeb.ConnCase, async: true

  import EpicenterWeb.UserMfaView, only: [colorize_key: 1]

  describe "colorize_key" do
    test "wraps each character in a span with a 'letter' or 'number' class" do
      assert colorize_key("abc123DEF") ==
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
