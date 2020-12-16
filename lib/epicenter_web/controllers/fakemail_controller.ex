defmodule EpicenterWeb.FakeMailController do
  use EpicenterWeb, :controller

  import EpicenterWeb.ControllerHelpers, only: [assign_defaults: 1]

  alias EpicenterWeb.Session

  def show(conn, _params) do
    fake_mail = Session.get_fake_mail(conn)
    count = length(fake_mail)

    conn
    |> assign_defaults()
    |> render(count: count, fake_mail: fake_mail, page_title: "Fakemail")
  end
end
