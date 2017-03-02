defmodule Slack.Phoenix.ActionControllerTest do
  use ExUnit.Case
  use Plug.Test

  import Slack.PlugTestHelper

  defmodule ActionController do
    use Slack.Phoenix.ActionController, token: "SLACK_TOKEN"

    def handle_action(action, conn, slack) do
      send self(), {:action, action, conn, slack}
      assign(conn, :test_dispatch, :action)
    end

    def handle_command(command, conn, slack) do
      send self(), {:command, command, conn, slack}
      assign(conn, :test_dispatch, :command)
    end
  end

  defmodule ActionRouter do
    use Phoenix.Router

    post "/", ActionController, :dispatch    
  end

  def post(params) do
    conn(:post, "/", params)
    |> ActionRouter.call(ActionRouter.init([]))
  end

  defp plug_conn(params) do
    build_conn(params) |> Slack.Plug.FetchSlackData.call(%{})
  end

  @action_payload %{
    "actions" => [%{"name" => "action", "value" => "val"}],
    "team" => %{"id" => "TEAM_ID", "domain" => "TEAM"},
    "channel" => %{"id" => "CH_ID", "name" => "CHANNEL"},
    "user" => %{"id" => "UID", "name" => "USER"},
    "action_ts" => "00000000", "message_ts" => "1111111",
    "attachment_id" => "ATTACH_ID", "token" => "TOKEN",
    "callback_id" => "123", "original_message" => %{},
    "response_url" => "RESP_URL"}

  @command_payload %{
    "command" => "/slash_command", "text" => "hello",
    "team_id" => "TEAM_ID", "team_domain" => "TEAM",
    "channel_id" => "CH_ID", "channel_name" => "CHANNEL",
    "user_id" => "UID", "user_name" => "USER",
    "token" => "TOKEN", "response_url" => "RESP_URL"}


  describe "dispatch/2" do
    test "with nil value for :slack_data, should return 400 response" do
      conn = plug_conn(nil)
      res = ActionController.dispatch(conn, nil)
      assert res.status == 400
    end

    test "with Slack action JSON payload, should call handle_action with slack data" do
      {:ok, slack} = Poison.encode(@action_payload) 
      params = %{"payload" => slack}
      conn = plug_conn(params)
      ActionController.dispatch(conn, nil)
      {:ok, expected_slack} = Slack.create(@action_payload)
      expected_action = expected_slack.action
      assert_receive {:action, ^expected_action, ^conn, ^expected_slack}
    end

    test "with Slack slash command params, should call handle_command with slack data" do
      conn = plug_conn(@command_payload)
      ActionController.dispatch(conn, nil)
      {:ok, expected_slack} = Slack.create(@command_payload)
      assert_receive {:command, "/slash_command", ^conn, ^expected_slack} 
    end

    test "when Slack action has invalid token, should return 400 error" do
      slack_payload = Map.put(@action_payload, "token", "INVALID")
      {:ok, slack} = Poison.encode(slack_payload)
      params = %{"payload" => slack}
      res = post(params) 
      assert res.status == 400
      assert res.halted == true
    end

    test "when Slack slash command has invalid token, should return 400 error" do
      params = Map.put(@command_payload, "token", "INVALID")
      res = post(params)
      assert res.status == 400
      assert res.halted == true
    end

    test "when Slack action has valid token, should dispatch action" do
      slack_payload = Map.put(@action_payload, "token", "SLACK_TOKEN")
      {:ok, slack} = Poison.encode(slack_payload)
      params = %{"payload" => slack}
      res = post(params) 
      assert res.assigns.test_dispatch == :action 
    end

    test "when Slack slash command has valid token, should dispatch command" do
      params = Map.put(@command_payload, "token", "SLACK_TOKEN")
      res = post(params)
      assert res.assigns.test_dispatch == :command 
    end
  end
end
