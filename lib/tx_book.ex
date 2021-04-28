defmodule TxBook do
  defstruct instruction: :new, side: :bid, price_level_index: 0, price: 0.0, quantity: 0

  def new() do
    %TxBook{}
  end
end
