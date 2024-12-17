defmodule Pinecone.VectorTest do
  use ExUnit.Case, async: true
  import Mox

  setup :verify_on_exit!

  @client Pinecone.Client.new(
            api_key: "test-api-key",
            project: "test-project",
            environment: "test-env",
            index: "test-index"
          )

  @base_url "https://test-index-test-project.svc.test-env.pinecone.io"

  describe "upsert/3" do
    test "sends request to correct endpoint with transformed parameters" do
      vectors = [
        %{id: "vec1", values: [0.1, 0.2], metadata: %{key: "value"}},
        %{id: "vec2", values: [0.3, 0.4]}
      ]

      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert env.method == :post
        assert env.url == "#{@base_url}/vectors/upsert"

        decoded = Jason.decode!(env.body)

        assert decoded["vectors"] == [
                 %{"id" => "vec1", "values" => [0.1, 0.2], "metadata" => %{"key" => "value"}},
                 %{"id" => "vec2", "values" => [0.3, 0.4]}
               ]

        assert decoded["namespace"] == "test-ns"

        {:ok, %Tesla.Env{status: 200, body: %{}}}
      end)

      Pinecone.Vector.upsert(@client, %{vectors: vectors, namespace: "test-ns"})
    end
  end

  describe "query/3" do
    test "sends request to correct endpoint with transformed parameters" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert env.method == :post
        assert env.url == "#{@base_url}/query"

        decoded = Jason.decode!(env.body)
        assert decoded["topK"] == 10
        assert decoded["vector"] == [0.1, 0.2]
        assert decoded["filter"] == %{"category" => %{"$eq" => "test"}}
        assert decoded["includeValues"]
        assert decoded["includeMetadata"]
        assert decoded["namespace"] == "test-ns"

        {:ok, %Tesla.Env{status: 200, body: %{}}}
      end)

      Pinecone.Vector.query(@client, %{
        topK: 10,
        vector: [0.1, 0.2],
        filter: %{category: %{"$eq" => "test"}},
        includeValues: true,
        includeMetadata: true,
        namespace: "test-ns"
      })
    end

    test "allows querying by ID instead of vector" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert env.method == :post
        assert env.url == "#{@base_url}/query"

        decoded = Jason.decode!(env.body)
        assert decoded["id"] == "vec1"
        refute Map.has_key?(decoded, "vector")

        {:ok, %Tesla.Env{status: 200, body: %{}}}
      end)

      Pinecone.Vector.query(@client, %{topK: 10, id: "vec1"})
    end
  end

  describe "fetch/3" do
    test "sends parameters as query params instead of body" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert env.method == :get
        assert env.url == "#{@base_url}/vectors/fetch"
        assert env.query == %{ids: ["vec1", "vec2"], namespace: "test-ns"}
        assert env.body == nil

        {:ok, %Tesla.Env{status: 200, body: %{}}}
      end)

      Pinecone.Vector.fetch(@client, %{ids: ["vec1", "vec2"], namespace: "test-ns"})
    end

    test "only includes allowed params in query" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert env.method == :get
        assert env.url == "#{@base_url}/vectors/fetch"
        assert env.query == %{ids: ["vec1"]}
        assert env.body == nil

        {:ok, %Tesla.Env{status: 200, body: %{}}}
      end)

      # extra_param should be ignored
      Pinecone.Vector.fetch(@client, %{ids: ["vec1"], extra_param: "value"})
    end
  end

  describe "update/3" do
    test "sends request to correct endpoint with transformed parameters" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert env.method == :post
        assert env.url == "#{@base_url}/vectors/update"

        decoded = Jason.decode!(env.body)
        assert decoded["id"] == "vec1"
        assert decoded["values"] == [0.1, 0.2]
        assert decoded["setMetadata"] == %{"key" => "value"}
        assert decoded["namespace"] == "test-ns"

        {:ok, %Tesla.Env{status: 200, body: %{}}}
      end)

      Pinecone.Vector.update(@client, %{
        id: "vec1",
        values: [0.1, 0.2],
        setMetadata: %{key: "value"},
        namespace: "test-ns"
      })
    end
  end

  describe "delete/3" do
    test "sends delete request with body parameters" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert env.method == :delete
        assert env.url == "#{@base_url}/vectors/delete"

        decoded = Jason.decode!(env.body)
        assert decoded["ids"] == ["vec1", "vec2"]
        assert decoded["namespace"] == "test-ns"

        {:ok, %Tesla.Env{status: 200, body: %{}}}
      end)

      Pinecone.Vector.delete(@client, %{ids: ["vec1", "vec2"], namespace: "test-ns"})
    end

    test "supports deleteAll parameter" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert env.method == :delete
        assert env.url == "#{@base_url}/vectors/delete"

        decoded = Jason.decode!(env.body)
        assert decoded["deleteAll"] == true
        assert decoded["namespace"] == "test-ns"
        refute Map.has_key?(decoded, "ids")

        {:ok, %Tesla.Env{status: 200, body: %{}}}
      end)

      Pinecone.Vector.delete(@client, %{deleteAll: true, namespace: "test-ns"})
    end
  end

  describe "list/3" do
    test "sends parameters as query params" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert env.method == :get
        assert env.url == "#{@base_url}/vectors/list"

        assert env.query == %{
                 prefix: "test_",
                 limit: 50,
                 namespace: "test-ns",
                 paginationToken: "token123"
               }

        assert env.body == nil

        {:ok, %Tesla.Env{status: 200, body: %{}}}
      end)

      Pinecone.Vector.list(@client, %{
        prefix: "test_",
        limit: 50,
        namespace: "test-ns",
        paginationToken: "token123"
      })
    end
  end

  describe "error handling" do
    test "passes through Tesla errors" do
      expect(Tesla.MockAdapter, :call, fn _env, _opts ->
        {:error, :timeout}
      end)

      assert {:error, :timeout} ==
               Pinecone.Vector.query(@client, %{topK: 10, vector: [0.1, 0.2]})
    end
  end
end
