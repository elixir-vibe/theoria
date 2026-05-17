defmodule Theoria.Lean.Encode.Application do
  @moduledoc "Specialized Lean encoders for application spines."

  alias Theoria.Lean.Encode
  alias Theoria.Term.Const

  @doc "Encodes an application spine when it needs Lean-specific argument handling."
  @spec encode(term(), [term()], [String.t()]) :: {:ok, String.t()} | :error
  def encode(%Const{name: :bool_rec}, [motive, on_true, on_false, major], context) do
    {:ok, encode_bool_match(motive, on_true, on_false, major, context)}
  end

  def encode(%Const{name: :bool_ind}, [motive, on_true, on_false, major], context) do
    {:ok, encode_bool_match(motive, on_true, on_false, major, context)}
  end

  def encode(%Const{name: :nat_rec}, [_motive, zero_case, succ_case, major], context) do
    {:ok, Encode.apply_source("Nat.rec", encode_args([zero_case, succ_case, major], context))}
  end

  def encode(%Const{name: :nat_ind}, [motive, zero_case, succ_case, major], context) do
    fun = "Nat.rec (motive := #{Encode.term(motive, context)})"
    {:ok, Encode.apply_source(fun, encode_args([zero_case, succ_case, major], context))}
  end

  def encode(%Const{name: :list_nil}, [type], context) do
    {:ok, Encode.apply_source("@List.nil", [Encode.term(type, context)])}
  end

  def encode(%Const{name: :list_cons}, [_type, _head, _tail] = args, context) do
    {:ok, Encode.apply_source("@List.cons", encode_args(args, context))}
  end

  def encode(%Const{name: :list_length}, [_type, list], context) do
    {:ok, Encode.apply_source("List.length", encode_args([list], context))}
  end

  def encode(%Const{name: :list_rec}, [_type, motive, nil_case, cons_case, major], context) do
    fun = "List.rec (motive := fun _ => #{Encode.term(motive, context)})"
    {:ok, Encode.apply_source(fun, encode_args([nil_case, cons_case, major], context))}
  end

  def encode(%Const{name: :list_ind}, [_type, motive, nil_case, cons_case, major], context) do
    fun = "List.rec (motive := #{Encode.term(motive, context)})"
    {:ok, Encode.apply_source(fun, encode_args([nil_case, cons_case, major], context))}
  end

  def encode(_fun, _args, _context), do: :error

  defp encode_bool_match(_motive, on_true, on_false, major, context) do
    "(match #{Encode.term(major, context)} with | Bool.true => #{Encode.term(on_true, context)} | Bool.false => #{Encode.term(on_false, context)})"
  end

  defp encode_args(args, context), do: Enum.map(args, &Encode.term(&1, context))
end
