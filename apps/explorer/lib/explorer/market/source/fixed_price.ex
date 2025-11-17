defmodule Explorer.Market.Source.FixedPrice do
  @moduledoc """
  Adapter for tokens with fixed prices (e.g., stablecoins like JUSD).

  This source allows you to configure specific token addresses with fixed USD values,
  ensuring they always display the correct pegged price regardless of market fluctuations.

  Configuration:
    MARKET_FIXED_PRICE_TOKENS='[{"address":"0x...","price":"1.00","symbol":"JUSD"}]'
  """

  alias Explorer.Chain.Hash
  alias Explorer.Market.{Source, Token}

  @behaviour Source

  @impl Source
  def native_coin_fetching_enabled?, do: :ignore

  @impl Source
  def fetch_native_coin, do: :ignore

  @impl Source
  def secondary_coin_fetching_enabled?, do: :ignore

  @impl Source
  def fetch_secondary_coin, do: :ignore

  @impl Source
  def tokens_fetching_enabled?, do: not is_nil(config(:tokens)) and config(:tokens) != []

  @impl Source
  def fetch_tokens(state, _batch_size) when state in [[], nil] do
    case config(:tokens) do
      tokens when is_list(tokens) and length(tokens) > 0 ->
        fixed_tokens = build_fixed_price_tokens(tokens)
        {:ok, [], true, fixed_tokens}

      _ ->
        {:error, "No fixed price tokens configured"}
    end
  end

  @impl Source
  def fetch_tokens(_state, _batch_size) do
    # Already fetched all tokens in first call
    {:ok, [], true, []}
  end

  @impl Source
  def native_coin_price_history_fetching_enabled?, do: :ignore

  @impl Source
  def fetch_native_coin_price_history(_previous_days), do: :ignore

  @impl Source
  def secondary_coin_price_history_fetching_enabled?, do: :ignore

  @impl Source
  def fetch_secondary_coin_price_history(_previous_days), do: :ignore

  @impl Source
  def market_cap_history_fetching_enabled?, do: :ignore

  @impl Source
  def fetch_market_cap_history(_previous_days), do: :ignore

  @impl Source
  def tvl_history_fetching_enabled?, do: :ignore

  @impl Source
  def fetch_tvl_history(_previous_days), do: :ignore

  # Private functions

  # Hardcoded JUSD stablecoin address
  @jusd_address "0x1Dd3057888944ff1f914626aB4BD47Dc8b6285Fe"

  defp build_fixed_price_tokens(tokens) do
    Enum.map(tokens, fn token_config ->
      address = token_config["address"]
      price = token_config["price"] || "1.00"

      # Hardcode JUSD metadata if it's the JUSD address
      {symbol, name} =
        if String.downcase(address) == String.downcase(@jusd_address) do
          {"JUSD", "JUSD Stablecoin"}
        else
          {token_config["symbol"] || "UNKNOWN", token_config["name"] || token_config["symbol"] || "UNKNOWN"}
        end

      {:ok, address_hash} = Hash.Address.cast(address)

      %{
        contract_address_hash: address_hash,
        type: "ERC-20",
        symbol: symbol,
        name: name,
        fiat_value: Source.to_decimal(price),
        circulating_market_cap: nil,
        volume_24h: nil,
        icon_url: token_config["icon_url"]
      }
    end)
  end

  defp config(key) do
    config = Application.get_env(:explorer, __MODULE__, [])

    case Keyword.get(config, key) do
      value when is_binary(value) and key == :tokens ->
        # Parse JSON string for tokens configuration
        case Jason.decode(value) do
          {:ok, parsed} -> parsed
          _ -> []
        end

      value ->
        value
    end
  end
end
