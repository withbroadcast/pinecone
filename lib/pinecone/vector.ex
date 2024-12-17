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

  @type fetch_params :: %{
          required(:ids) => [String.t()],
          optional(:namespace) => String.t()
        }

  @doc """
  Fetches vectors by their IDs from a namespace.

  ## Parameters
    * `client` - The Pinecone client
    * `params` - Map containing:
      * `ids` - List of vector IDs to fetch (required)
      * `namespace` - Namespace to fetch from (optional)
    * `opts` - Optional keyword list of options

  ## Returns
    * `{:ok, response}` on success
    * `{:error, reason}` on failure
  """
  @spec fetch(Client.t(), fetch_params(), Keyword.t()) :: {:ok, term()} | {:error, term()}
  def fetch(client, params, opts \\ []) do
    query_params = Map.take(params, [:ids, :namespace])

    client
    |> Tesla.get("/vectors/fetch", query: query_params)
    |> Client.handle_response(opts)
  end

  @type sparse_values :: %{
          required(:indices) => [integer()],
          required(:values) => [float()]
        }

  @type update_params :: %{
          required(:id) => String.t(),
          optional(:values) => [float()],
          optional(:sparseValues) => sparse_values(),
          optional(:setMetadata) => map(),
          optional(:namespace) => String.t()
        }

  @doc """
  Updates a vector in the index. If values are included, they will overwrite previous values.
  If setMetadata is included, the specified fields will be added or overwritten.

  ## Parameters
    * `client` - The Pinecone client
    * `params` - Map containing:
      * `id` - Vector's unique id (required)
      * `values` - Vector data (optional)
      * `sparseValues` - Vector sparse data (optional)
      * `setMetadata` - Metadata to set for the vector (optional)
      * `namespace` - Namespace containing the vector (optional)
    * `opts` - Optional keyword list of options

  ## Returns
    * `{:ok, response}` on success
    * `{:error, reason}` on failure
  """
  @spec update(Client.t(), update_params(), Keyword.t()) :: {:ok, term()} | {:error, term()}
  def update(client, params, opts \\ []) do
    client
    |> Tesla.post("/vectors/update", params)
    |> Client.handle_response(opts)
  end

  @type list_params :: %{
          optional(:prefix) => String.t(),
          optional(:limit) => integer(),
          optional(:paginationToken) => String.t(),
          optional(:namespace) => String.t()
        }

  @doc """
  Lists the IDs of vectors in a single namespace of a serverless index.

  ## Parameters
    * `client` - The Pinecone client
    * `params` - Map containing:
      * `prefix` - Filter results to IDs with this prefix (optional)
      * `limit` - Max number of IDs to return per page (optional, default: 100)
      * `paginationToken` - Token to continue a previous listing operation (optional)
      * `namespace` - Namespace to list from (optional)
    * `opts` - Optional keyword list of options

  Note: This operation is only supported for serverless indexes.

  ## Returns
    * `{:ok, response}` on success where response contains:
      * `vectors` - List of vector IDs
      * `namespace` - The namespace of the vectors
      * `pagination` - Contains the next pagination token if more results exist
    * `{:error, reason}` on failure
  """
  @spec list(Client.t(), list_params(), Keyword.t()) :: {:ok, term()} | {:error, term()}
  def list(client, params \\ %{}, opts \\ []) do
    client
    |> Tesla.get("/vectors/list", query: params)
    |> Client.handle_response(opts)
  end
end
