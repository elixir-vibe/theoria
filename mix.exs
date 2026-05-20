defmodule Theoria.MixProject do
  use Mix.Project

  @source_url "https://github.com/elixir-vibe/theoria"

  def project do
    [
      app: :theoria,
      version: "0.9.0-dev",
      elixir: "~> 1.19",
      description:
        "An Elixir-native proof/spec kernel inspired by trusted theorem prover kernels.",
      package: package(),
      source_url: @source_url,
      docs: docs(),
      aliases: aliases(),
      dialyzer: [
        plt_file: {:no_warn, "_build/dev/dialyxir_plt.plt"},
        plt_add_apps: [:mix]
      ],
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def cli do
    [preferred_envs: [ci: :test]]
  end

  defp aliases do
    [
      ci: [
        "compile --warnings-as-errors",
        "format --check-formatted",
        "credo --strict",
        "ex_dna",
        "reach.check --arch --smells",
        "dialyzer",
        "theoria.validate",
        "theoria.kernel.check",
        "test"
      ]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_dna, "~> 1.5", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:jason, "~> 1.4"},
      {:reach, "~> 2.3", only: [:dev, :test], runtime: false},
      {:stream_data, "~> 1.0", only: [:dev, :test]}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      extras: [
        "README.md",
        "CHANGELOG.md",
        "docs/roadmap.md",
        "docs/release_0_8.md",
        "docs/release_0_8_checklist.md",
        "docs/release_0_7.md",
        "docs/release_0_7_checklist.md",
        "docs/release_0_6.md",
        "docs/release_0_6_checklist.md",
        "docs/release_0_5.md",
        "docs/release_0_4.md",
        "docs/release_0_3.md",
        "docs/release_0_2.md",
        "docs/design.md",
        "docs/inductives.md",
        "docs/validation.md",
        "docs/assurance.md",
        "docs/obligations.md",
        "docs/public_api.md",
        "docs/reports.md",
        "docs/proof_capabilities.md",
        "docs/equations.md",
        "docs/kernel_spec.md",
        "docs/lean_validation.md",
        "docs/lean_alignment.md",
        "docs/lean_roadmap.md",
        "docs/theorem_modules.md",
        "docs/trusted_boundary.md",
        "LICENSE"
      ],
      groups_for_extras: [Guides: ~r/docs\//],
      groups_for_modules: [
        Core: [Theoria, Theoria.Term, Theoria.Level, Theoria.Context, Theoria.Env, Theoria.Error],
        Kernel: [Theoria.Kernel, Theoria.Normalize],
        "Theorem DSL": [
          Theoria.Syntax,
          Theoria.Elaborator,
          Theoria.DSL,
          Theoria.DSL.Theorem,
          Theoria.Prelude,
          Theoria.Theorem
        ],
        Inductives: ~r/^Theoria\.Inductive/,
        Equations: ~r/^Theoria\.Equation(?!\.Matcher)/,
        "Equation Matchers": ~r/^Theoria\.Equation\.Matcher/,
        "Rewrite and Simp": ~r/^Theoria\.(Rewrite|Simp)/,
        "Validation and Assurance":
          ~r/^Theoria\.(Validation|Kernel\.(ArtifactReplay|AssuranceSummary|Corpus|Differential|EnvironmentCorpus|GeneratedTerm|MetadataReplayReport|ProofStrategyReport|TheoremModuleReport))/,
        Libraries: ~r/^Theoria\.Library\./,
        "Lean Oracle Tooling": ~r/^Theoria\.Lean/
      ]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib docs mix.exs README.md CHANGELOG.md LICENSE .formatter.exs)
    ]
  end
end
