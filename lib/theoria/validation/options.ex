defmodule Theoria.Validation.Options do
  @moduledoc false

  @spec parse_only!([String.t()] | String.t(), [atom()]) :: [atom()]
  def parse_only!(values, valid_categories) do
    values
    |> List.wrap()
    |> Enum.flat_map(&String.split(&1, ",", trim: true))
    |> Enum.map(&parse_category!(&1, valid_categories))
  end

  defp parse_category!(value, valid_categories) do
    category = Enum.find(valid_categories, &(Atom.to_string(&1) == value))

    if category do
      category
    else
      valid = Enum.map_join(valid_categories, ", ", &Atom.to_string/1)
      Mix.raise("invalid --only value: #{value}. Expected one of: #{valid}")
    end
  end
end
