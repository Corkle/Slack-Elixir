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

  @action_button_payload %{
    "actions" => [%{"name" => "button_action", "value" => "val"}],
    "team" => %{"id" => "TEAM_ID", "domain" => "TEAM"},
    "channel" => %{"id" => "CH_ID", "name" => "CHANNEL"},
    "user" => %{"id" => "UID", "name" => "USER"},
    "action_ts" => "00000000", "message_ts" => "1111111",
    "attachment_id" => "ATTACH_ID", "token" => "TOKEN",
    "callback_id" => "123", "original_message" => %{},
    "response_url" => "RESP_URL"}

  @slack_button_action %Slack{
    action: %{name: "button_action", value: "val"},
    team: %{domain: "TEAM", id: "TEAM_ID"}, channel: %{id: "CH_ID", name: "CHANNEL"},
    user: %{id: "UID", name: "USER"}, action_ts: "00000000", message_ts: "1111111",
    attachment_id: "ATTACH_ID", token: "TOKEN", callback_id: "123",
    original_message: %{}, response_url: "RESP_URL", command: nil, text: nil}

  @action_menu_payload %{
    "actions" => [%{"name" => "menu_action",
      "selected_options" => [%{"value" => "val"}]}],
    "team" => %{"id" => "TEAM_ID", "domain" => "TEAM"},
    "channel" => %{"id" => "CH_ID", "name" => "CHANNEL"},
    "user" => %{"id" => "UID", "name" => "USER"},
    "action_ts" => "00000000", "message_ts" => "1111111",
    "attachment_id" => "ATTACH_ID", "token" => "TOKEN",
    "callback_id" => "123", "original_message" => %{},
    "response_url" => "RESP_URL"}

  @slack_menu_action %Slack{
    action: %{name: "menu_action", value: "val"},
    team: %{domain: "TEAM", id: "TEAM_ID"}, channel: %{id: "CH_ID", name: "CHANNEL"},
    user: %{id: "UID", name: "USER"}, action_ts: "00000000", message_ts: "1111111",
    attachment_id: "ATTACH_ID", token: "TOKEN", callback_id: "123",
    original_message: %{}, response_url: "RESP_URL", command: nil, text: nil}

  @command_payload %{
    "command" => "/slash_command", "text" => "hello",
    "team_id" => "TEAM_ID", "team_domain" => "TEAM",
    "channel_id" => "CH_ID", "channel_name" => "CHANNEL",
    "user_id" => "UID", "user_name" => "USER",
    "token" => "TOKEN", "response_url" => "RESP_URL"}

  @slack_command %Slack{
    command: "/slash_command", text: "hello", team: %{domain: "TEAM", id: "TEAM_ID"},
    channel: %{id: "CH_ID", name: "CHANNEL"}, user: %{id: "UID", name: "USER"},
    token: "TOKEN", response_url: "RESP_URL", action: nil, action_ts: nil,
    attachment_id: nil, callback_id: nil, message_ts: nil, original_message: nil,}

  describe "dispatch/2 with Slack button action" do
    test "with nil value for :slack_data, should return 400 response" do
      conn = plug_conn(nil)
      res = ActionController.dispatch(conn, nil)
      assert res.status == 400
    end

    test "with valid JSON payload, should call handle_action with slack data" do
      {:ok, slack} = Poison.encode(@action_button_payload)
      params = %{"payload" => slack}
      conn = plug_conn(params)
      ActionController.dispatch(conn, nil)
      assert_receive {:action, %{name: "button_action", value: "val"}, ^conn, @slack_button_action}
    end

    test "has invalid token, should return 400 error" do
      slack_payload = Map.put(@action_button_payload, "token", "INVALID")
      {:ok, slack} = Poison.encode(slack_payload)
      params = %{"payload" => slack}
      res = post(params) 
      assert res.status == 400
      assert res.halted == true
    end

    test "has valid token, should dispatch action" do
      slack_payload = Map.put(@action_button_payload, "token", "SLACK_TOKEN")
      {:ok, slack} = Poison.encode(slack_payload)
      params = %{"payload" => slack}
      res = post(params)
      assert res.assigns.test_dispatch == :action
    end
  end

  describe "dispatch/2 with Slack menu action" do
    test "with valid JSON payload, should call handle_action with slack data" do
      {:ok, slack} = Poison.encode(@action_menu_payload)
      params = %{"payload" => slack}
      conn = plug_conn(params)
      ActionController.dispatch(conn, nil)
      assert_receive {:action, %{name: "menu_action", value: "val"}, ^conn, @slack_menu_action}
    end

    test "has invalid token, should return 400 error" do
      slack_payload = Map.put(@action_menu_payload, "token", "INVALID")
      {:ok, slack} = Poison.encode(slack_payload)
      params = %{"payload" => slack}
      res = post(params)
      assert res.status == 400
      assert res.halted == true
    end

    test "has valid token, should dispatch action" do
      slack_payload = Map.put(@action_menu_payload, "token", "SLACK_TOKEN")
      {:ok, slack} = Poison.encode(slack_payload)
      params = %{"payload" => slack}
      res = post(params)
      assert res.assigns.test_dispatch == :action
    end
  end

  describe "dispatch/2 with Slack slash command" do
    test "has valid params, should call handle_command with slack data" do
      conn = plug_conn(@command_payload)
      ActionController.dispatch(conn, nil)
      assert_receive {:command, "/slash_command", ^conn, @slack_command}
    end

    test "has invalid token, should return 400 error" do
      params = Map.put(@command_payload, "token", "INVALID")
      res = post(params)
      assert res.status == 400
      assert res.halted == true
    end

    test "has valid token, should dispatch command" do
      params = Map.put(@command_payload, "token", "SLACK_TOKEN")
      res = post(params)
      assert res.assigns.test_dispatch == :command 
    end
  end
end
