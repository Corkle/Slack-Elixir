defmodule Slack.Plug.FetchSlackDataTest do
  use ExUnit.Case

  import Slack.PlugTestHelper
   
  alias Slack.Plug.FetchSlackData 

  test "with invalid Slack request params, should assign nil to :slack_data in conn.private" do
    conn = build_conn()
    res = FetchSlackData.call(conn, %{})
    expected = %{slack_data: nil}
    assert res.private == expected
  end

  describe "with action payload" do
    test "when payload is not json format, should raise ArgumentError" do
      conn = build_conn(%{"payload" => 777})
      assert_raise ArgumentError, fn ->
        FetchSlackData.call(conn, %{})
      end
    end

    test "when payload is valid json without expected slack action,
      should assign nil to :slack_data in conn.private" do
      slack =
        %{team: %{id: "TEAM_ID", domain: "TEAM"},
          channel: %{id: "CH_ID", name: "CHANNEL"},
          user: %{id: "UID", name: "USER"},
          message_ts: "110000", token: "SLACKTOKEN", response_url: "url"}
      {:ok, json} = Poison.encode(slack) 
      conn = build_conn(%{"payload" => json}) 
      res = FetchSlackData.call(conn, %{})
      expected = %{slack_data: nil}
      assert res.private == expected
    end

    test "with nil value for actions field, should assign nil to :slack_data in conn.private" do
      slack =
        %{actions: nil, action_ts: "000000",
          team: %{id: "TEAM_ID", domain: "TEAM"},
          channel: %{id: "CH_ID", name: "CHANNEL"},
          user: %{id: "UID", name: "USER"},
          message_ts: "110000",
          token: "SLACKTOKEN", response_url: "url"}
      {:ok, json} = Poison.encode(slack) 
      conn = build_conn(%{"payload" => json}) 
      res = FetchSlackData.call(conn, %{})
      expected = %{slack_data: nil}
      assert res.private == expected
    end

    test "when payload is valid json with expected slack action,
      should assign private field :slack_data as Slack struct." do
      slack =
        %{actions: [%{name: "ACTION", value: "VAL"}],
          team: %{id: "TEAM_ID", domain: "TEAM"},
          channel: %{id: "CH_ID", name: "CHANNEL"},
          user: %{id: "UID", name: "USER"},
          message_ts: "110000", action_ts: "000000",
          token: "SLACKTOKEN", response_url: "url"}
      {:ok, json} = Poison.encode(slack) 
      conn = build_conn(%{"payload" => json}) 
      res = FetchSlackData.call(conn, %{})
      expected =
        %{slack_data:
          %{action: %{name: "ACTION", value: "VAL"},
            team: %{id: "TEAM_ID", domain: "TEAM"},
            channel: %{id: "CH_ID", name: "CHANNEL"},
            user: %{id: "UID", name: "USER"},
            message_ts: "110000", action_ts: "000000",
            token: "SLACKTOKEN", response_url: "url",
            __struct__: Slack, command: nil, text: nil,
            attachment_id: nil, callback_id: nil, original_message: nil}}
      assert res.private == expected
    end

    test "with one action in actions field, should assign :action field in :slack_data as a map" do
      slack =
        %{actions: [%{name: "ACTION_NAME", value: "ACTION_VALUE"}],
          team: %{id: "TEAM_ID", domain: "TEAM"},
          channel: %{id: "CH_ID", name: "CHANNEL"},
          user: %{id: "UID", name: "USER"},
          message_ts: "110000", action_ts: "000000",
          token: "SLACKTOKEN", response_url: "url"}
      {:ok, json} = Poison.encode(slack) 
      conn = build_conn(%{"payload" => json}) 
      res = FetchSlackData.call(conn, %{})
      assert %{name: "ACTION_NAME", value: "ACTION_VALUE"} == res.private.slack_data.action
    end

    test "with more than one action in actions field, should assign only first action in :action field in :slack_data" do
      slack =
        %{actions: [%{name: "ACTION_A", value: "VALUE_A"},
                    %{name: "ACTION_B", value: "VALUE_B"}],
          team: %{id: "TEAM_ID", domain: "TEAM"},
          channel: %{id: "CH_ID", name: "CHANNEL"},
          user: %{id: "UID", name: "USER"},
          message_ts: "110000", action_ts: "000000",
          token: "SLACKTOKEN", response_url: "url"}
      {:ok, json} = Poison.encode(slack) 
      conn = build_conn(%{"payload" => json}) 
      res = FetchSlackData.call(conn, %{})
      assert %{name: "ACTION_A", value: "VALUE_A"} == res.private.slack_data.action
    end

    test "with action that does not have a value in actions field, should assign nil to :slack_data in conn.private" do
      slack =
        %{actions: [%{name: "ACTION"}], action_ts: "000000",
          team: %{id: "TEAM_ID", domain: "TEAM"},
          channel: %{id: "CH_ID", name: "CHANNEL"},
          user: %{id: "UID", name: "USER"},
          message_ts: "110000",
          token: "SLACKTOKEN", response_url: "url"}
      {:ok, json} = Poison.encode(slack) 
      conn = build_conn(%{"payload" => json}) 
      res = FetchSlackData.call(conn, %{})
      expected = %{slack_data: nil}
      assert res.private == expected
    end
  end

  describe "with slash command params" do
    test "when missing command field, should assign nil to :slack_data in conn.private" do
      slack =
        %{text: "hello",
          team_id: "TEAM_ID", team_domain: "TEAM",
          channel_id: "CH_ID", channel_name: "CHANNEL",
          user_id: "UID", user_name: "USER",
          token: "TOKEN", response_url: "RESP_URL"}
      conn = build_conn(slack) 
      res = FetchSlackData.call(conn, %{})
      expected = %{slack_data: nil}
      assert res.private == expected
    end

    test "with valid command field, should assign private field :slack_data as Slack struct." do
      slack =
        %{command: "/slash_command", text: "hello",
          team_id: "TEAM_ID", team_domain: "TEAM",
          channel_id: "CH_ID", channel_name: "CHANNEL",
          user_id: "UID", user_name: "USER",
          token: "SLACKTOKEN", response_url: "RESP_URL"}
      conn = build_conn(slack) 
      res = FetchSlackData.call(conn, %{})
      expected =
        %{slack_data: 
          %{command: "/slash_command", text: "hello",
            team: %{id: "TEAM_ID", domain: "TEAM"},
            channel: %{id: "CH_ID", name: "CHANNEL"},
            user: %{id: "UID", name: "USER"},
            message_ts: nil, action_ts: nil,
            token: "SLACKTOKEN", response_url: "RESP_URL",
            __struct__: Slack, action: nil, attachment_id: nil,
            callback_id: nil, original_message: nil}}
      assert res.private == expected
    end 
  end
end
