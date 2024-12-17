defmodule Pinecone.Client do
  @base_url "pinecone.io"
  @api_key_env "PINECONE_API_KEY"
  @index_name_env "PINECONE_INDEX_NAME"
  @project_name_env "PINECONE_PROJECT_NAME"
  @environment_env "PINECONE_ENVIRONMENT"

  @type t :: Tesla.Client.t()

  @doc """
  Creates a new Pinecone client.

  ## Parameters
    * `opts` - Keyword list of options:
      * `:base_url` - Base URL for Pinecone API (optional, default: "pinecone.io")
      * `:https` - Whether to use HTTPS (optional, default: true)
      * `:environment` - Pinecone environment (optional, defaults to PINECONE_ENVIRONMENT env var)
      * `:index` - Index name (optional, defaults to PINECONE_INDEX_NAME env var)
      * `:project` - Project name (optional, defaults to PINECONE_PROJECT_NAME env var)
      * `:api_key` - API key (optional, defaults to PINECONE_API_KEY env var)

  ## Environment Variables
    * `PINECONE_API_KEY` - API key for authentication
    * `PINECONE_INDEX_NAME` - Name of the Pinecone index
    * `PINECONE_PROJECT_NAME` - Name of your Pinecone project
    * `PINECONE_ENVIRONMENT` - Pinecone environment (e.g., "us-west1-gcp")

  ## Returns
    * Tesla client configured for Pinecone API

  ## Raises
    * `ArgumentError` if required configuration is missing (api_key, environment, index, or project)
  """
  def new(opts \\ []) do
    base_url = Keyword.get(opts, :base_url, @base_url)
    https = Keyword.get(opts, :https, true)
    environment = Keyword.get(opts, :environment, System.get_env(@environment_env))
    index_name = Keyword.get(opts, :index, System.get_env(@index_name_env))
    project_name = Keyword.get(opts, :project, System.get_env(@project_name_env))

    if is_nil(environment) do
      raise ArgumentError, "Pinecone :environment cannot be blank"
    end

    if is_nil(index_name) do
      raise ArgumentError, "Pinecone :index cannot be blank"
    end

    if is_nil(project_name) do
      raise ArgumentError, "Pinecone :project cannot be blank"
    end

    scheme =
      if https do
        "https"
      else
        "http"
      end

    domain = "#{scheme}://#{index_name}-#{project_name}.svc.#{environment}.#{base_url}"

    api_key = Keyword.get(opts, :api_key, System.get_env(@api_key_env))

    if is_nil(api_key) do
      raise ArgumentError, "Pinecone :api_key cannot be blank"
    end

    middleware = [
      {Tesla.Middleware.BaseUrl, domain},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, [{"api-key", api_key}]}
    ]

    Tesla.client(middleware)
  end

  @doc """
  Handles the response from a Pinecone API request.

  ## Parameters
    * `resp` - Response tuple from Tesla client
    * `opts` - Optional keyword list of options (currently unused)

  ## Returns
    * `{:ok, body}` for successful responses (status < 400)
    * `{:error, response}` for error responses
    * Passes through `{:error, reason}` for failed requests
  """
  def handle_response(resp, opts \\ [])

  def handle_response({:error, _} = err, _opts), do: err

  def handle_response({:ok, %Tesla.Env{status: status, body: body}}, _opts) when status <= 400 do
    {:ok, body}
  end

  def handle_response({:ok, resp}, _opts), do: {:error, resp}
end
