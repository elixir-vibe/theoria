defimpl Theoria.Lean.Encodable, for: Theoria.Term.Sort do
  alias Theoria.Lean.Encode

  def encode(%{level: level}, _context), do: Encode.sort(level)
end

defimpl Theoria.Lean.Encodable, for: Theoria.Term.Const do
  alias Theoria.Lean.Encode

  def encode(%{name: name}, _context), do: Encode.constant(name)
end

defimpl Theoria.Lean.Encodable, for: Theoria.Term.BVar do
  def encode(%{index: index}, context), do: Enum.fetch!(context, index)
end

defimpl Theoria.Lean.Encodable, for: Theoria.Term.App do
  alias Theoria.Lean.Encode
  alias Theoria.Lean.Encode.Application
  alias Theoria.Term

  def encode(app, context) do
    {fun, args} = Term.Application.collect(app)

    case Application.encode(fun, args, context) do
      {:ok, source} -> source
      :error -> encode_regular_app(fun, args, context)
    end
  end

  defp encode_regular_app(fun, args, context) do
    fun
    |> Encode.term(context)
    |> Encode.apply_source(Enum.map(args, &Encode.term(&1, context)))
  end
end

defimpl Theoria.Lean.Encodable, for: Theoria.Term.Lam do
  alias Theoria.Lean.Encode
  alias Theoria.Term.Lam

  def encode(%Lam{name: name, domain: domain, body: body}, context) do
    binder = Encode.fresh_name(name, context)

    "(fun (#{binder} : #{Encode.term(domain, context)}) => #{Encode.term(body, [binder | context])})"
  end
end

defimpl Theoria.Lean.Encodable, for: Theoria.Term.Forall do
  alias Theoria.Lean.Encode
  alias Theoria.Term.Forall

  def encode(%Forall{name: :_, domain: domain, body: body}, context) do
    "(#{Encode.term(domain, context)} -> #{Encode.term(body, ["_" | context])})"
  end

  def encode(%Forall{name: name, domain: domain, body: body}, context) do
    binder = Encode.fresh_name(name, context)

    "(forall (#{binder} : #{Encode.term(domain, context)}), #{Encode.term(body, [binder | context])})"
  end
end

defimpl Theoria.Lean.Encodable, for: Theoria.Term.Let do
  alias Theoria.Lean.Encode
  alias Theoria.Term.Let

  def encode(%Let{name: name, type: type, value: value, body: body}, context) do
    binder = Encode.fresh_name(name, context)

    "(let #{binder} : #{Encode.term(type, context)} := #{Encode.term(value, context)}; #{Encode.term(body, [binder | context])})"
  end
end

defimpl Theoria.Lean.Encodable, for: Theoria.Term.Eq do
  alias Theoria.Lean.Encode
  alias Theoria.Term.Eq

  def encode(%Eq{left: left, right: right}, context) do
    "(#{Encode.term(left, context)} = #{Encode.term(right, context)})"
  end
end

defimpl Theoria.Lean.Encodable, for: Theoria.Term.Refl do
  alias Theoria.Lean.Encode
  alias Theoria.Term.Refl

  def encode(%Refl{value: value}, context) do
    value = Encode.term(value, context)
    "(show #{value} = #{value} from rfl)"
  end
end

defimpl Theoria.Lean.Encodable, for: Theoria.Term.EqRec do
  alias Theoria.Lean.Encode
  alias Theoria.Term.EqRec

  def encode(%EqRec{motive: motive, base: base, proof: proof}, context) do
    "(tEqRec #{Encode.term(motive, context)} #{Encode.term(base, context)} #{Encode.term(proof, context)})"
  end
end
