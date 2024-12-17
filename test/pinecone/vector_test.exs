defmodule Pinecone.VectorTest do
  use ExUnit.Case, async: true
  import Mox

  # Setup mocks for each test
  setup :verify_on_exit!

  # Define test client
  @client Pinecone.Client.new(
            api_key: "test-api-key",
            project: "test-project",
            environment: "test-env",
            index: "test-index"
          )

  @base_url "https://test-index-test-project.svc.test-env.pinecone.io"

  # Mock successful response
  @success_response {:ok, %Tesla.Env{status: 200, body: %{"status" => "success"}}}

  describe "upsert/3" do
    test "successfully upserts vectors" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert env.method == :post
        assert env.url == "#{@base_url}/vectors/upsert"

        assert Jason.decode!(env.body) == %{
                 "vectors" => [
                   %{"id" => "vec1", "values" => [0.1, 0.2, 0.3]}
                 ],
                 "namespace" => "test-namespace"
               }

        @success_response
      end)

      assert {:ok, %{"status" => "success"}} ==
               Pinecone.Vector.upsert(@client, %{
                 vectors: [%{id: "vec1", values: [0.1, 0.2, 0.3]}],
                 namespace: "test-namespace"
               })
    end
  end

  describe "query/3" do
    test "successfully queries vectors" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert env.method == :post
        assert env.url == "#{@base_url}/query"

        assert Jason.decode!(env.body) == %{
                 "topK" => 10,
                 "vector" => [0.1, 0.2, 0.3],
                 "namespace" => "test-namespace"
               }

        {:ok,
         %Tesla.Env{
           status: 200,
           body: %{
             "matches" => [
               %{"id" => "vec1", "score" => 0.9}
             ]
           }
         }}
      end)

      assert {:ok, %{"matches" => [%{"id" => "vec1", "score" => 0.9}]}} ==
               Pinecone.Vector.query(@client, %{
                 topK: 10,
                 vector: [0.1, 0.2, 0.3],
                 namespace: "test-namespace"
               })
    end
  end

  describe "fetch/3" do
    test "successfully fetches vectors" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert env.method == :get
        assert env.url == "#{@base_url}/vectors/fetch"
        assert env.query == %{ids: ["vec1"], namespace: "test-namespace"}

        {:ok,
         %Tesla.Env{
           status: 200,
           body: %{
             "vectors" => %{
               "vec1" => %{
                 "id" => "vec1",
                 "values" => [0.1, 0.2, 0.3]
               }
             }
           }
         }}
      end)

      assert {:ok, %{"vectors" => %{"vec1" => %{"id" => "vec1", "values" => [0.1, 0.2, 0.3]}}}} ==
               Pinecone.Vector.fetch(@client, %{
                 ids: ["vec1"],
                 namespace: "test-namespace"
               })
    end
  end

  describe "update/3" do
    test "successfully updates a vector" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert env.method == :post
        assert env.url == "#{@base_url}/vectors/update"

        assert Jason.decode!(env.body) == %{
                 "id" => "vec1",
                 "values" => [0.1, 0.2, 0.3],
                 "setMetadata" => %{"category" => "test"}
               }

        @success_response
      end)

      assert {:ok, %{"status" => "success"}} ==
               Pinecone.Vector.update(@client, %{
                 id: "vec1",
                 values: [0.1, 0.2, 0.3],
                 setMetadata: %{"category" => "test"}
               })
    end
  end

  describe "delete/3" do
    test "successfully deletes vectors" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert env.method == :delete
        assert env.url == "#{@base_url}/vectors/delete"

        assert Jason.decode!(env.body) == %{
                 "ids" => ["vec1", "vec2"],
                 "namespace" => "test-namespace"
               }

        @success_response
      end)

      assert {:ok, %{"status" => "success"}} ==
               Pinecone.Vector.delete(@client, %{
                 ids: ["vec1", "vec2"],
                 namespace: "test-namespace"
               })
    end
  end

  describe "list/3" do
    test "successfully lists vectors" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert env.method == :get
        assert env.url == "#{@base_url}/vectors/list"
        assert env.query == %{prefix: "test_", namespace: "test-namespace"}

        {:ok,
         %Tesla.Env{
           status: 200,
           body: %{
             "vectors" => ["test_1", "test_2"],
             "namespace" => "test-namespace",
             "pagination" => %{"next" => "token123"}
           }
         }}
      end)

      assert {:ok,
              %{
                "vectors" => ["test_1", "test_2"],
                "namespace" => "test-namespace",
                "pagination" => %{"next" => "token123"}
              }} ==
               Pinecone.Vector.list(@client, %{
                 prefix: "test_",
                 namespace: "test-namespace"
               })
    end
  end
end
