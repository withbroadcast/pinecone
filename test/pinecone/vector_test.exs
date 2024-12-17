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

        {:ok, %Tesla.Env{status: 200, body: %{"upsertedCount" => 1}}}
      end)

      assert {:ok, %{"upsertedCount" => 1}} ==
               Pinecone.Vector.upsert(@client, %{
                 vectors: [%{id: "vec1", values: [0.1, 0.2, 0.3]}],
                 namespace: "test-namespace"
               })
    end

    test "handles API error responses" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert env.method == :post
        assert env.url == "#{@base_url}/vectors/upsert"

        {:ok,
         %Tesla.Env{
           status: 400,
           body: %{"message" => "Invalid vector dimension"}
         }}
      end)

      assert {:ok, %{"message" => "Invalid vector dimension"}} ==
               Pinecone.Vector.upsert(@client, %{
                 vectors: [%{id: "vec1", values: []}],
                 namespace: "test-namespace"
               })
    end

    test "upserts vectors with metadata" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert env.method == :post
        assert env.url == "#{@base_url}/vectors/upsert"

        assert Jason.decode!(env.body) == %{
                 "vectors" => [
                   %{
                     "id" => "vec1",
                     "values" => [0.1, 0.2, 0.3],
                     "metadata" => %{"category" => "test", "score" => 0.9}
                   }
                 ]
               }

        @success_response
      end)

      assert {:ok, %{"status" => "success"}} ==
               Pinecone.Vector.upsert(@client, %{
                 vectors: [
                   %{
                     id: "vec1",
                     values: [0.1, 0.2, 0.3],
                     metadata: %{category: "test", score: 0.9}
                   }
                 ]
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
               %{
                 "id" => "vec1",
                 "score" => 0.9,
                 "values" => [0.1, 0.2, 0.3],
                 "metadata" => nil
               }
             ],
             "namespace" => "test-namespace",
             "usage" => %{"readUnits" => 1}
           }
         }}
      end)

      assert {:ok,
              %{
                "matches" => [
                  %{
                    "id" => "vec1",
                    "score" => 0.9,
                    "values" => [0.1, 0.2, 0.3],
                    "metadata" => nil
                  }
                ],
                "namespace" => "test-namespace",
                "usage" => %{"readUnits" => 1}
              }} ==
               Pinecone.Vector.query(@client, %{
                 topK: 10,
                 vector: [0.1, 0.2, 0.3],
                 namespace: "test-namespace"
               })
    end

    test "queries with metadata filter" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert env.method == :post
        assert env.url == "#{@base_url}/query"

        assert Jason.decode!(env.body) == %{
                 "topK" => 10,
                 "vector" => [0.1, 0.2, 0.3],
                 "filter" => %{"category" => %{"$eq" => "test"}}
               }

        {:ok,
         %Tesla.Env{
           status: 200,
           body: %{
             "matches" => [
               %{"id" => "vec1", "score" => 0.9, "metadata" => %{"category" => "test"}}
             ]
           }
         }}
      end)

      assert {:ok,
              %{
                "matches" => [
                  %{"id" => "vec1", "score" => 0.9, "metadata" => %{"category" => "test"}}
                ]
              }} ==
               Pinecone.Vector.query(@client, %{
                 topK: 10,
                 vector: [0.1, 0.2, 0.3],
                 filter: %{"category" => %{"$eq" => "test"}}
               })
    end

    test "queries by vector ID" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert env.method == :post
        assert env.url == "#{@base_url}/query"

        assert Jason.decode!(env.body) == %{
                 "topK" => 10,
                 "id" => "vec1"
               }

        {:ok,
         %Tesla.Env{
           status: 200,
           body: %{
             "matches" => [
               %{"id" => "vec2", "score" => 0.8}
             ]
           }
         }}
      end)

      assert {:ok, %{"matches" => [%{"id" => "vec2", "score" => 0.8}]}} ==
               Pinecone.Vector.query(@client, %{
                 topK: 10,
                 id: "vec1"
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
                 "values" => [0.1, 0.2, 0.3],
                 "metadata" => nil
               }
             },
             "namespace" => "test-namespace",
             "usage" => %{"readUnits" => 1}
           }
         }}
      end)

      assert {:ok,
              %{
                "vectors" => %{
                  "vec1" => %{
                    "id" => "vec1",
                    "values" => [0.1, 0.2, 0.3],
                    "metadata" => nil
                  }
                },
                "namespace" => "test-namespace",
                "usage" => %{"readUnits" => 1}
              }} ==
               Pinecone.Vector.fetch(@client, %{
                 ids: ["vec1"],
                 namespace: "test-namespace"
               })
    end

    test "handles non-existent vectors" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert env.method == :get
        assert env.url == "#{@base_url}/vectors/fetch"

        {:ok,
         %Tesla.Env{
           status: 200,
           body: %{"vectors" => %{}}
         }}
      end)

      assert {:ok, %{"vectors" => %{}}} ==
               Pinecone.Vector.fetch(@client, %{
                 ids: ["nonexistent"]
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

        {:ok, %Tesla.Env{status: 200, body: %{}}}
      end)

      assert {:ok, %{}} ==
               Pinecone.Vector.update(@client, %{
                 id: "vec1",
                 values: [0.1, 0.2, 0.3],
                 setMetadata: %{"category" => "test"}
               })
    end

    test "successfully updates a vector with sparse values" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert env.method == :post
        assert env.url == "#{@base_url}/vectors/update"

        assert Jason.decode!(env.body) == %{
                 "id" => "vec1",
                 "sparseValues" => %{
                   "indices" => [1, 4, 8],
                   "values" => [0.5, 0.2, 0.1]
                 }
               }

        @success_response
      end)

      assert {:ok, %{"status" => "success"}} ==
               Pinecone.Vector.update(@client, %{
                 id: "vec1",
                 sparseValues: %{
                   indices: [1, 4, 8],
                   values: [0.5, 0.2, 0.1]
                 }
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

        {:ok, %Tesla.Env{status: 200, body: %{}}}
      end)

      assert {:ok, %{}} ==
               Pinecone.Vector.delete(@client, %{
                 ids: ["vec1", "vec2"],
                 namespace: "test-namespace"
               })
    end

    test "successfully deletes all vectors in namespace" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert env.method == :delete
        assert env.url == "#{@base_url}/vectors/delete"

        assert Jason.decode!(env.body) == %{
                 "deleteAll" => true,
                 "namespace" => "test-namespace"
               }

        @success_response
      end)

      assert {:ok, %{"status" => "success"}} ==
               Pinecone.Vector.delete(@client, %{
                 deleteAll: true,
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
             "vectors" => [%{"id" => "test_1"}, %{"id" => "test_2"}],
             "namespace" => "test-namespace",
             "pagination" => %{"next" => "token123"},
             "usage" => %{"readUnits" => 1}
           }
         }}
      end)

      assert {:ok,
              %{
                "vectors" => [%{"id" => "test_1"}, %{"id" => "test_2"}],
                "namespace" => "test-namespace",
                "pagination" => %{"next" => "token123"},
                "usage" => %{"readUnits" => 1}
              }} ==
               Pinecone.Vector.list(@client, %{
                 prefix: "test_",
                 namespace: "test-namespace"
               })
    end

    test "handles pagination with continuation token" do
      expect(Tesla.MockAdapter, :call, fn env, _opts ->
        assert env.method == :get
        assert env.url == "#{@base_url}/vectors/list"
        assert env.query == %{paginationToken: "token123"}

        {:ok,
         %Tesla.Env{
           status: 200,
           body: %{
             "vectors" => ["test_3", "test_4"],
             "namespace" => "test-namespace",
             "pagination" => %{"next" => nil}
           }
         }}
      end)

      assert {:ok,
              %{
                "vectors" => ["test_3", "test_4"],
                "namespace" => "test-namespace",
                "pagination" => %{"next" => nil}
              }} ==
               Pinecone.Vector.list(@client, %{
                 paginationToken: "token123"
               })
    end
  end

  describe "error handling" do
    test "handles network timeout" do
      expect(Tesla.MockAdapter, :call, fn _env, _opts ->
        {:error, :timeout}
      end)

      assert {:error, :timeout} ==
               Pinecone.Vector.query(@client, %{
                 topK: 10,
                 vector: [0.1, 0.2, 0.3]
               })
    end

    test "handles connection refused" do
      expect(Tesla.MockAdapter, :call, fn _env, _opts ->
        {:error, :econnrefused}
      end)

      assert {:error, :econnrefused} ==
               Pinecone.Vector.query(@client, %{
                 topK: 10,
                 vector: [0.1, 0.2, 0.3]
               })
    end

    test "handles rate limiting" do
      expect(Tesla.MockAdapter, :call, fn _env, _opts ->
        {:ok,
         %Tesla.Env{
           status: 429,
           body: %{"message" => "Too many requests"}
         }}
      end)

      assert {:error,
              %Tesla.Env{
                status: 429,
                body: %{"message" => "Too many requests"},
                __client__: nil,
                __module__: nil,
                headers: [],
                method: nil,
                opts: [],
                query: [],
                url: ""
              }} ==
               Pinecone.Vector.query(@client, %{
                 topK: 10,
                 vector: [0.1, 0.2, 0.3]
               })
    end
  end
end
