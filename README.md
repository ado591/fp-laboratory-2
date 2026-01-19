# Лабораторная работа 2
### Образцова Анжела Дмитриевна P3322
### Вариант: sc-bag

Bag + Separating Chaining Map
Bag — это контейнер данных, позволяющий хранить элементы с учётом их кратности (один и тот же элемент может содержаться несколько раз).
- Количество сегментов фиксировано;

- Распределение элементов по сегментам определяется хеш-функцией;

- Каждый сегмент содержит список записей вида {элемент, количество вхождений};

- Все операции сохраняют эффективность благодаря использованию хеширования.

Основные операции:

- empty
- new
- from_list
- add
- remove
- count
- member
- size
- to_list
- map
- filter
- append
- empty

Последние две нужны для реализации структуры моноида. Для последних двух были написаны property-based тесты с использованием StreamData(empty -- нейтральный элемент для операции append + ассоциативность append)

### Элементы реализации

```
  def empty do
    %__MODULE__{size: 0, table: fresh_table()}
  end
```

```
  def append(a, b) do
    foldl(fn x, acc -> add(acc, x) end, a, b)
  end
```

```
def equal?(a, b) do
    size(a) == size(b) and
      Enum.all?(unique_elems(a), fn x ->
        count(a, x) == count(b, x)
      end)
  end
```

```
property "Bag is a monoid" do
    check all(
            l1 <- int_list_generator(),
            l2 <- int_list_generator(),
            l3 <- int_list_generator()
          ) do
      a = Bag.from_list(l1)
      b = Bag.from_list(l2)
      c = Bag.from_list(l3)
      e = Bag.empty()

      assert Bag.equal?(Bag.append(e, a), a)
      assert Bag.equal?(Bag.append(a, e), a)

      left = Bag.append(Bag.append(a, b), c)
      right = Bag.append(a, Bag.append(b, c))

      assert Bag.equal?(left, right)
    end
  end
```

