defimpl Jason.Encoder, for: Theoria.Equation.Identity do
  alias Theoria.Equation.Identity

  def encode(identity, opts), do: Jason.Encode.string(Identity.format(identity), opts)
end

defimpl Jason.Encoder, for: Theoria.Equation.Realized do
  def encode(realized, opts) do
    Jason.Encode.map(
      %{
        identity: realized.identity,
        type: inspect(realized.type),
        proof: inspect(realized.proof),
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
        proof_status: step.proof_status,
        has_proof: not is_nil(step.proof),
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
        proof_status: step.proof_status,
        has_proof: not is_nil(step.proof),
        source: step.source
      },
      opts
    )
  end
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
        realized: result.realized
      },
      opts
    )
  end
end
