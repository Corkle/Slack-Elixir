defmodule Slack.Plug.VerifyToken do
  @moduledoc """
  Checks `conn.private.slack_data` for `:token` and compares it to
  :token in the second function arguement list.
  `conn` is returned, unchanged, if the tokens are a match.
  If the slack data token does not match the argument token, the
  connection is halted and `conn.status` is set to 400.

  An error is raised if token argument is `nil`.
  """

  import Plug.Conn

  @lint {Credo.Check.Readability.Specs, false}
  @doc false
  def init(opts \\ []) do
    opts = Enum.into(opts, %{})
    %{token: Map.get(opts, :token, nil)}
  end

  @lint {Credo.Check.Readability.Specs, false}
  @doc false
  def call(conn, %{token: token}),
    do: verify_slack_token(conn, token)

  defp verify_slack_token(_conn, nil),
    do: raise(ArgumentError, message: "slack validation token cannot be nil")
  defp verify_slack_token(%{private: %{slack_data: %{token: from_token}}} = conn, token)
    when from_token == token,
    do: conn
  defp verify_slack_token(conn, _),
    do: bad_request(conn)

  defp bad_request(conn),
    do: conn |> put_status(400) |> halt
end
