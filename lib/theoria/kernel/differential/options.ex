defmodule Theoria.Kernel.Differential.Options do
  @moduledoc """
  Structured options for kernel differential assurance runs.

  Experimental before 1.0; the shape may change.
  """

  @default_generated_size 3
  @default_generated_max_terms 128
  @default_environment_depth 4

  @enforce_keys [:generated_size, :generated_max_terms, :environment_depth]
  defstruct [:generated_size, :generated_max_terms, :environment_depth]

  @type t :: %__MODULE__{
          generated_size: non_neg_integer(),
          generated_max_terms: pos_integer(),
          environment_depth: pos_integer()
        }

  @spec default() :: t()
  def default,
    do: %__MODULE__{
      generated_size: @default_generated_size,
      generated_max_terms: @default_generated_max_terms,
      environment_depth: @default_environment_depth
    }

  @spec parse(keyword() | t()) :: {:ok, t()} | {:error, term()}
  def parse(%__MODULE__{} = options), do: validate(options)

  def parse(opts) when is_list(opts) do
    default = default()

    %__MODULE__{
      generated_size: Keyword.get(opts, :generated_size, default.generated_size),
      generated_max_terms: Keyword.get(opts, :generated_max_terms, default.generated_max_terms),
      environment_depth: Keyword.get(opts, :environment_depth, default.environment_depth)
    }
    |> validate()
  end

  def parse(other), do: {:error, {:invalid_options, other}}

  defp validate(%__MODULE__{generated_size: size}) when not is_integer(size) or size < 0,
    do: {:error, {:invalid_generated_size, size}}

  defp validate(%__MODULE__{generated_max_terms: max_terms})
       when not is_integer(max_terms) or max_terms < 1,
       do: {:error, {:invalid_generated_max_terms, max_terms}}

  defp validate(%__MODULE__{environment_depth: depth}) when not is_integer(depth) or depth < 1,
    do: {:error, {:invalid_environment_depth, depth}}

  defp validate(%__MODULE__{} = options), do: {:ok, options}
end
