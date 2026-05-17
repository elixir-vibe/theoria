defmodule Theoria.Equation.Pattern do
  @moduledoc "Equation compiler patterns."

  defmodule Var do
    @moduledoc "A variable pattern."
    @enforce_keys [:name]
    defstruct [:name]

    @type t :: %__MODULE__{name: atom()}
  end

  defmodule Wildcard do
    @moduledoc "A wildcard pattern."
    defstruct []

    @type t :: %__MODULE__{}
  end

  defmodule Constructor do
    @moduledoc "A constructor pattern with subpatterns."
    @enforce_keys [:name]
    defstruct [:name, args: []]

    @type t :: %__MODULE__{name: atom(), args: [Theoria.Equation.Pattern.t()]}
  end

  @type t :: Var.t() | Wildcard.t() | Constructor.t()

  @doc "Builds a variable pattern."
  @spec var(atom()) :: Var.t()
  def var(name) when is_atom(name), do: %Var{name: name}

  @doc "Builds a wildcard pattern."
  @spec wildcard() :: Wildcard.t()
  def wildcard, do: %Wildcard{}

  @doc "Builds a constructor pattern."
  @spec constructor(atom(), [t()]) :: Constructor.t()
  def constructor(name, args \\ []) when is_atom(name) and is_list(args) do
    %Constructor{name: name, args: args}
  end
end
