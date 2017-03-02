defmodule Slack.PlugTestHelper do
  import Plug.Test
  
  alias Plug.Parsers

  def build_conn(params \\ nil) do
    opts = Parsers.init(parsers: [:urlencoded, :multipart, :json])
    conn(:post, "/", params) 
    |> Plug.Parsers.call(opts)
  end
end
