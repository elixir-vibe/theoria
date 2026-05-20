defimpl Jason.Encoder, for: Theoria.Equality.Chain.Result do
  def encode(result, opts) do
    Jason.Encode.map(
      %{
        strategy: result.strategy,
        has_proof: not is_nil(result.proof)
      },
      opts
    )
  end
end

defimpl Jason.Encoder, for: Theoria.Rewrite.Proof.Capability.Entry do
  def encode(entry, opts) do
    Jason.Encode.map(
      %{
        path: entry.path,
        capability: entry.capability
      },
      opts
    )
  end
end

defimpl Jason.Encoder, for: Theoria.Rewrite.Proof.Capability do
  def encode(capability, opts) do
    Jason.Encode.map(
      %{
        supported: capability.supported?,
        reason: capability.reason,
        description: capability.description,
        inner: capability.inner
      },
      opts
    )
  end
end

defimpl Jason.Encoder, for: Theoria.Rewrite.Proof.Result do
  def encode(result, opts) do
    Jason.Encode.map(
      %{
        proof_status: result.status,
        proof_capability: result.capability,
        has_proof: not is_nil(result.proof)
      },
      opts
    )
  end
end

defimpl Jason.Encoder, for: Theoria.Theorem.ModuleReport do
  def encode(report, opts) do
    Jason.Encode.map(
      %{
        module: inspect(report.module),
        theorem_names: report.theorem_names,
        theorem_count: report.theorem_count,
        installed: report.installed?,
        axioms: report.axioms
      },
      opts
    )
  end
end

defimpl Jason.Encoder, for: Theoria.Theorem.Report do
  def encode(report, opts) do
    Jason.Encode.map(%{modules: report.modules, total: report.total}, opts)
  end
end

defimpl Jason.Encoder, for: Theoria.Level.Solver.Explanation do
  def encode(explanation, opts) do
    Jason.Encode.map(
      %{
        constraint: inspect(explanation.constraint),
        status: explanation.status,
        rule: explanation.rule
      },
      opts
    )
  end
end

defimpl Jason.Encoder, for: Theoria.Equation.Summary do
  def encode(summary, opts), do: Jason.Encode.map(Map.from_struct(summary), opts)
end

defimpl Jason.Encoder, for: Theoria.Equation.Identity do
  alias Theoria.Equation.Identity

  def encode(identity, opts), do: Jason.Encode.string(Identity.format(identity), opts)
end

defimpl Jason.Encoder, for: Theoria.Equation.Report.Entry do
  def encode(entry, opts) do
    Jason.Encode.map(
      %{
        definition: entry.definition,
        identities: entry.identities,
        unfold_identity: entry.unfold_identity,
        matcher_identities: entry.matcher_identities,
        realized: entry.realized
      },
      opts
    )
  end
end

defimpl Jason.Encoder, for: Theoria.Equation.Report do
  def encode(report, opts) do
    Jason.Encode.map(
      %{
        equations: report.equations,
        registry_entries: report.registry_entries
      },
      opts
    )
  end
end

defimpl Jason.Encoder, for: Theoria.Equation.Realized do
  def encode(realized, opts) do
    Jason.Encode.map(
      %{
        identity: realized.identity,
        type: inspect(realized.type),
        proof: inspect(realized.proof),
        proof_strategy: realized.proof_strategy,
        universe_params: realized.universe_params
      },
      opts
    )
  end
end

defimpl Jason.Encoder, for: Theoria.Rewrite.Step do
  def encode(step, opts) do
    Jason.Encode.map(
      %{
        rule: step.rule.name,
        before: inspect(step.before),
        after: inspect(step.after),
        path: step.path,
        proof: step.proof_result,
        substitution: encode_substitution(step.substitution)
      },
      opts
    )
  end

  defp encode_substitution(nil), do: nil

  defp encode_substitution(substitution) do
    Map.new(substitution, fn {index, term} -> {Integer.to_string(index), inspect(term)} end)
  end
end

defimpl Jason.Encoder, for: Theoria.Simp.Step do
  alias Theoria.Equation.Identity

  def encode(step, opts) do
    Jason.Encode.map(
      %{
        rule: Identity.format_declaration(step.rule),
        before: inspect(step.before),
        after: inspect(step.after),
        path: step.path,
        proof: step.proof_result,
        source: step.source
      },
      opts
    )
  end
end

defimpl Jason.Encoder, for: Theoria.Simp.ExampleReport do
  def encode(report, opts) do
    Jason.Encode.map(
      %{
        name: report.name,
        stopped: report.stopped,
        proof_checked: report.proof_checked,
        result: report.result
      },
      opts
    )
  end
end

defimpl Jason.Encoder, for: Theoria.Simp.Report do
  def encode(report, opts), do: Jason.Encode.map(%{examples: report.examples}, opts)
end

defimpl Jason.Encoder, for: Theoria.Simp.Result do
  def encode(result, opts) do
    Jason.Encode.map(
      %{
        input: inspect(result.input),
        term: inspect(result.term),
        stopped: result.stopped,
        steps: result.steps,
        proof_checked: not is_nil(result.realized),
        proof_strategy: result.proof_strategy,
        proof_status_counts: Theoria.Simp.Result.proof_status_counts(result),
        realized: result.realized
      },
      opts
    )
  end
end
