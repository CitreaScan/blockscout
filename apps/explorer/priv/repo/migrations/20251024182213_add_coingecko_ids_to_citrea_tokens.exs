defmodule Explorer.Repo.Migrations.AddCoingeckoIdsToCitreaTokens do
  use Ecto.Migration

  def up do
    # Enable cataloging for known tokens and assign CoinGecko IDs
    # Only tokens with confirmed contract addresses on Citrea

    # Wrapped cBTC (WCBTC) -> Bitcoin
    # Contract: 0x4370e27F7d91D9341bFf232d7Ee8bdfE3a9933a0
    execute """
    UPDATE tokens
    SET cataloged = true,
        skip_metadata = false,
        fiat_value = NULL,
        circulating_market_cap = NULL,
        coingecko_coin_id = 'bitcoin'
    WHERE LOWER(contract_address_hash::text) = LOWER('0x4370e27F7d91D9341bFf232d7Ee8bdfE3a9933a0')
    """

    # NUSD (Nomo USD) -> USD Stablecoin
    # Contract: 0x9B28B690550522608890C3C7e63c0b4A7eBab9AA
    execute """
    UPDATE tokens
    SET cataloged = true,
        skip_metadata = false,
        coingecko_coin_id = 'nusd'
    WHERE LOWER(contract_address_hash::text) = LOWER('0x9B28B690550522608890C3C7e63c0b4A7eBab9AA')
    """

    # cUSD (Citrea USD) -> USD Stablecoin
    # Contract: 0x2fFC18aC99D367b70dd922771dF8c2074af4aCE0
    # Using Tether as proxy since cUSD might not be on CoinGecko
    execute """
    UPDATE tokens
    SET cataloged = true,
        skip_metadata = false,
        coingecko_coin_id = 'tether'
    WHERE LOWER(contract_address_hash::text) = LOWER('0x2fFC18aC99D367b70dd922771dF8c2074af4aCE0')
    """

    # USDC (USD Coin) -> USD Coin
    # Contract: 0x36c16eaC6B0Ba6c50f494914ff015fCa95B7835F
    execute """
    UPDATE tokens
    SET cataloged = true,
        skip_metadata = false,
        coingecko_coin_id = 'usd-coin'
    WHERE LOWER(contract_address_hash::text) = LOWER('0x36c16eaC6B0Ba6c50f494914ff015fCa95B7835F')
    """
  end

  def down do
    # Revert CoinGecko IDs for all configured tokens
    execute """
    UPDATE tokens
    SET cataloged = false,
        coingecko_coin_id = NULL,
        fiat_value = NULL,
        circulating_market_cap = NULL
    WHERE LOWER(contract_address_hash::text) IN (
      LOWER('0x4370e27F7d91D9341bFf232d7Ee8bdfE3a9933a0'),  -- WCBTC
      LOWER('0x9B28B690550522608890C3C7e63c0b4A7eBab9AA'),  -- NUSD
      LOWER('0x2fFC18aC99D367b70dd922771dF8c2074af4aCE0'),  -- cUSD
      LOWER('0x36c16eaC6B0Ba6c50f494914ff015fCa95B7835F')   -- USDC
    )
    """
  end
end
