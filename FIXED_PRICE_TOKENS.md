# Fixed Price Tokens Configuration

## Übersicht

Das `FixedPrice` Market Source Module ermöglicht es, für spezifische Token (wie Stablecoins) feste USD-Preise zu konfigurieren, die unabhängig von Marktschwankungen konstant bleiben.

## Anwendungsfall: JUSD Stablecoin

JUSD ist ein Stablecoin, der immer 1:1 an den US-Dollar gekoppelt ist. Mit dieser Konfiguration wird sichergestellt, dass der Explorer immer exakt **1.00 USD** für JUSD anzeigt.

## Konfiguration

### 1. Environment Variables setzen

In `.env.dev` oder `.env.prd`:

```bash
# Token Source auf fixed_price setzen
MARKET_TOKENS_SOURCE=fixed_price

# JSON-Array mit Token-Konfigurationen
MARKET_FIXED_PRICE_TOKENS=[{"address":"0xYOUR_JUSD_CONTRACT_ADDRESS","price":"1.00","symbol":"JUSD","name":"JUSD Stablecoin"}]
```

### 2. JUSD Contract Address ersetzen

Ersetze `0xYOUR_JUSD_CONTRACT_ADDRESS` mit der tatsächlichen Contract-Adresse von JUSD auf deinem Netzwerk.

Beispiel:
```bash
MARKET_FIXED_PRICE_TOKENS=[{"address":"0x1234567890abcdef1234567890abcdef12345678","price":"1.00","symbol":"JUSD","name":"JUSD Stablecoin"}]
```

### 3. Mehrere Stablecoins konfigurieren

Du kannst mehrere Tokens mit festen Preisen konfigurieren:

```bash
MARKET_FIXED_PRICE_TOKENS=[{"address":"0xJUSD_ADDRESS","price":"1.00","symbol":"JUSD","name":"JUSD Stablecoin"},{"address":"0xUSDC_ADDRESS","price":"1.00","symbol":"USDC","name":"USD Coin"},{"address":"0xUSDT_ADDRESS","price":"1.00","symbol":"USDT","name":"Tether"}]
```

## Token-Konfiguration Format

Jedes Token-Objekt im JSON-Array unterstützt folgende Felder:

| Feld | Typ | Pflicht | Beschreibung |
|------|-----|---------|--------------|
| `address` | String | Ja | Contract-Adresse des Tokens (mit 0x Prefix) |
| `price` | String | Nein | Fester USD-Preis (Standard: "1.00") |
| `symbol` | String | Nein | Token-Symbol (z.B. "JUSD") |
| `name` | String | Nein | Vollständiger Token-Name |
| `icon_url` | String | Nein | URL zum Token-Icon |

## Implementierung

### Neu erstellte Dateien

1. **apps/explorer/lib/explorer/market/source/fixed_price.ex**
   - Neues Market Source Modul
   - Implementiert das `Explorer.Market.Source` Behaviour
   - Gibt für konfigurierte Tokens feste Preise zurück

### Modifizierte Dateien

1. **apps/explorer/lib/explorer/market/source.ex**
   - `FixedPrice` zu den Source-Aliases hinzugefügt

2. **config/config_helper.exs**
   - `"fixed_price" => Source.FixedPrice` zur `market_source/1` Funktion hinzugefügt

3. **config/runtime.exs**
   - Neue Konfiguration für `Explorer.Market.Source.FixedPrice` hinzugefügt

4. **.env.dev** und **.env.prd**
   - `MARKET_TOKENS_SOURCE=fixed_price` hinzugefügt
   - `MARKET_FIXED_PRICE_TOKENS` Konfiguration hinzugefügt

## Verwendung

### Application starten

```bash
# Development
mix deps.get
mix ecto.migrate
mix phx.server

# Production
docker-compose up -d --build
```

### Verifizierung

1. Öffne den Explorer in deinem Browser
2. Suche nach der JUSD Token-Adresse
3. Der angezeigte Preis sollte exakt **$1.00** sein
4. API-Request testen:

```bash
curl http://localhost:4000/api/v2/tokens/0xYOUR_JUSD_CONTRACT_ADDRESS
```

Response sollte enthalten:
```json
{
  "exchange_rate": "1.00",
  ...
}
```

## Alternative Lösungen

Falls du zusätzlich Preise von externen APIs für andere Tokens benötigst, kannst du:

### Option 1: Hybrid-Ansatz (Custom Source mit Fallback)
Erstelle eine Custom Source, die:
- Für JUSD den festen Preis 1.00 USD zurückgibt
- Für andere Tokens an CoinGecko/CoinMarketCap weiterleitet

### Option 2: Manuelle Datenbank-Updates
Direktes SQL-Update in der Datenbank:

```sql
-- Einmaliges Update
UPDATE tokens
SET fiat_value = 1.00
WHERE contract_address_hash = '\x<jusd_address_bytes>';

-- Als wiederkehrender Cron-Job
-- Stellt sicher, dass der Wert konstant bleibt
```

### Option 3: Admin Panel
Token als "Verified via Admin Panel" markieren und Preis manuell setzen:

```elixir
token = Explorer.Chain.Token.get_by_contract_address_hash(jusd_address, [api?: true])
Explorer.Chain.Token.update(token, %{
  fiat_value: Decimal.new("1.00"),
  is_verified_via_admin_panel: true
}, info_from_admin_panel? = true)
```

## Troubleshooting

### Problem: Preis wird nicht aktualisiert

**Lösung:** Prüfe ob der Token Fetcher läuft:
```bash
# Logs prüfen
docker-compose logs -f blockscout

# Token Fetcher Status
# Sollte "FixedPrice" als Source anzeigen
```

### Problem: Token wird nicht gefunden

**Lösung:**
1. Prüfe ob die Contract-Adresse korrekt ist (Checksummed Format)
2. Prüfe ob der Token bereits in der Datenbank existiert
3. Führe einen manuellen Token-Import durch

### Problem: JSON Parse Error

**Lösung:**
Stelle sicher, dass das JSON valide ist:
```bash
# JSON validieren
echo $MARKET_FIXED_PRICE_TOKENS | jq .
```

## Weitere Informationen

- **Token Fetcher Interval:** Standardmäßig alle 10 Sekunden (`MARKET_TOKENS_INTERVAL=10s`)
- **Refetch Interval:** Alle 1 Stunde (`MARKET_TOKENS_REFETCH_INTERVAL=1h`)
- **Batch Size:** 500 Tokens pro Request (`MARKET_TOKENS_MAX_BATCH_SIZE=500`)

## Support

Bei Fragen oder Problemen:
1. Prüfe die Logs: `docker-compose logs -f blockscout`
2. Prüfe die Konfiguration: `docker exec -it blockscout env | grep MARKET`
3. Erstelle ein Issue im Repository
