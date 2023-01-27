defmodule Pinecone.MixProject do
  use Mix.Project

  def project do
    [
      app: :pinecone,
      description: description(),
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    "Elixir client for the Pinecone API"
  end

  defp package do
    [
      licenses: ["MIT"],
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      links: %{"GitHub" => "https://github.com/withbroadcast/pinecone"},
      source_url: "https://github.com/withbroadcast/pinecone",
      homepage_url: "https://github.com/withbroadcast/pinecone"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:bypass, "~> 2.1"},
      {:tesla, "~> 1.4"}
    ]
  end
end
