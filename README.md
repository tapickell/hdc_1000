# Hdc1000

[![Hex version](https://img.shields.io/hexpm/v/hdc_1000.svg "Hex version")](https://hex.pm/packages/hdc_1000)
[![API docs](https://img.shields.io/hexpm/v/hdc_1000.svg?label=hexdocs "API docs")](https://hexdocs.pm/hdc_1000/readme.html)

  This is a library for the HDC1000 Humidity & Temp Sensor

  I2C interface to HDC1000 sensor

  Designed specifically to work with the HDC100X sensors from Adafruit
  ----> https://www.adafruit.com/products/2635
  These sensors use I2C to communicate, 2 pins are required to
  interface.

  Please note:
  TI has indicated that there's a 'settling' effect for the humidity and
  that you will need to re-hydrate the sensor once you receive it.
  To rehydrate it, place it in a location with 85% humidity for 24 hours
  or 60% humidity for 10 days.

  You will see really low sensor readings that do not properly calculate to actual RH when you need to re-hydrate.
  For my testing I used a 62rh 2 way humidity control packet in a sealed glass jar and
  let it rehydrate for 10 days.
  ----> https://amzn.to/2RAES5R


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `hdc_1000` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:hdc_1000, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/hdc_1000](https://hexdocs.pm/hdc_1000).

