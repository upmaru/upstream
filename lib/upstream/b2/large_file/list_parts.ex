defmodule Upstream.B2.LargeFile.ListParts do
  @moduledoc """
  This module will get the parts of an unfinished large file
  """


  defstruct [
    :parts,
    :next_part_number
  ]

  use Upstream.B2.Base

  @spec url(Authorization.t(), any) :: binary()
  def url(auth, _), do: Url.generate(auth.api_url, :list_parts)

  def body(file_id) when is_binary(file_id), do: %{fileId: file_id}

  @spec extract_shas(any()) :: [any()]
  def extract_shas(parts) do
    Enum.map(parts, fn part -> part["contentSha1"] end)
  end
end
