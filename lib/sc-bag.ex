defmodule Bag do
  @moduledoc """
  Bag implementation + hash table
  with separate chaining.
  """

  @opaque t :: %__MODULE__{
            size: non_neg_integer(),
            table: tuple()
          }

  @enforce_keys [:size, :table]
  defstruct size: 0, table: {}

  @bucket_count 32


  @spec empty() :: t()
  def empty do
    %__MODULE__{size: 0, table: fresh_table()}
  end

  @spec mempty() :: t()
  def mempty, do: empty()

  @spec new(Enumerable.t()) :: t()
  def new(enum) do
    Enum.reduce(enum, empty(), fn x, acc -> add(acc, x) end)
  end

  @spec from_list(list()) :: t()
  def from_list(xs), do: new(xs)

  @spec size(t()) :: non_neg_integer()
  def size(%__MODULE__{size: n}), do: n

  @spec add(t(), any()) :: t()
  def add(%__MODULE__{} = bag, elem) do
    slot = slot_for(elem)
    chain = fetch_chain(bag, slot)
    updated = chain_inc(chain, elem)

    %__MODULE__{
      size: bag.size + 1,
      table: put_elem(bag.table, slot, updated)
    }
  end

  @spec remove(t(), any()) :: t()
  def remove(%__MODULE__{} = bag, elem) do
    slot = slot_for(elem)
    chain = fetch_chain(bag, slot)
    {updated, removed?} = chain_dec(chain, elem)

    if removed? do
      %__MODULE__{
        size: bag.size - 1,
        table: put_elem(bag.table, slot, updated)
      }
    else
      bag
    end
  end

  @spec count(t(), any()) :: non_neg_integer()
  def count(%__MODULE__{} = bag, elem) do
    bag
    |> fetch_chain(slot_for(elem))
    |> chain_count(elem)
  end

  @spec member?(t(), any()) :: boolean()
  def member?(bag, elem), do: count(bag, elem) > 0

  @spec to_list(t()) :: list()
  def to_list(%__MODULE__{table: table}) do
    for chain <- Tuple.to_list(table),
        {elem, n} <- chain,
        _ <- 1..n,
        do: elem
  end

  @spec map(t(), (any() -> any())) :: t()
  def map(bag, fun) do
    bag
    |> to_list()
    |> Enum.map(fun)
    |> from_list()
  end

  @spec filter(t(), (any() -> as_boolean(term))) :: t()
  def filter(bag, pred) do
    bag
    |> to_list()
    |> Enum.filter(pred)
    |> from_list()
  end

  @spec foldl((any(), any() -> any()), any(), t()) :: any()
  def foldl(fun, acc, %__MODULE__{table: table}) do
    fold_table(fun, acc, table, :left)
  end

  @spec foldr((any(), any() -> any()), any(), t()) :: any()
  def foldr(fun, acc, %__MODULE__{table: table}) do
    fold_table(fun, acc, table, :right)
  end

  @spec append(t(), t()) :: t()
  def append(a, b) do
    foldl(fn x, acc -> add(acc, x) end, a, b)
  end

  @spec equal?(t(), t()) :: boolean()
  def equal?(a, b) do
    size(a) == size(b) and
      Enum.all?(unique_elems(a), fn x ->
        count(a, x) == count(b, x)
      end)
  end


  defp fresh_table do
    :erlang.make_tuple(@bucket_count, [])
  end

  defp slot_for(x) do
    :erlang.phash2(x, @bucket_count)
  end

  defp fetch_chain(%__MODULE__{table: table}, slot) do
    elem(table, slot)
  end

  defp chain_inc([], x), do: [{x, 1}]

  defp chain_inc([{k, v} | rest], x) when k == x do
    [{k, v + 1} | rest]
  end

  defp chain_inc([h | rest], x) do
    [h | chain_inc(rest, x)]
  end

  defp chain_dec([], _x), do: {[], false}

  defp chain_dec([{k, v} | rest], x) when k == x do
    if v > 1 do
      {[{k, v - 1} | rest], true}
    else
      {rest, true}
    end
  end

  defp chain_dec([h | rest], x) do
    {tail, ok?} = chain_dec(rest, x)
    {[h | tail], ok?}
  end

  defp chain_count(chain, x) do
    case Enum.find(chain, fn {k, _} -> k == x end) do
      {_, n} -> n
      nil -> 0
    end
  end


  defp fold_table(fun, acc, table, dir) do
    table
    |> Tuple.to_list()
    |> maybe_reverse(dir)
    |> Enum.reduce(acc, fn chain, a ->
      fold_chain(fun, a, chain, dir)
    end)
  end

  defp fold_chain(fun, acc, chain, :left) do
    Enum.reduce(chain, acc, fn {e, n}, a ->
      apply_n(fun, a, e, n)
    end)
  end

  defp fold_chain(fun, acc, chain, :right) do
    chain
    |> Enum.reverse()
    |> Enum.reduce(acc, fn {e, n}, a ->
      apply_n(fun, a, e, n)
    end)
  end

  defp apply_n(_fun, acc, _elem, 0), do: acc

  defp apply_n(fun, acc, elem, n) do
    apply_n(fun, fun.(elem, acc), elem, n - 1)
  end

  defp maybe_reverse(xs, :right), do: Enum.reverse(xs)
  defp maybe_reverse(xs, :left), do: xs

  # =========================
  # Equality helpers
  # =========================

  defp unique_elems(bag) do
    bag
    |> to_list()
    |> MapSet.new()
  end
end
