defmodule Slack.Mixfile do
  use Mix.Project

  def project do
    [app: :slack,
     version: "0.1.0",
     elixir: "~> 1.4",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps do
    [{:phoenix, "~> 1.2.1"},
     {:credo, "~> 0.5", only: [:dev, :test]},
     {:ex_doc, ">= 0.0.0", only: :dev}]
  end

  defp description do
    """
    Handle Slack slash command and interactive message HTTP requests in Elixir
    """
  end

  defp package do
    [
      name: :slack_interactive,
      maintainers: ["Corey McDaniel"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/Corkle/Slack-Elixir"}
    ]
  end
end
