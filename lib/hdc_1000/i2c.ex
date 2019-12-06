defmodule Hdc1000.I2C do
  use Bitwise

  @moduledoc """
  This is a library for the HDC1000 Humidity & Temp Sensor
  Designed specifically to work with the HDC1000 sensor from Adafruit
  ----> https://www.adafruit.com/products/2635
  These sensors use I2C to communicate, 2 pins are required to
  interface.

  Please note:
  TI has indicated that there's a 'settling' effect for the humidity and
  that you will need to re-hydrate the sensor once you receive it.
  To rehydrate it, place it in a location with 85% humidity for 24 hours
  or 60% humidity for 10 days.

  {:ok, {ref, 0x40} = sensor} = Hdc1000.I2C.init(0x40)
  {:ok, {ref, 0x40}} = Hdc1000.I2C.reset(0x40)

  {:ok, temp} = Hdc1000.I2C.read_temp(sensor)
  {:ok, rh} = Hdc1000.I2C.read_rh(sensor)
  {:ok, {temp, rh}} = Hdc1000.I2C.read_temp_and_rh(sensor)
  :ok = Hdc1000.I2C.dry_sensor(sensor)
  """

  def init(bus_name, address \\ 0x40) do
    with {:ok, ref} <- Circuits.I2C.open(bus_name),
         {:ok, <<16, 0>>} <- read_16(ref, address, <<0xFF>>),
         {:ok, "TI"} <- read_16(ref, address, <<0xFE>>) do
      {:ok, {ref, address}}
    end
  end

  def reset(address) do
  end

  def dry_sensor(ref) do
  end

  def read_temp({ref, address}) do
    {:ok, data} = read_32(ref, address, <<0x00>>)
    {:ok, calc_temp(data)}
  end

  def read_rh(ref) do
    {:ok, data} = read_32(ref, address, <<0x00>>)
    {:ok, calc_rh(data)}
  end

  def read_temp_and_rh(ref) do
    {:ok, data} = read_32(ref, address, <<0x00>>)
    {:ok, {calc_temp(data), calc_rh(data)}}
  end

  # PRIVATE FUNCTIONS

  defp read(ref, address, send, count) do
    with :ok <- Circuits.I2C.write!(ref, address, send),
         :ok <- Process.sleep(20) do
      Circuits.I2C.read(ref, address, count)
    end
  end

  defp read_16(ref, address, send) do
    read(ref, address, send, 2)
  end

  defp read_32(ref, address, send) do
    read(ref, address, send, 4)
  end

  defp calc_temp(data) do
    a = Bitwise.>>>(data, 16)
    a / 65536 * 165 - 40
  end

  defp calc_rh(data) do
    b = Bitwise.&&&(data, 0xFFFF)
    b / 65536 * 100
  end

  defp read_sensor(ref, address) do
    {:ok, <<data::32>>} = read_32(ref, address, <<0x00>>)
    data
  end
end
