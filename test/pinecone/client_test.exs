defmodule Pinecone.ClientTest do
  use ExUnit.Case
  alias Pinecone.Client

  describe "new/1" do
    test "creates new client" do
      opts = [
        api_key: "test-api-key",
        project: "test-project",
        environment: "test-env",
        index: "test-index"
      ]

      _client = Client.new(opts)
    end

    test "raises when missing api_key" do
      opts = [
        project: "test-project",
        environment: "test-env",
        index: "test-index"
      ]

      assert_raise(ArgumentError, "Pinecone :api_key cannot be blank", fn ->
        _client = Client.new(opts)
      end)
    end

    test "raises when missing project" do
      opts = [
        api_key: "test-api-key",
        environment: "test-env",
        index: "test-index"
      ]

      assert_raise(ArgumentError, "Pinecone :project cannot be blank", fn ->
        _client = Client.new(opts)
      end)
    end

    test "raises when missing index" do
      opts = [
        api_key: "test-api-key",
        project: "test-project",
        environment: "test-env"
      ]

      assert_raise(ArgumentError, "Pinecone :index cannot be blank", fn ->
        _client = Client.new(opts)
      end)
    end

    test "raises when missing environment" do
      opts = [
        api_key: "test-api-key",
        project: "test-project",
        index: "test-index"
      ]

      assert_raise(ArgumentError, "Pinecone :environment cannot be blank", fn ->
        _client = Client.new(opts)
      end)
    end
  end
end
