defmodule Ravix.Ecto.Adapter do
  @behaviour Ecto.Adapter
  @behaviour Ecto.Adapter.Queryable
  @behaviour Ecto.Adapter.Schema

  @adapter Ravix.Ecto.Planner
  @queryable Ravix.Ecto.Queryable
  @schema Ravix.Ecto.Schema

  defmacro __before_compile__(_env), do: :ok

  # Adapter Delegates
  defdelegate ensure_all_started(repo, type), to: @adapter

  defdelegate init(config), to: @adapter

  defdelegate loaders(primitive, type), to: @adapter

  defdelegate dumpers(primitive, type), to: @adapter

  @spec checkout(any, any, any) :: no_return()
  defdelegate checkout(adapter_meta, config, function), to: @adapter

  defdelegate checked_out?(adapter_meta), to: @adapter

  # Queryable Delegates
  defdelegate prepare(operation, query), to: @queryable

  defdelegate execute(repo, query_meta, query_cache, params, opts), to: @queryable

  @spec stream(any, any, any, any, any) :: no_return()
  defdelegate stream(repo, query_meta, query_cache, params, opts), to: @queryable

  # Schema Delegates
  defdelegate autogenerate(any_id), to: @schema

  defdelegate insert(adapter_meta, schema_meta, fields, on_conflict, returning, options),
    to: @schema
end
