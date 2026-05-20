defmodule Theoria.Certificate do
  @moduledoc """
  Replayable result of checking a `Theoria.Obligation`.

  Certificates are intended for Elixir tools and agents that need to attach a
  trust status to a generated claim. A checked certificate records that the proof
  term in the obligation was accepted by the native kernel at the time of
  checking. `replay/2` re-runs the kernel check against a supplied environment.
  """

  alias Theoria.Env
  alias Theoria.Obligation

  @type status :: :checked | :failed | :unchecked

  @type t :: %__MODULE__{
          obligation: Obligation.t(),
          status: status(),
          reason: term(),
          checked_at: DateTime.t() | nil,
          diagnostics: map()
        }

  @enforce_keys [:obligation, :status]
  defstruct [:obligation, :status, :reason, :checked_at, diagnostics: %{}]

  @doc "Builds a checked certificate."
  @spec checked(Obligation.t(), keyword()) :: t()
  def checked(%Obligation{} = obligation, opts \\ []) do
    %__MODULE__{
      obligation: obligation,
      status: :checked,
      checked_at: Keyword.get_lazy(opts, :checked_at, &DateTime.utc_now/0),
      diagnostics: Map.new(Keyword.get(opts, :diagnostics, %{}))
    }
  end

  @doc "Builds a failed certificate with the kernel rejection reason."
  @spec failed(Obligation.t(), term(), keyword()) :: t()
  def failed(%Obligation{} = obligation, reason, opts \\ []) do
    %__MODULE__{
      obligation: obligation,
      status: :failed,
      reason: reason,
      checked_at: Keyword.get_lazy(opts, :checked_at, &DateTime.utc_now/0),
      diagnostics: Map.new(Keyword.get(opts, :diagnostics, %{}))
    }
  end

  @doc "Builds an unchecked certificate for an obligation that could not be checked."
  @spec unchecked(Obligation.t(), term(), keyword()) :: t()
  def unchecked(%Obligation{} = obligation, reason, opts \\ []) do
    %__MODULE__{
      obligation: obligation,
      status: :unchecked,
      reason: reason,
      checked_at: Keyword.get(opts, :checked_at),
      diagnostics: Map.new(Keyword.get(opts, :diagnostics, %{}))
    }
  end

  @doc "Returns true when the certificate status is `:checked`."
  @spec checked?(t()) :: boolean()
  def checked?(%__MODULE__{status: status}), do: status == :checked

  @doc "Returns the certificate obligation."
  @spec obligation(t()) :: Obligation.t()
  def obligation(%__MODULE__{obligation: obligation}), do: obligation

  @doc "Returns the certificate status."
  @spec status(t()) :: status()
  def status(%__MODULE__{status: status}), do: status

  @doc "Returns the rejection or unchecked reason, if any."
  @spec reason(t()) :: term()
  def reason(%__MODULE__{reason: reason}), do: reason

  @doc "Returns the UTC timestamp recorded for checked/failed certificates."
  @spec checked_at(t()) :: DateTime.t() | nil
  def checked_at(%__MODULE__{checked_at: checked_at}), do: checked_at

  @doc "Returns diagnostic metadata."
  @spec diagnostics(t()) :: map()
  def diagnostics(%__MODULE__{diagnostics: diagnostics}), do: diagnostics

  @doc "Replays the certificate obligation against an environment."
  @spec replay(Env.t(), t()) :: {:ok, t()} | {:error, t()}
  def replay(%Env{} = env, %__MODULE__{obligation: %Obligation{} = obligation}) do
    Obligation.check(env, obligation)
  end
end
