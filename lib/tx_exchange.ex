defmodule TxExchange do

  # @type t :: %Examples{first: integer, last: integer}
  # @spec start_link(any) :: {:ok, pid} | {:error, {:already_started, pid}}
  @moduledoc """
  `TxExchange` is sole engine of application that is responsible to do the CRUD operation of orderr.
  """

  @name :tx_exchange_server
  use GenServer

  # Client Interface

  @spec start_link(any) :: {:ok, pid} | {:error, {:already_started, pid}}
  def start_link(_args) do
    IO.puts("Starting the TxExchange server...")
    GenServer.start_link(__MODULE__, [], name: @name)
  end

 
  
  @type t :: %TxBook{instruction: :new | :update | :delete, side: :bid | :ask, price_level_index: integer, price: float, quantity: float}
  @spec send_instruction(t) :: :ok | {:error, String.t}
  def send_instruction(%TxBook{instruction: :update } = book) do
    GenServer.call(@name, book)
  end

  @spec send_instruction(t) :: :ok | {:error, String.t}
  def send_instruction(%TxBook{instruction: :new} = book) do
    GenServer.call(@name, book)
  end

  
  @spec send_instruction(t):: :ok | :stop
  def send_instruction(%TxBook{} = book) do
    GenServer.cast(@name, book)
  end

  def send_instruction(_), do: IO.puts("Operation not defined")

  def clear_list(), do: GenServer.cast(@name, :clear_list) 

  

  def get_all_book() do
    GenServer.call(@name, :get_all_book)
  end

  def order_book(price_level_index), do: GenServer.call(@name, {:order_book, price_level_index})

 
  

  # Function that intended to use for testing purpose
  @book1 %TxBook{instruction: :new, price: 20, quantity: 20, side: :bid,  price_level_index: 1 }
  @book2 %TxBook{instruction: :new, price: 5, quantity: 200, side: :ask,  price_level_index: 1 }
  @book3 %TxBook{instruction: :new, price: 30, quantity: 30, side: :bid,  price_level_index: 2 }
  @book4 %TxBook{instruction: :new, price: 40, quantity: 40, side: :ask,  price_level_index: 2 }
  def test_addbook() do
    [@book1, @book2, @book3, @book4]
    |> Enum.each( &TxExchange.send_instruction/1)
  end
  
  def test_duplicate_entry_while_add() do
    send_instruction(@book1)
  end

  def test_update() do
    %TxBook{instruction: :update,price: 200, quantity: 200, side: :bid,  price_level_index: 1 }
    |> send_instruction
  end

  def test_delete() do
    %TxBook{instruction: :delete,price: 200, quantity: 200, side: :bid,  price_level_index: 1 }
    |> send_instruction
  end

  
  
  ################### Server interface
  @doc """
  GenServer.init/1 callback
  """
  def init(_state), do: {:ok, []}

  def handle_cast(:clear_list, _state), do: {:noreply, []}

  def handle_cast(%TxBook{instruction: :delete} = book, state) do
    before_length = Enum.count(state)
    state = delete_book_from_list(state, book)
    after_length = Enum.count(state)

    if after_length == before_length do
      {:stop, "Book not found", state}
    else
      {:noreply, state}
    end
  end

  def handle_call(%TxBook{instruction: :new} = book, _from, state) do
    case find_book_from_list(state, book) do
      {:record_found, _} -> {:reply, {:error, "Duplicate recard found"}, state}
      {:record_not_found, _} -> {:reply, :ok, [book | state] |> sort_book_list}
    end
  end

  def handle_call(%TxBook{instruction: :update} = book, _from, state) do
    case find_book_from_list(state, book) do
      {:record_not_found, _} -> {:reply, {:error, "Record not found"}, state}
      {:record_found, _} -> {:reply, :ok, update_book_list(state, book)}
    end
  end

  def handle_call(:get_all_book, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:order_book, price_index}, _from, state) do
    order_list = extract_order(price_index, state)
    {:reply, order_list, state}
  end



  # Server's helper function...
  defp extract_order(price_index, state) do
    Enum.filter(state, fn book -> book.price_level_index <= price_index end)
    |> construct_map([])
  end

  # defp construct_map([head | tail], order_list \\ [])
  defp construct_map([], order_list), do: order_list

  defp construct_map([head | tail], order_list) do
    [head1 | tail1] = tail

    order_list = [
      %{
        ask_price: head.price,
        ask_quantity: head.quantity,
        bid_price: head1.price,
        bid_quantity: head1.quantity
      }
      | order_list
    ]

    construct_map(tail1, order_list)
  end

  defp update_book_list(list, book) do
    Enum.map(list, fn head -> if check_book_valid_to_ops?(head, book), do: book, else: head end)
  end

  defp find_book_from_list(list, book) do
    value = Enum.find(list, fn head -> check_book_valid_to_ops?(head, book) end)

    if value == nil do
      {:record_not_found, nil}
    else
      {:record_found, value}
    end
  end

  defp delete_book_from_list(list, book) do
    Enum.filter(list, fn listbook -> !check_book_valid_to_ops?(listbook, book) end)
  end

  defp check_book_valid_to_ops?(book1, book2) do
    book1.side == book2.side and book1.price_level_index == book2.price_level_index
  end

  defp sort_book_list(list) do
    Enum.sort(list, &(&1.price_level_index >= &2.price_level_index))
  end
end
