defmodule Blazay.B2.LargeFile.Cancel do
  defstruct [:file_id, :account_id, :bucket_id, :file_name]

  @type t :: %__MODULE__{
    file_id: String.t,
    account_id: String.t,
    bucket_id: String.t,
    file_name: String.t
  }

  use Blazay.B2

  def url(_), do: Account.api_url |> Url.generate( :cancel_large_file)
  
  def body(file_id) when is_binary(file_id), do: %{ fileId: file_id }
end
