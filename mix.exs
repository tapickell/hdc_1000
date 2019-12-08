defmodule Hdc1000.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/tapickell/hdc_1000"

  def project do
    [
      app: :hdc_1000,
      version: @version,
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "HDC 1000",
      source_url: @source_url,
      docs: docs(),
      description: description(),
      package: package(),
      dialyzer: [
        flags: [:unmatched_returns, :error_handling, :race_conditions, :underspecs]
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

  defp description do
    """
    I2C interface to HDC1000 sensor
    """
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end

  # The main page in the docs
  defp package do
    [
      files: [
        "lib",
        "mix.exs",
        "README.md",
        "LICENSE"
      ],
      maintainers: ["Todd Pickell"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => @source_url, "Docs" => "http://hexdocs.pm/simple_statistics/"}
    ]
  end
end
