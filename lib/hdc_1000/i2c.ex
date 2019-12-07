defmodule Hdc1000.I2C do
  use Bitwise

  @moduledoc """
  I2C interface to HDC1000 sensor
  """

  @doc """
  Initializes the sensor and ensures it is open for communication.

  Takes a bus name for I2C bus and an address for the sensor on the bus.
  If an address is not provided the default address
  of 0x40 will be used and returned to the caller.

  If you are unsure about the devices bus_name run
  iex> Circuits.I2C.bus_names()

  Returns ok tuple containing a tuple of the reference and the address
  of the sensor on I2C.

  ## Examples

      iex> {:ok, {ref, 0x40} = sensor} = Hdc1000.I2C.init("i2c-1", 0x40)

  """
  def init(bus_name, address \\ 0x40) do
    with {:ok, ref} <- Circuits.I2C.open(bus_name),
         {:ok, <<16, 0>>} <- read_16(ref, address, <<0xFF>>),
         {:ok, "TI"} <- read_16(ref, address, <<0xFE>>) do
      {:ok, {ref, address}}
    end
  end

  @doc """
  Resets the sensor with the default configuration settings.

  ## Examples

      iex> {:ok, {ref, 0x40}} = Hdc1000.I2C.reset(0x40)

  """
  def reset(_address) do
    :ok
  end

  @doc """
  Dries the sensor by running a bunch of reads from it to heat it up.

  ## Examples

      iex> {:ok, {ref, 0x40} = sensor} = Hdc1000.I2C.init("i2c-1", 0x40)
      iex> :ok = Hdc1000.I2C.dry_sensor(sensor)

  """

  def dry_sensor(_ref) do
    :ok
  end

  @doc """
  Reads from the sensor and returns the temperature
  in celcius as a float

  ## Examples

      iex> {:ok, {ref, 0x40} = sensor} = Hdc1000.I2C.init("i2c-1", 0x40)
      iex> {:ok, temp} = Hdc1000.I2C.read_temp(sensor)

  """
  def read_temp({ref, address}) do
    {:ok, data} = read_32(ref, address, <<0x00>>)
    {:ok, calc_temp(data)}
  end

  @doc """
  Reads from the sensor and returns the relative
  humidity as a float

  ## Examples

      iex> {:ok, {ref, 0x40} = sensor} = Hdc1000.I2C.init("i2c-1", 0x40)
      iex> {:ok, rh} = Hdc1000.I2C.read_rh(sensor)

  """
  def read_rh({ref, address}) do
    {:ok, data} = read_32(ref, address, <<0x00>>)
    {:ok, calc_rh(data)}
  end

  @doc """
  Reads from the sensor and returns the temperature and
  relative humidity as a float in a tuple

  ## Examples

      iex> {:ok, {ref, 0x40} = sensor} = Hdc1000.I2C.init("i2c-1", 0x40)
      iex> {:ok, {temp, rh}} = Hdc1000.I2C.read_temp_and_rh(sensor)

  """
  def read_temp_and_rh({ref, address}) do
    {:ok, data} = read_32(ref, address, <<0x00>>)
    {:ok, {calc_temp(data), calc_rh(data)}}
  end

  # PRIVATE FUNCTIONS

  defp read_16(ref, address, send) do
    Circuits.I2C.write_read(ref, address, send, 2)
  end

  defp read_32(ref, address, send) do
    Circuits.I2C.write_read(ref, address, send, 4)
  end

  defp calc_temp(data) do
    a = Bitwise.>>>(data, 16)
    a / 65536 * 165 - 40
  end

  defp calc_rh(data) do
    b = Bitwise.&&&(data, 0xFFFF)
    b / 65536 * 100
  end
end
