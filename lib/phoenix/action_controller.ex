defmodule Slack.Phoenix.ActionController do
  @moduledoc """
  This is a helper module to use with a Phoenix controller to
  handle HTTP requests coming from Slack for Slash Commands or
  actions from Interactive Messages.

  You must provide a Slack token for the `__using__/1` macro that
  this module will use to verify incoming Slack requests. See the
  [Slack API docs] to obtain the token.

  ## Example

  ```
  defmodule App.SlackController do
    use Slack.Phoenix.ActionController, token: "TOKEN"

    import Plug.Conn

    def handle_action(action, conn, slack) do
      conn
      |> put_status(200)
      |> text("Working on this action")
    end

    def handle_action(command, conn, slack) do
      conn
      |> put_status(200)
      |> text("Working on this command")
    end
  end

  defmodule App.Router do
    use Phoenix.Router

    post "/*path", App.SlackController, :dispatch
  end
  ```
  ## Handling Requests

  Define a route in your Phoenix router with the `:dispatch` action
  to validate incoming requests and dispatch to the overridable
  functions `handle_action` or `handle_command`.

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

  Action request only fields (nil for command requests)
  * callback_id - string of callback_id from message attachment
  * action_ts - string timestamp when action occurred
  * message_ts - string timestamp when message containing action
    was posted
  * attachment_id - string id for specific attachment within message
  * original_message - original message JSON object

  See Slack docs for [responding to button actions] and [slash commands]

  [Slack API docs]: https://api.slack.com/
  [responding to button actions]: https://api.slack.com/docs/message-buttons
  [slash commands]: https://api.slack.com/slash-commands
  """
  defmacro __using__([token: token]) do
    quote do
      use Phoenix.Controller

      plug Slack.Plug.FetchSlackData
      plug Slack.Plug.VerifyToken, token: unquote(token)

      @spec dispatch(Plug.Conn.t, map) :: Plug.Conn.t
      def dispatch(%{private: %{slack_data: slack}} = conn, _),
        do: dispatch_slack(conn, slack)

      defp dispatch_slack(conn, nil),
        do: put_status(conn, 400)
      defp dispatch_slack(conn, %{action: action} = slack) when action != nil,
        do: apply(__MODULE__, :handle_action, [action, conn, slack])
      defp dispatch_slack(conn, %{command: command} = slack) when command != nil,
        do: apply(__MODULE__, :handle_command, [command, conn, slack])

      @spec handle_action(map, Plug.Conn.t, Slack.t) :: Plug.Conn.t
      def handle_action(_action, conn, _slack), do: conn

      @spec handle_command(binary, Plug.Conn.t, Slack.t) :: Plug.Conn.t
      def handle_command(_command, conn, _slack), do: conn

      defoverridable [handle_action: 3, handle_command: 3]
    end
  end
end
