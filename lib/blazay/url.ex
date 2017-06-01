defmodule Blazay.Url do
  import Enum, only: [join: 2]

  def generate(name), do: generate(Blazay.base_api, name)
  def generate(api, name) do
    resource = join(["b2", "#{name}"], "_")
    join([api, resource], "/")
  end
end