defmodule Blazay.B2.LargeFile.Finish do
  defstruct [:file_id, :file_name, :account_id, :bucket_id, 
             :content_length, :content_sha1, :content_type, 
             :file_info, :action, :upload_timestamp]
  
  @type t :: %__MODULE__{
    file_id: String.t,
    file_name: String.t,
    account_id: String.t,
    bucket_id: String.t,
    content_length: integer,
    content_sha1: String.t,
    content_type: String.t,
    file_info: map,
    action: String.t,
    upload_timestamp: integer
  }
  use Blazay.B2

  def url(_), do: Account.api_url |> Url.generate(:finish_large_file)

  def body(body) do
    file_id = Keyword.get(body, :file_id)
    sha1_array = Keyword.get(body, :sha1_array)
    
    %{ 
      fileId: file_id,
      partSha1Array: sha1_array
    }
  end
end