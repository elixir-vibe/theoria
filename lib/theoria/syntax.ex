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

    @type t :: %__MODULE__{level: non_neg_integer()}
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
    defstruct [:name]

    @type t :: %__MODULE__{name: atom()}
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

  @type t :: Sort.t() | Var.t() | Const.t() | App.t() | Lam.t() | Forall.t() | Eq.t() | Refl.t()

  @spec sort(non_neg_integer()) :: Sort.t()
  def sort(level) when is_integer(level) and level >= 0, do: %Sort{level: level}

  @spec var(atom()) :: Var.t()
  def var(name) when is_atom(name), do: %Var{name: name}

  @spec const(atom()) :: Const.t()
  def const(name) when is_atom(name), do: %Const{name: name}

  @spec app(t(), t()) :: App.t()
  def app(fun, arg), do: %App{fun: fun, arg: arg}

  @spec lam(atom(), t(), t()) :: Lam.t()
  def lam(name, domain, body) when is_atom(name), do: %Lam{name: name, domain: domain, body: body}

  @spec forall(atom(), t(), t()) :: Forall.t()
  def forall(name, domain, body) when is_atom(name),
    do: %Forall{name: name, domain: domain, body: body}

  @spec arrow(t(), t()) :: Forall.t()
  def arrow(domain, codomain), do: forall(:_, domain, codomain)

  @spec eq(t(), t(), t()) :: Eq.t()
  def eq(type, left, right), do: %Eq{type: type, left: left, right: right}

  @spec refl(t()) :: Refl.t()
  def refl(value), do: %Refl{value: value}
end
