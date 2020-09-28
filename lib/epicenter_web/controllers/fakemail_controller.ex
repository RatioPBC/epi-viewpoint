defmodule EpicenterWeb.FakeMailController do
  use EpicenterWeb, :controller

  alias EpicenterWeb.Session

  def show(conn, _params) do
    fake_mail = Session.get_fake_mail(conn)
    count = length(fake_mail)
    conn |> render(body_background: "color", count: count, fake_mail: fake_mail, page_title: "Fakemail")
  end
end
