defmodule Blazay.Request.LargeFile do
  use Blazay.Request

  def start do
    url = Url.generate(:start_large_file)

    case get(url, [Blazay.Account.authorization_header], []) do
      {:ok, %{status_code: 200, body: body}} -> Poison.decode!(body)
      
    end
  end

  def unfinished do
    
  end
end