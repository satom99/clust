defmodule Clust.MixProject do
  use Mix.Project

  def project do
    [
      app: :clust,
      version: "0.1.0",
      elixir: "~> 1.7",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Clust, []}
    ]
  end

  defp deps do
    [
      {:fastglobal, "~> 1.0"},
      {:ex_hash_ring, "~> 3.0"}
    ]
  end
end
