defmodule Hdc1000.MixProject do
  use Mix.Project

  def project do
    [
      app: :hdc_1000,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "HDC 1000",
      source_url: "https://github.com/tapickell/hdc_1000",
      docs: [
        # The main page in the docs
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:circuits_i2c, "~> 0.3"},
      {:dialyxir, "~> 0.3", only: [:dev]},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end
end
