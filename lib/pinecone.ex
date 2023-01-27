defmodule Pinecone do
  @type client :: Tesla.Client.t()
  @type options :: Keyword.t()
  @type result :: {:ok, term()} | {:error, term()}
end
