defmodule Theoria.Spec.Finite do
  @moduledoc """
  Small finite-set vocabulary for tool-generated claims.

  This module normalizes finite collections to `MapSet` and builds structured
  claims for common checks such as subset and no-new-items. It is useful for
  Reach/Vibe-style facts where tools need to say "all reported items are allowed"
  or "this edit introduced no new members" before selected claims become
  obligations/certificates.
  """

  @type item :: term()
  @type set :: MapSet.t(item())

  defmodule SubsetClaim do
    @moduledoc "Structured witness that every item in `subset` is present in `superset`."

    @type t :: %__MODULE__{
            subset: Theoria.Spec.Finite.set(),
            superset: Theoria.Spec.Finite.set(),
            valid?: boolean(),
            missing: [Theoria.Spec.Finite.item()]
          }

    @enforce_keys [:subset, :superset, :valid?, :missing]
    defstruct @enforce_keys

    @doc "Returns true when the subset claim is valid."
    @spec valid?(t()) :: boolean()
    def valid?(%__MODULE__{valid?: valid?}), do: valid?
  end

  defmodule NoNewClaim do
    @moduledoc "Structured witness that `new` introduces no items outside `old`."

    @type t :: %__MODULE__{
            old: Theoria.Spec.Finite.set(),
            new: Theoria.Spec.Finite.set(),
            valid?: boolean(),
            added: [Theoria.Spec.Finite.item()]
          }

    @enforce_keys [:old, :new, :valid?, :added]
    defstruct @enforce_keys

    @doc "Returns true when no new items were introduced."
    @spec valid?(t()) :: boolean()
    def valid?(%__MODULE__{valid?: valid?}), do: valid?
  end

  @doc "Normalizes an enumerable into a `MapSet`."
  @spec set(Enumerable.t()) :: set()
  def set(items), do: MapSet.new(items)

  @doc "Returns true when an item is a member of the finite collection."
  @spec member?(Enumerable.t(), item()) :: boolean()
  def member?(items, item), do: items |> set() |> MapSet.member?(item)

  @doc "Returns true when every item in `subset` is in `superset`."
  @spec subset?(Enumerable.t(), Enumerable.t()) :: boolean()
  def subset?(subset, superset), do: MapSet.subset?(set(subset), set(superset))

  @doc "Returns items in `left` that are not in `right`."
  @spec difference(Enumerable.t(), Enumerable.t()) :: [item()]
  def difference(left, right) do
    left
    |> set()
    |> MapSet.difference(set(right))
    |> Enum.sort_by(&inspect/1)
  end

  @doc "Builds a structured subset claim."
  @spec subset_claim(Enumerable.t(), Enumerable.t()) :: SubsetClaim.t()
  def subset_claim(subset, superset) do
    missing = difference(subset, superset)

    %SubsetClaim{
      subset: set(subset),
      superset: set(superset),
      valid?: missing == [],
      missing: missing
    }
  end

  @doc "Builds a structured claim that `new` introduced no items outside `old`."
  @spec no_new_claim(Enumerable.t(), Enumerable.t()) :: NoNewClaim.t()
  def no_new_claim(old, new) do
    added = difference(new, old)

    %NoNewClaim{
      old: set(old),
      new: set(new),
      valid?: added == [],
      added: added
    }
  end
end
