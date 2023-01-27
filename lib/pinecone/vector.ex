defmodule Pinecone.Vector do
  alias Pinecone.Client

  @type vector :: %{
          required(:values) => [float()],
          required(:id) => String.t(),
          optional(:metadata) => map()
        }

  @type upsert_params :: %{
          required(:vectors) => [vector()],
          optional(:namespace) => String.t()
        }

  @spec upsert(Client.t(), upsert_params(), Keyword.t()) :: {:ok, term()} | {:error, term()}
  def upsert(client, params, opts \\ []) do
    client
    |> Tesla.post("/vectors/upsert", params)
    |> Client.handle_response(opts)
  end

  @type delete_params :: %{
          required(:ids) => [String.t()],
          optional(:namespace) => String.t(),
          optional(:deleteAll) => boolean()
        }

  @spec delete(Client.t(), delete_params(), Keyword.t()) :: {:ok, term()} | {:error, term()}
  def delete(client, params, opts \\ []) do
    client
    |> Tesla.delete("/vectors/delete", body: params)
    |> Client.handle_response(opts)
  end

  @type query_params :: %{
          required(:topK) => integer(),
          optional(:namespace) => String.t(),
          optional(:filter) => map(),
          optional(:includeValues) => boolean(),
          optional(:includeMetadata) => boolean(),
          optional(:vector) => [float()],
          optional(:id) => String.t()
        }

  @spec query(Client.t(), query_params(), Keyword.t()) :: {:ok, term()} | {:error, term()}
  def query(client, params, opts \\ []) do
    client
    |> Tesla.post("/query", params)
    |> Client.handle_response(opts)
  end
end
