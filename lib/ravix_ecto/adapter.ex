defmodule Ravix.Ecto.Planner do
  @behaviour Ecto.Adapter

  require Decimal

  @doc false
  @impl true
  defmacro __before_compile__(_env) do
  end

  @impl true
  def ensure_all_started(_repo, type) do
    {:ok, _ravix} = Application.ensure_all_started(:ravix, type)
  end

  @impl true
  def init(config) do
    store = Keyword.get(config, :store)

    unless Code.ensure_loaded?(Ravix.Documents.Store) do
      driver = :ravix

      raise """
      Could not find Ravix Driver.

      Please verify you have added #{inspect(driver)} as a dependency to mix.exs:
          {#{inspect(driver)}, ">= 0.0.0"}
      Remember to recompile Ecto afterwards by cleaning the current build:
          mix deps.clean --build ecto
      """
    end

    if store == nil do
      raise """
      Could not find any RavenDB Stored attached to this adapter instance:
        - Verify if the adapter param 'store' is informed and it's a Ravix.Documents.Store behaviour implementation
      """
    end

    {:ok, store.child_spec(config), %{}}
  end

  # For RavenDB this makes no sense, we could say "Ok, this will make all calls to one of the cluster nodes", but
  # i don't think it would improve anything
  @impl true
  def checkout(_, _, _),
    do: raise("The Ravix RavenDB driver does not provide support for Repo.checkout/1!")

  @impl true
  def checked_out?(_), do: false

  @impl true
  def loaders(:time, type), do: [&load_time/1, type]
  def loaders(:date, type), do: [&load_date/1, type]
  def loaders(:utc_datetime, type), do: [&load_datetime/1, type]
  def loaders(:utc_datetime_usec, type), do: [&load_datetime/1, type]
  def loaders(:naive_datetime, type), do: [&load_naive_datetime/1, type]
  def loaders(:naive_datetime_usec, type), do: [&load_naive_datetime/1, type]
  def loaders(:binary_id, type), do: [&load_objectid/1, type]
  def loaders(:uuid, type), do: [&load_binary(&1, :ecto_uuid), type]
  def loaders(:binary, type), do: [&load_binary(&1, :binary), type]
  def loaders(:id, type), do: [&load_id/1, type]
  def loaders(:integer, type), do: [&load_integer/1, type]
  def loaders(:decimal, type), do: [&load_decimal/1, type]

  def loaders(_base, type) do
    [type]
  end

  defp load_time(time), do: Time.from_iso8601(time)

  defp load_date(date) do
    date |> Date.from_iso8601()
  end

  defp load_naive_datetime(datetime) when is_bitstring(datetime) do
    {:ok, NaiveDateTime.from_iso8601!(datetime)}
  end

  defp load_datetime(datetime) when is_bitstring(datetime) do
    {:ok, utc_date_time, _} = DateTime.from_iso8601(datetime)
    {:ok, utc_date_time}
  end

  defp load_datetime(datetime) do
    {:ok, datetime}
  end

  defp load_integer(map) do
    {:ok, map}
  end

  defp load_binary(binary, :ecto_uuid) do
    Ecto.UUID.dump(binary)
  end

  defp load_binary(binary, :binary) do
    {:ok, binary <> <<0>>}
  end

  defp load_objectid(objectid) do
    {:ok, objectid}
  end

  defp load_id(id) when is_binary(id) do
    {value, _} = Integer.parse(id)
    {:ok, value}
  end

  defp load_id(id) when is_integer(id) do
    {:ok, id}
  end

  def load_decimal(decimal) do
    Decimal.cast(decimal)
  end

  @impl true
  def dumpers(:time, type), do: [type, &dump_time/1]
  def dumpers(:date, type), do: [type, &dump_date/1]
  def dumpers(:utc_datetime, type), do: [type, &dump_utc_datetime/1]
  def dumpers(:utc_datetime_usec, type), do: [type, &dump_utc_datetime/1]
  def dumpers(:naive_datetime, type), do: [type, &dump_naive_datetime/1]
  def dumpers(:naive_datetime_usec, type), do: [type, &dump_naive_datetime/1]
  def dumpers(:binary_id, type), do: [type, &dump_objectid/1]
  def dumpers(:uuid, type), do: [type, &dump_binary(&1, :ecto_uuid)]
  def dumpers(:binary, type), do: [type, &dump_binary(&1, :binary)]
  def dumpers(:id, type), do: [type, &dump_id/1]
  def dumpers(:decimal, type), do: [type, &dump_decimal/1]
  def dumpers(_base, type), do: [type]

  defp dump_time({h, m, s, _}), do: Time.from_erl({h, m, s})
  defp dump_time(%Time{} = time), do: {:ok, time}
  defp dump_time(_), do: :error

  defp dump_date({_, _, _} = date) do
    dt =
      {date, {0, 0, 0}}
      |> NaiveDateTime.from_erl!()
      |> DateTime.from_naive!("Etc/UTC")

    {:ok, dt}
  end

  defp dump_date(%Date{} = date) do
    {:ok, date}
  end

  defp dump_utc_datetime({{_, _, _} = date, {h, m, s, ms}}) do
    datetime =
      {date, {h, m, s}}
      |> NaiveDateTime.from_erl!({ms, 6})
      |> DateTime.from_naive!("Etc/UTC")

    {:ok, datetime}
  end

  defp dump_utc_datetime({{_, _, _} = date, {h, m, s}}) do
    datetime =
      {date, {h, m, s}}
      |> NaiveDateTime.from_erl!({0, 6})
      |> DateTime.from_naive!("Etc/UTC")

    {:ok, datetime}
  end

  defp dump_utc_datetime(datetime) do
    {:ok, datetime}
  end

  defp dump_naive_datetime({{_, _, _} = date, {h, m, s, ms}}) do
    datetime =
      {date, {h, m, s}}
      |> NaiveDateTime.from_erl!({ms, 6})
      |> DateTime.from_naive!("Etc/UTC")

    {:ok, datetime}
  end

  defp dump_naive_datetime(%NaiveDateTime{} = dt) do
    datetime =
      dt
      |> DateTime.from_naive!("Etc/UTC")

    {:ok, datetime}
  end

  defp dump_naive_datetime(dt) do
    datetime =
      dt
      |> DateTime.from_naive!("Etc/UTC")

    {:ok, datetime}
  end

  defp dump_binary(binary, :ecto_uuid) when is_binary(binary) do
    Ecto.UUID.load(binary)
  end

  defp dump_binary(binary, :binary) when is_binary(binary) do
    {:ok, Enum.join(for <<c::utf8 <- binary>>, do: <<c::utf8>>)}
  end

  defp dump_objectid(objectid) do
    {:ok, objectid}
  end

  defp dump_id(id) when is_integer(id) do
    {:ok, id}
  end

  def dump_decimal(decimal) when is_number(decimal) do
    {:ok, Integer.to_string(decimal)}
  end

  def dump_decimal(decimal) when Decimal.is_decimal(decimal) do
    {:ok, Decimal.to_string(decimal, :raw)}
  end

  def dump_decimal(decimal) do
    case Decimal.is_decimal(decimal) do
      true -> {:ok, decimal}
      false -> {:error, :not_a_decimal}
    end
  end
end
