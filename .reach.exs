[
  layers: [
    public: ["Theoria"],
    dsl: "Theoria.DSL.*",
    library: "Theoria.Library.*",
    rewrite: ["Theoria.Rewrite", "Theoria.Rewrite.*", "Theoria.Simp", "Theoria.Simp.*"],
    lean: "Theoria.Lean.*",
    mix_tasks: "Mix.Tasks.Theoria.*",
    kernel: [
      "Theoria.Context",
      "Theoria.Env",
      "Theoria.Env.*",
      "Theoria.Error",
      "Theoria.Kernel",
      "Theoria.Normalize",
      "Theoria.Term",
      "Theoria.Term.*"
    ]
  ],
  deps: [
    forbidden: [
      {:kernel, :dsl},
      {:kernel, :library},
      {:kernel, :rewrite},
      {:kernel, :lean},
      {:kernel, :mix_tasks}
    ]
  ],
  calls: [
    forbidden: []
  ],
  source: [
    forbidden_modules: [],
    forbidden_files: []
  ]
]
