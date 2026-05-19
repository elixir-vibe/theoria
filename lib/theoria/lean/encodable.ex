defprotocol Theoria.Lean.Encodable do
  @moduledoc "Experimental before 1.0; the shape may change. Protocol for rendering Theoria structures as Lean oracle source."

  @fallback_to_any true

  @doc "Encodes a value as Lean source with a de Bruijn context."
  @spec encode(t(), [String.t()]) :: String.t()
  def encode(value, context)
end

defimpl Theoria.Lean.Encodable, for: Any do
  def encode(value, _context) do
    raise Protocol.UndefinedError,
      protocol: Theoria.Lean.Encodable,
      value: value,
      description: "cannot encode value as Lean source"
  end
end
