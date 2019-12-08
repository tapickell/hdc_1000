defmodule Hdc1000.I2C do
  use Bitwise

  require Logger

  @type address :: integer()
  @type bus_name :: String.t()
  @type sensor :: {reference(), address}

  @sixteen {16, 2}
  @thirty_two {32, 4}

  @module [to_string(__MODULE__), " :: "]
  @data_issue "Data for calculation is not an Integer: "
  @i2c_nak_warn "Recieved :i2c_nak on write_read. Falling back to write, sleep, read."
  @readable "Able to read from sensor"
  @read_fail "Failed reading from sensor: "

  @moduledoc """
  I2C interface to HDC1000 sensor

  This is a library for the HDC1000 Humidity & Temp Sensor

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

      iex> bus_name = Circuits.I2C.bus_names() |> hd()
      "i2c-1"
      iex> {:ok, sensor} = Hdc1000.I2C.init(bus_name, 0x40)
      {:ok, {#Reference<0.3684559318.805699597.133010>, 64}}

      iex> {:ok, sensor} = Hdc1000.I2C.init(bus_name)
      {:ok, {#Reference<0.3684559318.805699597.133010>, 64}}
  """
  @spec init(bus_name(), address()) :: {:ok, {reference(), address()}}
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
  Dries the sensor by running 1000 reads from it to heat it up.

  ## Examples

      iex> bus_name = Circuits.I2C.bus_names() |> hd()
      "i2c-1"
      iex> {:ok, sensor} = Hdc1000.I2C.init(bus_name)
      {:ok, {#Reference<0.3684559318.805699597.133010>, 64}}
      iex> Hdc1000.I2C.dry_sensor(sensor)
      {:ok, 26.14501953125}

  """

  @spec dry_sensor(sensor()) :: {:ok, float()} | {:error, String.t()}
  def dry_sensor({_ref, _address} = sensor) do
    1..1000
    |> Enum.map(fn _ ->
      read_temp(sensor)
      Process.sleep(10)
    end)
    |> Enum.reverse()
    |> hd()
  end

  @doc """
  Reads from the sensor and returns the temperature
  in celcius as a float

  ## Examples

      iex> bus_name = Circuits.I2C.bus_names() |> hd()
      "i2c-1"
      iex> {:ok, sensor} = hdc1000.i2c.init(bus_name)
      {:ok, {#Reference<0.3684559318.805699597.133010>, 64}}
      iex> {:ok, temp} = Hdc1000.I2C.read_temp(sensor)
      {:ok, 26.14501953125}

      iex> # error case
      iex> {:ok, temp} = Hdc1000.I2C.read_temp(sensor)
      {:error, "#{@data_issue}"}
  """
  @spec read_temp(sensor()) :: {:ok, float()} | {:error, String.t()}
  def read_temp({ref, address}) do
    with {:ok, data} <- read_32(ref, address, <<0x00>>),
         {:ok, temp} <- calc_temp(data) do
      {:ok, temp}
    end
  end

  @doc """
  Reads from the sensor and returns the relative
  humidity as a float

  ## Examples

      iex> bus_name = Circuits.I2C.bus_names() |> hd()
      "i2c-1"
      iex> {:ok, sensor} = hdc1000.i2c.init(bus_name)
      {:ok, {#Reference<0.3684559318.805699597.133010>, 64}}
      iex> {:ok, rh} = Hdc1000.I2C.read_rh(sensor)
      {:ok, 26.751708984375}

      iex> # error case
      iex> {:ok, rh} = Hdc1000.I2C.read_rh(sensor)
      {:error, "#{@data_issue}"}
  """
  @spec read_rh(sensor()) :: {:ok, float()} | {:error, String.t()}
  def read_rh({ref, address}) do
    with {:ok, data} <- read_32(ref, address, <<0x00>>),
         {:ok, rh} <- calc_rh(data) do
      {:ok, rh}
    end
  end

  @doc """
  Reads from the sensor and returns the temperature and
  relative humidity as a float in a tuple

  ## Examples

      iex> bus_name = Circuits.I2C.bus_names() |> hd()
      "i2c-1"
      iex> {:ok, sensor} = hdc1000.i2c.init(bus_name)
      {:ok, {#Reference<0.3684559318.805699597.133010>, 64}}
      iex> {:ok, {temp, rh}} = Hdc1000.I2C.read_temp_and_rh(sensor)
      {:ok, {26.14501953125, 26.751708984375}}

      iex> # error case
      iex> {:ok, {temp, rh}} = Hdc1000.I2C.read_temp_and_rh(sensor)
      {:error, "#{@data_issue}"}
  """
  @spec read_temp_and_rh(sensor()) :: {:ok, {float(), float()}} | {:error, String.t()}
  def read_temp_and_rh({ref, address}) do
    with {:ok, data} <- read_32(ref, address, <<0x00>>),
         {:ok, temp} <- calc_temp(data),
         {:ok, rh} <- calc_rh(data) do
      {:ok, {temp, rh}}
    end
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
    a = Bitwise.>>>(data, 16) / 65536 * 165 - 40
    {:ok, a}
  end

  defp calc_temp(data) do
    _ = Logger.warn([@module, @data_issue, data])
    {:error, @data_issue}
  end

  defp calc_rh(data) when is_integer(data) do
    b = Bitwise.&&&(data, 0xFFFF) / 65536 * 100
    {:ok, b}
  end

  defp calc_rh(data) do
    _ = Logger.warn([@module, @data_issue, data])
    {:error, @data_issue}
  end
end
