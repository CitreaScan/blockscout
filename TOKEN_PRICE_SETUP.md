# Token Price Configuration for Citrea

## Overview

This setup enables automatic price fetching for tokens on Citrea Testnet using CoinGecko API.

Since Citrea is not yet listed as a platform on CoinGecko, we map common bridged tokens to their CoinGecko IDs manually.

## Setup Steps

### 1. Run the Migration

```bash
cd apps/explorer
mix ecto.migrate
```

This migration maps the following tokens to CoinGecko:

| Token | Symbol | CoinGecko ID | Contract Address |
|-------|--------|--------------|------------------|
| Wrapped cBTC | WCBTC | bitcoin | 0x4370e27F7d91D9341bFf232d7Ee8bdfE3a9933a0 |
| Tether | USDT | tether | Auto-detected by symbol |
| USD Coin | USDC | usd-coin | Auto-detected by symbol |
| Wrapped ETH | WETH | weth | Auto-detected by symbol |
| Wrapped BTC | WBTC | wrapped-bitcoin | Auto-detected by symbol |
| Dai | DAI | dai | Auto-detected by symbol |
| Chainlink | LINK | chainlink | Auto-detected by symbol |
| Uniswap | UNI | uniswap | Auto-detected by symbol |
| Aave | AAVE | aave | Auto-detected by symbol |

### 2. Environment Variables

Already configured in `.env.vm_citrea_testnet_dev`:

```bash
# Native coin price (cBTC)
MARKET_NATIVE_COIN_SOURCE=coin_gecko
MARKET_COINGECKO_COIN_ID=bitcoin

# Token prices
MARKET_TOKENS_SOURCE=coin_gecko
```

### 3. Restart Backend

After migration, restart the Blockscout backend:

```bash
# Development
mix phx.server

# Production
# Restart your deployment
```

## How It Works

1. **Migration** sets `coingecko_coin_id` for known tokens
2. **Market Fetcher** runs every ~60 seconds
3. **Token Fetcher** fetches prices for all tokens with `coingecko_coin_id`
4. **Prices** are stored in `fiat_value` column of `tokens` table
5. **API** exposes prices via `/api/v2/tokens/:address`

## Adding New Tokens

To add a new token manually:

```sql
UPDATE tokens
SET cataloged = true,
    skip_metadata = false,
    coingecko_coin_id = 'your-coingecko-id'
WHERE LOWER(contract_address_hash::text) = LOWER('0xYourTokenAddress');
```

Find CoinGecko IDs at: https://www.coingecko.com/

## Monitoring

Check if tokens are being fetched:

```sql
SELECT
  symbol,
  name,
  contract_address_hash,
  coingecko_coin_id,
  fiat_value,
  updated_at
FROM tokens
WHERE coingecko_coin_id IS NOT NULL
ORDER BY updated_at DESC;
```

## Rate Limits

- **Without API Key:** 5-30 calls/min (variable)
- **With Free Demo Key:** 30 calls/min, 10K calls/month
- **Recommended:** Get a free API key from https://www.coingecko.com/en/api

Add to `.env`:
```bash
MARKET_COINGECKO_API_KEY=your_demo_key_here
```

## Future: When Citrea Gets Listed

When Citrea is added to CoinGecko's platform list, switch to automatic detection:

```bash
MARKET_COINGECKO_PLATFORM_ID=citrea
```

Then all tokens will be fetched automatically without manual mapping.

## Troubleshooting

### Prices not updating?

1. Check backend logs for market fetcher errors
2. Verify CoinGecko API is accessible
3. Check rate limits (add API key if needed)

### Token not showing price?

1. Verify `cataloged = true`
2. Verify `coingecko_coin_id` is set
3. Check if CoinGecko ID is correct
4. Wait for next fetch cycle (~60 seconds)

### Manual price update trigger:

```elixir
# In IEx console
Explorer.Market.Fetcher.Token.fetch_and_update()
```
