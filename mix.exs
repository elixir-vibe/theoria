defmodule Theoria.MixProject do
  use Mix.Project

  def project do
    [
      app: :theoria,
      version: "0.1.0",
      elixir: "~> 1.19",
      description:
        "An Elixir-native proof/spec kernel inspired by trusted theorem prover kernels.",
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps, do: []

  defp package do
    [
      licenses: ["MIT"],
      links: %{}
    ]
  end
end
