defmodule Theoria.DSL.Theorem do
  @moduledoc """
  Theorem macro support for `Theoria.DSL`.

  `theorem/2` declares a named theorem from explicit `type` and `proof` blocks.
  The macro generates `<name>_type/0`, `<name>_proof/0`, and
  `<name>_theorem/1` functions and registers the theorem name for module-level
  workflows.

      theorem :truth do
        type do
          const(:True)
        end

        proof do
          const(:true_intro)
        end
      end

  The generated theorem checker elaborates both blocks and asks the native
  kernel to check the proof. The macro only builds syntax and does not extend the
  trusted boundary.
  """

  @doc false
  defmacro __before_compile__(env) do
    theorems =
      env.module
      |> Module.get_attribute(:theoria_theorems)
      |> Enum.reverse()

    quote do
      def __theoria_theorems__, do: unquote(theorems)
    end
  end

  @doc "Declares a checked theorem function trio from `type` and `proof` blocks."
  defmacro theorem(name, do: block) when is_atom(name), do: theorem_impl(name, [], block)

  defmacro theorem(name, contents) do
    if Keyword.keyword?(contents) and Keyword.has_key?(contents, :do) do
      raise ArgumentError, "theorem name must be an atom, got: #{Macro.to_string(name)}"
    else
      raise ArgumentError, "expected theorem declaration with a do block"
    end
  end

  defmacro theorem(name, opts, do: block) when is_atom(name) and is_list(opts),
    do: theorem_impl(name, opts, block)

  defmacro theorem(name, opts, do: _block) do
    cond do
      not is_atom(name) ->
        raise ArgumentError, "theorem name must be an atom, got: #{Macro.to_string(name)}"

      not is_list(opts) ->
        raise ArgumentError, "theorem options must be a keyword list"
    end
  end

  defp theorem_impl(name, opts, block) do
    universe_params = Keyword.get(opts, :universes, [])
    validate_universe_params!(universe_params)

    {type_ast, proof_ast} = theorem_parts(block)
    type_fun = String.to_atom("#{name}_type")
    proof_fun = String.to_atom("#{name}_proof")
    theorem_fun = String.to_atom("#{name}_theorem")

    quote do
      @theoria_theorems unquote(name)

      @doc "Returns the unelaborated type syntax for theorem `#{unquote(name)}`."
      def unquote(type_fun)(), do: unquote(type_ast)

      @doc "Returns the unelaborated proof syntax for theorem `#{unquote(name)}`."
      def unquote(proof_fun)(), do: unquote(proof_ast)

      @doc "Elaborates and checks theorem `#{unquote(name)}` against the given environment."
      def unquote(theorem_fun)(env \\ Theoria.new_env()) do
        with {:ok, type} <- Theoria.Elaborator.elaborate(unquote(type_fun)()),
             {:ok, proof} <- Theoria.Elaborator.elaborate(unquote(proof_fun)()),
             :ok <- Theoria.Kernel.check(env, proof, type) do
          {:ok,
           %Theoria.Theorem{
             name: unquote(name),
             type: type,
             proof: proof,
             universe_params: unquote(universe_params)
           }}
        end
      end
    end
  end

  defp validate_universe_params!(params) do
    cond do
      not is_list(params) or not Enum.all?(params, &is_atom/1) ->
        raise ArgumentError, "theorem :universes must be a list of atoms"

      length(params) != MapSet.size(MapSet.new(params)) ->
        raise ArgumentError,
              "theorem :universes contains duplicate parameters: #{inspect(params)}"

      true ->
        :ok
    end
  end

  defp theorem_parts({:__block__, _meta, expressions}) do
    expressions
    |> Enum.reduce({nil, nil}, &theorem_part/2)
    |> validate_theorem_parts!()
  end

  defp theorem_parts(expression) do
    expression
    |> theorem_part({nil, nil})
    |> validate_theorem_parts!()
  end

  defp theorem_part({:type, _meta, [[do: body]]}, {nil, proof}), do: {body, proof}
  defp theorem_part({:type, _meta, [[do: _body]]}, {_type, _proof}), do: duplicate_block!(:type)
  defp theorem_part({:proof, _meta, [[do: body]]}, {type, nil}), do: {type, body}
  defp theorem_part({:proof, _meta, [[do: _body]]}, {_type, _proof}), do: duplicate_block!(:proof)

  defp theorem_part(other, _acc) do
    raise ArgumentError,
          "expected theorem blocks named type/proof, got: #{Macro.to_string(other)}"
  end

  defp duplicate_block!(name), do: raise(ArgumentError, "theorem has duplicate #{name} block")

  defp validate_theorem_parts!({nil, _proof}),
    do: raise(ArgumentError, "theorem is missing a type block")

  defp validate_theorem_parts!({_type, nil}),
    do: raise(ArgumentError, "theorem is missing a proof block")

  defp validate_theorem_parts!({type, proof}), do: {type, proof}
end
