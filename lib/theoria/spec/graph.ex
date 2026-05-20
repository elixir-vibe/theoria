defmodule Theoria.Spec.Graph do
  @moduledoc """
  Small finite graph vocabulary for tool-generated claims.

  This module is intentionally Elixir-data-first. Reach and other tools can use
  it to normalize graph facts and validate concrete witnesses such as dependency
  paths before turning selected claims into Theoria obligations/certificates.
  The structural checks here are useful diagnostics, but they are not kernel
  proofs by themselves.
  """

  @type graph_node :: term()
  @type edge :: {graph_node(), graph_node()}
  @type t :: %__MODULE__{nodes: MapSet.t(graph_node()), edges: MapSet.t(edge())}

  @enforce_keys [:nodes, :edges]
  defstruct @enforce_keys

  defmodule PathClaim do
    @moduledoc "Structured witness that a finite graph path is valid."

    @type t :: %__MODULE__{
            from: Theoria.Spec.Graph.graph_node(),
            to: Theoria.Spec.Graph.graph_node(),
            path: [Theoria.Spec.Graph.graph_node()],
            valid?: boolean(),
            reason: atom() | nil
          }

    @enforce_keys [:from, :to, :path, :valid?]
    defstruct [:from, :to, :path, :valid?, :reason]

    @doc "Returns true when the path witness is structurally valid."
    @spec valid?(t()) :: boolean()
    def valid?(%__MODULE__{valid?: valid?}), do: valid?

    @doc "Returns the invalidity reason, if any."
    @spec reason(t()) :: atom() | nil
    def reason(%__MODULE__{reason: reason}), do: reason
  end

  @doc "Builds a finite directed graph from edge pairs."
  @spec new([edge()]) :: t()
  def new(edges) when is_list(edges) do
    edge_set = MapSet.new(edges)

    node_set =
      Enum.reduce(edges, MapSet.new(), fn {from, to}, nodes ->
        nodes |> MapSet.put(from) |> MapSet.put(to)
      end)

    %__MODULE__{nodes: node_set, edges: edge_set}
  end

  @doc "Returns graph nodes."
  @spec nodes(t()) :: MapSet.t(graph_node())
  def nodes(%__MODULE__{nodes: nodes}), do: nodes

  @doc "Returns graph edges."
  @spec edges(t()) :: MapSet.t(edge())
  def edges(%__MODULE__{edges: edges}), do: edges

  @doc "Returns true when the graph has an edge `from -> to`."
  @spec edge?(t(), graph_node(), graph_node()) :: boolean()
  def edge?(%__MODULE__{edges: edges}, from, to), do: MapSet.member?(edges, {from, to})

  @doc "Returns true when every adjacent pair in `path` is an edge in the graph."
  @spec path?(t(), [graph_node()]) :: boolean()
  def path?(%__MODULE__{} = graph, path), do: path_reason(graph, path) == nil

  @doc "Builds a path witness claim with validation status and reason."
  @spec path_claim(t(), graph_node(), graph_node(), [graph_node()]) :: PathClaim.t()
  def path_claim(%__MODULE__{} = graph, from, to, path) when is_list(path) do
    reason = path_claim_reason(graph, from, to, path)

    %PathClaim{from: from, to: to, path: path, valid?: is_nil(reason), reason: reason}
  end

  defp path_claim_reason(_graph, _from, _to, []), do: :empty_path
  defp path_claim_reason(_graph, from, _to, [first | _]) when first != from, do: :wrong_start

  defp path_claim_reason(graph, _from, to, path) do
    if List.last(path) != to do
      :wrong_end
    else
      path_reason(graph, path)
    end
  end

  defp path_reason(_graph, []), do: :empty_path
  defp path_reason(_graph, [_single]), do: nil

  defp path_reason(graph, [_left, _right | _rest] = path) do
    path
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.find_value(fn [from, to] ->
      unless edge?(graph, from, to), do: :missing_edge
    end)
  end
end
