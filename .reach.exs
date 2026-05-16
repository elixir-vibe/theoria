[
  layers: [
    public: ["Theoria"],
    dsl: "Theoria.DSL.*",
    library: "Theoria.Library.*",
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
      {:kernel, :library}
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
