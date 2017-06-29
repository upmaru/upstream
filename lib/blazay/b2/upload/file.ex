defmodule Blazay.B2.Upload.File do
  defstruct [:file_id, :file_name, :account_id, 
             :bucket_id, :content_length, :content_sha1,
             :content_type, :file_info, :action, :upload_timestamp]
end