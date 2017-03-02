defmodule SlackTest do
  use ExUnit.Case

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

  describe "create/1 with interactive message payload data" do
    test "when all fields are valid, should return struct with non-nil action fields" do
      expected = 
        {:ok, %{__struct__: Slack,
          action: %{name: "action", value: "val"},
          team: %{id: "TEAM_ID", domain: "TEAM"},
          channel: %{id: "CH_ID", name: "CHANNEL"},
          user: %{id: "UID", name: "USER"},
          action_ts: "00000000", message_ts: "1111111",
          attachment_id: "ATTACH_ID", token: "TOKEN",
          callback_id: "123", original_message: %{},
          response_url: "RESP_URL", command: nil, text: nil}}
      assert Slack.create(@action_payload) == expected
    end

    test "when missing team field, should return format error" do
      payload = Map.delete(@action_payload, "team")
      expected = {:error, :invalid_team_format}
      assert Slack.create(payload) == expected
    end
    
    test "when missing channel field, should return format error" do
      payload = Map.delete(@action_payload, "channel")
      expected = {:error, :invalid_channel_format}
      assert Slack.create(payload) == expected
    end

    test "when missing user field, should return format error" do
      payload = Map.delete(@action_payload, "user")
      expected = {:error, :invalid_user_format}
      assert Slack.create(payload) == expected
    end

    test "when actions field is invalid format, should return format error" do
      payload = Map.put(@action_payload, "actions", {:action, "BAD_FORMAT"})
      expected = {:error, :invalid_action_format}
      assert Slack.create(payload) == expected
    end

    test "with multiple values in actions param, should return struct with only first action assigned to :action" do
      action_a = %{"name" => "action_a", "value" => "val_1"}
      action_b = %{"name" => "action_b", "value" => "val_2"}
      payload = Map.put(@action_payload, "actions", [action_a, action_b])
      expected = 
        {:ok, %{__struct__: Slack,
          action: %{name: "action_a", value: "val_1"},
          team: %{id: "TEAM_ID", domain: "TEAM"},
          channel: %{id: "CH_ID", name: "CHANNEL"},
          user: %{id: "UID", name: "USER"},
          action_ts: "00000000", message_ts: "1111111",
          attachment_id: "ATTACH_ID", token: "TOKEN",
          callback_id: "123", original_message: %{},
          response_url: "RESP_URL", command: nil, text: nil}}
      assert Slack.create(payload) == expected
    end
  end

  describe "create/1 with slash command data" do
    test "when all fields are valid, should return struct with non-nil command fields" do
      expected = 
        {:ok, %{__struct__: Slack,
          command: "/slash_command", text: "hello",
          team: %{id: "TEAM_ID", domain: "TEAM"},
          channel: %{id: "CH_ID", name: "CHANNEL"},
          user: %{id: "UID", name: "USER"},
          action_ts: nil, message_ts: nil,
          action: nil, attachment_id: nil,
          callback_id: nil, original_message: nil,
          token: "TOKEN", response_url: "RESP_URL"}}
      assert Slack.create(@command_payload) == expected
    end

    test "when missing team_id field, should return format error" do
      payload = Map.delete(@command_payload, "team_id")
      expected = {:error, :invalid_team_format}
      assert Slack.create(payload) == expected
    end
    
    test "when missing channel_id field, should return format error" do
      payload = Map.delete(@command_payload, "channel_id")
      expected = {:error, :invalid_channel_format}
      assert Slack.create(payload) == expected
    end

    test "when missing user field, should return format error" do
      payload = Map.delete(@command_payload, "user_id")
      expected = {:error, :invalid_user_format}
      assert Slack.create(payload) == expected
    end
  end

  test "create/1 with no actions or commands params, should return :error" do
    payload = Map.drop(@command_payload, ["command", "actions"])
    expected = {:error, :invalid_slack_data}
    assert Slack.create(payload) == expected
  end
end

