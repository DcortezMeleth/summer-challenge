defmodule SummerChallenge.Model.Challenge do
  @moduledoc """
  Challenge model struct.
  """

  defstruct [:id, :name, :start_date, :end_date, :included_activity_types]

  @type t :: %__MODULE__{
          id: integer(),
          name: String.t(),
          start_date: DateTime.t(),
          end_date: DateTime.t(),
          included_activity_types: [String.t()]
        }
end
