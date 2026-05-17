defmodule Theoria.Syntax do
  @moduledoc """
  Named surface terms for building Theoria core terms.

  Surface terms are not trusted. They must be elaborated to `Theoria.Term`
  values and checked by `Theoria.Kernel` before they can prove anything.
  """

  defmodule Sort do
    @moduledoc "A named-syntax universe level."
    @enforce_keys [:level]
    defstruct [:level]

    @type t :: %__MODULE__{level: Theoria.Level.t()}
  end

  defmodule Var do
    @moduledoc "A named bound variable."
    @enforce_keys [:name]
    defstruct [:name]

    @type t :: %__MODULE__{name: atom()}
  end

  defmodule Const do
    @moduledoc "A named environment constant."
    @enforce_keys [:name]
    defstruct [:name, levels: []]

    @type t :: %__MODULE__{name: atom(), levels: [Theoria.Level.t()]}
  end

  defmodule App do
    @moduledoc "Function application."
    @enforce_keys [:fun, :arg]
    defstruct [:fun, :arg]

    @type t :: %__MODULE__{fun: Theoria.Syntax.t(), arg: Theoria.Syntax.t()}
  end

  defmodule Lam do
    @moduledoc "Lambda abstraction with a named binder."
    @enforce_keys [:name, :domain, :body]
    defstruct [:name, :domain, :body]

    @type t :: %__MODULE__{
            name: atom(),
            domain: Theoria.Syntax.t(),
            body: Theoria.Syntax.t()
          }
  end

  defmodule Forall do
    @moduledoc "Dependent function type with a named binder."
    @enforce_keys [:name, :domain, :body]
    defstruct [:name, :domain, :body]

    @type t :: %__MODULE__{
            name: atom(),
            domain: Theoria.Syntax.t(),
            body: Theoria.Syntax.t()
          }
  end

  defmodule Let do
    @moduledoc "Local definition with a named binder."
    @enforce_keys [:name, :type, :value, :body]
    defstruct [:name, :type, :value, :body]

    @type t :: %__MODULE__{
            name: atom(),
            type: Theoria.Syntax.t(),
            value: Theoria.Syntax.t(),
            body: Theoria.Syntax.t()
          }
  end

  defmodule Eq do
    @moduledoc "Named-syntax propositional equality."
    @enforce_keys [:type, :left, :right]
    defstruct [:type, :left, :right]

    @type t :: %__MODULE__{
            type: Theoria.Syntax.t(),
            left: Theoria.Syntax.t(),
            right: Theoria.Syntax.t()
          }
  end

  defmodule Refl do
    @moduledoc "Named-syntax reflexivity proof."
    @enforce_keys [:value]
    defstruct [:value]

    @type t :: %__MODULE__{value: Theoria.Syntax.t()}
  end

  defmodule EqRec do
    @moduledoc "Named-syntax equality recursor."
    @enforce_keys [:type, :motive, :base, :proof]
    defstruct [:type, :motive, :base, :proof]

    @type t :: %__MODULE__{
            type: Theoria.Syntax.t(),
            motive: Theoria.Syntax.t(),
            base: Theoria.Syntax.t(),
            proof: Theoria.Syntax.t()
          }
  end

  @type t ::
          Sort.t()
          | Var.t()
          | Const.t()
          | App.t()
          | Lam.t()
          | Forall.t()
          | Let.t()
          | Eq.t()
          | Refl.t()
          | EqRec.t()

  @spec sort(non_neg_integer() | Theoria.Level.t()) :: Sort.t()
  def sort(level), do: %Sort{level: Theoria.Level.cast!(level)}

  @spec var(atom()) :: Var.t()
  def var(name) when is_atom(name), do: %Var{name: name}

  @spec const(atom(), [non_neg_integer() | Theoria.Level.t()]) :: Const.t()
  def const(name, levels \\ []) when is_atom(name) and is_list(levels) do
    %Const{name: name, levels: Enum.map(levels, &Theoria.Level.cast!/1)}
  end

  @spec app(t(), t()) :: App.t()
  def app(fun, arg), do: %App{fun: fun, arg: arg}

  @spec lam(atom(), t(), t()) :: Lam.t()
  def lam(name, domain, body) when is_atom(name), do: %Lam{name: name, domain: domain, body: body}

  @spec forall(atom(), t(), t()) :: Forall.t()
  def forall(name, domain, body) when is_atom(name),
    do: %Forall{name: name, domain: domain, body: body}

  @spec arrow(t(), t()) :: Forall.t()
  def arrow(domain, codomain), do: forall(:_, domain, codomain)

  @spec let(atom(), t(), t(), t()) :: Let.t()
  def let(name, type, value, body) when is_atom(name) do
    %Let{name: name, type: type, value: value, body: body}
  end

  @spec eq(t(), t(), t()) :: Eq.t()
  def eq(type, left, right), do: %Eq{type: type, left: left, right: right}

  @spec refl(t()) :: Refl.t()
  def refl(value), do: %Refl{value: value}

  @spec eq_rec(t(), t(), t(), t()) :: EqRec.t()
  def eq_rec(type, motive, base, proof) do
    %EqRec{type: type, motive: motive, base: base, proof: proof}
  end

  @doc "Converts a core de Bruijn term back to named syntax using `context` for bound variables."
  @spec from_core(Theoria.Term.t(), [atom()]) :: t()
  def from_core(term, context \\ [])

  def from_core(%Theoria.Term.Sort{level: level}, _context), do: sort(level)

  def from_core(%Theoria.Term.Const{name: name, levels: levels}, _context),
    do: const(name, levels)

  def from_core(%Theoria.Term.BVar{index: index}, context),
    do: context |> Enum.fetch!(index) |> var()

  def from_core(%Theoria.Term.App{fun: fun, arg: arg}, context),
    do: app(from_core(fun, context), from_core(arg, context))

  def from_core(%Theoria.Term.Forall{name: name, domain: domain, body: body}, context) do
    forall(name, from_core(domain, context), from_core(body, [name | context]))
  end

  def from_core(%Theoria.Term.Lam{name: name, domain: domain, body: body}, context) do
    lam(name, from_core(domain, context), from_core(body, [name | context]))
  end

  def from_core(%Theoria.Term.Let{name: name, type: type, value: value, body: body}, context) do
    let(
      name,
      from_core(type, context),
      from_core(value, context),
      from_core(body, [name | context])
    )
  end

  def from_core(%Theoria.Term.Eq{type: type, left: left, right: right}, context) do
    eq(from_core(type, context), from_core(left, context), from_core(right, context))
  end

  def from_core(%Theoria.Term.Refl{value: value}, context), do: refl(from_core(value, context))

  def from_core(
        %Theoria.Term.EqRec{type: type, motive: motive, base: base, proof: proof},
        context
      ) do
    eq_rec(
      from_core(type, context),
      from_core(motive, context),
      from_core(base, context),
      from_core(proof, context)
    )
  end
end
