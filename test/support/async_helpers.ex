defmodule Epicenter.AsyncHelpers do
  def retry_until(func_that_could_go_wrong, timeout \\ 100, from \\ DateTime.utc_now()) do
    if DateTime.diff(DateTime.utc_now(), from, :millisecond) > timeout do
      func_that_could_go_wrong.()
    else
      try do
        func_that_could_go_wrong.()
      rescue
        _ ->
          :timer.sleep(10)
          retry_until(func_that_could_go_wrong, timeout, from)
      end
    end
  end
end
