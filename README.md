# Slack

A simple wrapper for handling interactive Slack HTTP requests.

Currently, only [slash command] and [interactive message button] requests are supported.

Documentation can be found at [https://hexdocs.pm/slack_interactive](://hexdocs.pm/slack_interactive).

[slash command]: https://api.slack.com/slash-commands
[interactive message button]: https://api.slack.com/docs/message-buttons

## Installation

The package can be installed by adding `slack_interactive` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:slack_interactive, "~> 0.1.0"}]
end
```

## With Phoenix Controllers

Use `Slack.Phoenix.ActionController` in your Phoenix controllers with
your validation token provided by Slack. Valid Slack requests will be
forwarded to `handle_action` or `handle_command` respective to the
request type.

  ```elixir
  defmodule App.SlackController do
    use Slack.Phoenix.ActionController, token: "SLACK_TOKEN"

    import Plug.Conn

    def handle_action(action, conn, slack) do
      conn
      |> put_status(200)
      |> text("Working on this action")
    end

    def handle_command(command, conn, slack) do
      conn
      |> put_status(200)
      |> text("Working on this command")
    end
  end
  ```

## Handling Requests

  Define a route in your Phoenix router with the `:dispatch` action
  to validate incoming requests and dispatch to the overridable
  functions `handle_action` or `handle_command`.

  ```
  defmodule App.Router do
    use Phoenix.Router

    post "/slack/*path", App.SlackController, :dispatch
  end
  ```

  If an incoming request contains a matching validation token, either
  `handle_action` or `handle_command` will be called. Override these
  functions in your controller to manipulate the validated Slack data
  and respond to the request. The following arugments are passed to
  these functions:
  * `action` or `command`: Either the action `map` or command `string`
  from the request.
  * `conn`: The incoming request as a `Plug.Conn`.
  * `slack`: The incoming request parameters converted to a `Slack`
  struct.

  A `Plug.Conn` is expected as the return value for these functions.

## Slack Argument

  The third argument passed to the handle functions contains the
  below fields. The default value of these fields is `nil` if the
  incoming request did not contain a matching field name.

  * action - map with :name and :value for action request (action
    request only)
  * command - slash command string (command request only)
  * text - the text string following the slash command (command
    request only)
  * team - map with :domain and :id for Slack team
  * channel - map with :name and :id for Slack channel
  * user - map with :name and :id for Slack user
  * token - validation token used to confirm request came from Slack
  * reponse_url - string containing URL for delayed response to request


  Action request only fields (defaults to `nil` for command requests):
  * callback_id - string of callback_id from message attachment
  * action_ts - string timestamp when action occurred
  * message_ts - string timestamp when message containing action
    was posted
  * attachment_id - string id for specific attachment within message
  * original_message - original message JSON object

  See Slack docs for [responding to button actions] and [slash commands]

  [responding to button actions]: https://api.slack.com/docs/message-buttons
  [slash commands]: https://api.slack.com/slash-commands
  """
