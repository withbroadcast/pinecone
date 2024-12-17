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
    test "accepts vectors and namespace, returns upserted count" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert env.method == :post
        assert env.url == "#{@base_url}/vectors/upsert"

        decoded = Jason.decode!(env.body)

        assert %{
                 "vectors" => [%{"id" => "vec1", "values" => [0.1, 0.2]}],
                 "namespace" => "test-ns"
               } = decoded

        {:ok, %Tesla.Env{status: 200, body: %{"upsertedCount" => 1}}}
      end)

      assert {:ok, %{"upsertedCount" => 1}} =
               Pinecone.Vector.upsert(@client, %{
                 vectors: [%{id: "vec1", values: [0.1, 0.2]}],
                 namespace: "test-ns"
               })
    end
  end

  describe "query/3" do
    test "accepts topK and vector or id, returns matches" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert env.method == :post
        assert env.url == "#{@base_url}/query"

        decoded = Jason.decode!(env.body)

        assert %{
                 "topK" => 10,
                 "vector" => [0.1, 0.2],
                 "namespace" => "test-ns"
               } = decoded

        {:ok, %Tesla.Env{status: 200, body: %{"matches" => []}}}
      end)

      assert {:ok, %{"matches" => []}} =
               Pinecone.Vector.query(@client, %{
                 topK: 10,
                 vector: [0.1, 0.2],
                 namespace: "test-ns"
               })
    end
  end

  describe "fetch/3" do
    test "accepts ids as query params, returns vector data" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert env.method == :get
        assert env.url == "#{@base_url}/vectors/fetch"
        assert env.query == %{ids: ["vec1"], namespace: "test-ns"}
        assert env.body == nil

        {:ok, %Tesla.Env{status: 200, body: %{"vectors" => %{}}}}
      end)

      assert {:ok, %{"vectors" => %{}}} =
               Pinecone.Vector.fetch(@client, %{
                 ids: ["vec1"],
                 namespace: "test-ns"
               })
    end
  end

  describe "update/3" do
    test "accepts id and values or metadata, returns empty map" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert env.method == :post
        assert env.url == "#{@base_url}/vectors/update"

        decoded = Jason.decode!(env.body)

        assert %{
                 "id" => "vec1",
                 "values" => [0.1, 0.2],
                 "setMetadata" => %{"key" => "value"}
               } = decoded

        {:ok, %Tesla.Env{status: 200, body: %{}}}
      end)

      assert {:ok, %{}} =
               Pinecone.Vector.update(@client, %{
                 id: "vec1",
                 values: [0.1, 0.2],
                 setMetadata: %{key: "value"}
               })
    end
  end

  describe "delete/3" do
    test "accepts ids or deleteAll flag, returns empty map" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert env.method == :delete
        assert env.url == "#{@base_url}/vectors/delete"

        decoded = Jason.decode!(env.body)
        assert %{"ids" => ["vec1"], "namespace" => "test-ns"} = decoded

        {:ok, %Tesla.Env{status: 200, body: %{}}}
      end)

      assert {:ok, %{}} =
               Pinecone.Vector.delete(@client, %{
                 ids: ["vec1"],
                 namespace: "test-ns"
               })
    end
  end

  describe "list/3" do
    test "accepts prefix and pagination params as query params, returns vectors" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert env.method == :get
        assert env.url == "#{@base_url}/vectors/list"
        assert %{prefix: "test_", namespace: "test-ns"} = env.query
        assert env.body == nil

        {:ok, %Tesla.Env{status: 200, body: %{"vectors" => []}}}
      end)

      assert {:ok, %{"vectors" => []}} =
               Pinecone.Vector.list(@client, %{
                 prefix: "test_",
                 namespace: "test-ns"
               })
    end
  end

  describe "error handling" do
    test "all functions pass through Tesla errors" do
      expect(Tesla.MockAdapter, :call, fn _env, _opts ->
        {:error, :timeout}
      end)

      assert {:error, :timeout} =
               Pinecone.Vector.query(@client, %{
                 topK: 10,
                 vector: [0.1, 0.2]
               })
    end
  end
end
