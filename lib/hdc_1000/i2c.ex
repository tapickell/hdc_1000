defmodule Hdc1000.I2C do
  use Bitwise

  require Logger

  @sixteen {16, 2}
  @thirty_two {32, 4}

  @module [to_string(__MODULE__), " :: "]
  @data_issue "Data for calculation is not an Integer: "
  @i2c_nak_warn "Recieved :i2c_nak on write_read. Falling back to write, sleep, read."
  @readable "Able to read from sensor"
  @read_fail "Failed reading from sensor: "

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
    {:ok, ref} = Circuits.I2C.open(bus_name)

    with {:ok, _dev_id} <- read_16(ref, address, <<0xFF>>),
         {:ok, _manuf_id} <- read_16(ref, address, <<0xFE>>) do
      Logger.info([@module, @readable])
    else
      err -> Logger.warn([@module, @read_fail, err])
    end

    {:ok, {ref, address}}
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

  defp write_sleep_read(ref, address, send, {size, read}) do
    with :ok <- Circuits.I2C.write(ref, address, send),
         :ok <- Process.sleep(20),
         {:ok, <<data::size(size)>>} <- Circuits.I2C.read(ref, address, read) do
      {:ok, data}
    end
  end

  defp write_read(ref, address, send, {size, read}) do
    with {:ok, <<data::size(size)>>} <- Circuits.I2C.write_read(ref, address, send, read) do
      {:ok, data}
    else
      {:error, :i2c_nak} ->
        _ = Logger.info([@module, @i2c_nak_warn])
        write_sleep_read(ref, address, send, {size, read})
    end
  end

  defp read_16(ref, address, send) do
    write_read(ref, address, send, @sixteen)
  end

  defp read_32(ref, address, send) do
    write_read(ref, address, send, @thirty_two)
  end

  defp calc_temp(data) when is_integer(data) do
    a = Bitwise.>>>(data, 16)
    a / 65536 * 165 - 40
  end

  defp calc_temp(data) do
    _ = Logger.warn([@module, @data_issue, data])
    :error
  end

  defp calc_rh(data) when is_integer(data) do
    b = Bitwise.&&&(data, 0xFFFF)
    b / 65536 * 100
  end

  defp calc_rh(data) do
    _ = Logger.warn([@module, @data_issue, data])
    :error
  end
end
