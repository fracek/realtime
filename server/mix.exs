defmodule Realtime.MixProject do
  use Mix.Project

  @version "0.0.0-automated"
  @elixir "~> 1.5"

  def project do
    [
      app: :realtime,
      version: @version,
      elixir: @elixir,
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Realtime.Application, []},
      extra_applications: [:logger, :runtime_tools, :httpoison]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.5"},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_html, "~> 2.14"},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      {:gettext, "~> 0.18"},
      {:httpoison, "~> 1.8"},
      {:jason, "~> 1.2.2"},
      {:joken, "~> 2.3.0"},
      {:plug_cowboy, "~> 2.4"},
      {:epgsql, "~> 4.5"},
      {:retry, "~> 0.14"},
      {:ecto_sql, "~> 3.4"},
      {:oban, "~> 2.4"},
      {:postgrex, "~> 0.15.8"},
      {:ex_json_schema, "~> 0.8.0-rc1"},
      {:warpath, "~> 0.6.0"},
      {:nimble_parsec, "~> 1.1"},
      {:temp, "~> 0.4.7"},
      #{:decimal, "~> 2.0.0", override: true},
      {:mock, "~> 0.3.0", only: :test}
    ]
  end

  defp aliases do
    [
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
