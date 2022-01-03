defmodule DynamicDnsClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :dynamic_dns_client,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {DynamicDnsClient.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 1.8"}
    ]
  end
end
