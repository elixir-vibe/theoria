defmodule TheoriaDownstreamSmoke.MixProject do
  use Mix.Project

  def project do
    [
      app: :theoria_downstream_smoke,
      version: "0.1.0",
      elixir: "~> 1.19",
      deps: deps(),
      docs: [main: "readme", extras: ["README.md"]]
    ]
  end

  def application, do: [extra_applications: [:logger]]

  defp deps do
    [
      {:theoria, path: System.get_env("THEORIA_PATH", "../../..")},
      {:ex_doc, "~> 0.34", only: [:dev, :test], runtime: false}
    ]
  end
end
