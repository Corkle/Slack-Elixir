defmodule Slack.Plug.VerifyTokenTest do
  use ExUnit.Case

  import Plug.Conn
  import Slack.PlugTestHelper
   
  alias Slack.Plug.VerifyToken 
  
  test "without :slack_params in conn.private, should halt conn and set 40000 status" do
    conn = build_conn()
    opts = VerifyToken.init([token: "SLACK_TOKEN"])
    res = VerifyToken.call(conn, opts)
    assert res.status == 400 
    assert res.halted == true
  end

  test "when no :token argument is provided, should raise arugment error" do
    conn = build_conn()
    opts = VerifyToken.init()
    assert_raise ArgumentError, fn ->
      VerifyToken.call(conn, opts)
    end
  end

  test "when token in :slack_params does not match validation :token argument, should halt conn and set 400 status" do
    conn = build_conn(%Slack{token: "INVALID"})
    opts = VerifyToken.init([token: "SLACK_TOKEN"])
    res = VerifyToken.call(conn, opts)
    assert res.status == 400
    assert res.halted == true
  end

  test "when token in :slack_params matches validation :token, should return conn unchanged" do
    conn = build_conn() |> put_private(:slack_data, %Slack{token: "SLACK_TOKEN"})
    opts = VerifyToken.init([token: "SLACK_TOKEN"])
    assert VerifyToken.call(conn, opts) == conn
  end
end
