# Blockscout Webhook Service - Implementierungsspezifikation

**Datum:** 25. Oktober 2025
**Projekt:** CitreaScan/Blockscout
**Ziel:** Implementierung eines Alchemy-kompatiblen ADDRESS_ACTIVITY Webhook-Services

---

## 1. Projektziel

Erweiterung der Blockscout API um einen Webhook-Service, der **exakt kompatibel** zur Alchemy Notify API (ADDRESS_ACTIVITY Webhook-Typ) ist. Der Service soll es Clients ermöglichen, Benachrichtigungen über Blockchain-Transaktionen auf überwachten Adressen zu erhalten.

### 1.1 Anforderungen

- ✅ **Vollständige Alchemy API-Kompatibilität** (ADDRESS_ACTIVITY Webhook-Typ)
- ✅ **Nutzung des bestehenden Blockscout Event-Systems** (`Explorer.Chain.Events.Listener`)
- ✅ **REST API für Webhook-Management** (Create, Read, Update, Delete)
- ✅ **HTTP-basierte Webhook-Auslieferung** an Client-URLs
- ✅ **Signatur-Verifizierung** für Webhook-Payloads
- ✅ **At-least-once Delivery** mit Retry-Mechanismus
- ✅ **Multi-Blockchain Support** (alle von Blockscout unterstützte EVM-Chains)

---

## 2. API-Spezifikation

### 2.1 Base URL

```
https://<blockscout-instance>/api/webhooks
```

Beispiel:
```
https://base.blockscout.com/api/webhooks
```

### 2.2 Authentication

**Alle Endpoints verwenden:**
- **Header:** `X-Alchemy-Token: <auth_token>`
- **Content-Type:** `application/json`

**Auth Token Generierung:**
- 32-Byte Hex-String (z.B. `whsec_a1b2c3d4e5f6...`)
- Pro Team/User ein Auth Token
- Wird bei der Erstellung eines Blockscout-Accounts generiert
- Verfügbar im Blockscout Dashboard unter "Webhooks"

---

## 3. API Endpoints

### 3.1 Create Webhook

**Endpoint:**
```http
POST /api/webhooks/create-webhook
```

**Request Headers:**
```http
X-Alchemy-Token: <auth_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "network": "ETH_MAINNET",
  "webhook_type": "ADDRESS_ACTIVITY",
  "webhook_url": "https://example.com/webhook",
  "addresses": [
    "0x1234567890123456789012345678901234567890",
    "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd"
  ],
  "name": "My Webhook",
  "app_id": "optional_app_identifier"
}
```

**Request Body Schema:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `network` | string | ✅ | Network enum (siehe 3.1.1) |
| `webhook_type` | string | ✅ | Muss `"ADDRESS_ACTIVITY"` sein |
| `webhook_url` | string | ✅ | Ziel-URL für Webhook-Benachrichtigungen |
| `addresses` | string[] | ✅ | Array von Ethereum-Adressen (max. 500 pro Request) |
| `name` | string | ❌ | Optionaler Name für den Webhook |
| `app_id` | string | ❌ | Optionale App-Identifikation |

**Response (200 OK):**
```json
{
  "data": {
    "id": "wh_k63lg72rxda78gce",
    "network": "ETH_MAINNET",
    "webhook_type": "ADDRESS_ACTIVITY",
    "webhook_url": "https://example.com/webhook",
    "is_active": true,
    "time_created": 1706001746,
    "version": "V2",
    "signing_key": "whsec_a1b2c3d4e5f6789012345678901234567890",
    "name": "My Webhook",
    "app_id": "optional_app_identifier"
  }
}
```

**Response Schema:**
| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Webhook-ID (Format: `wh_<random>`) |
| `network` | string | Blockchain-Netzwerk |
| `webhook_type` | string | `"ADDRESS_ACTIVITY"` |
| `webhook_url` | string | Ziel-URL |
| `is_active` | boolean | Webhook aktiv/inaktiv |
| `time_created` | number | Unix-Timestamp |
| `version` | string | Webhook-Version (immer `"V2"`) |
| `signing_key` | string | HMAC-Signing-Key (Format: `whsec_<random>`) |
| `name` | string | Webhook-Name |
| `app_id` | string | App-ID |

**Error Responses:**
- `400 Bad Request` - Ungültige Parameter
- `401 Unauthorized` - Fehlender/ungültiger Auth Token
- `422 Unprocessable Entity` - Validierungsfehler (z.B. ungültige Adressen)

#### 3.1.1 Network Enums

Unterstützte Netzwerke (abhängig von Blockscout-Instanz):

```
ETH_MAINNET
ETH_SEPOLIA
ETH_GOERLI
MATIC_MAINNET
MATIC_MUMBAI
ARBITRUM_MAINNET
ARBITRUM_GOERLI
OPTIMISM_MAINNET
OPTIMISM_GOERLI
BASE_MAINNET
BASE_GOERLI
BSC_MAINNET
BSC_TESTNET
GNOSIS_MAINNET
CITREA_MAINNET
CITREA_TESTNET
```

---

### 3.2 Get All Webhooks

**Endpoint:**
```http
GET /api/webhooks/team-webhooks
```

**Request Headers:**
```http
X-Alchemy-Token: <auth_token>
```

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "wh_k63lg72rxda78gce",
      "network": "ETH_MAINNET",
      "webhook_type": "ADDRESS_ACTIVITY",
      "webhook_url": "https://example.com/webhook",
      "is_active": true,
      "time_created": 1706001746,
      "version": "V2",
      "signing_key": "whsec_a1b2c3d4e5f6789012345678901234567890",
      "name": "My Webhook",
      "app_id": "optional_app_identifier"
    }
  ],
  "totalCount": 1
}
```

**Error Responses:**
- `401 Unauthorized` - Fehlender/ungültiger Auth Token

---

### 3.3 Update Webhook

**Endpoint:**
```http
PUT /api/webhooks/update-webhook
```

**Request Headers:**
```http
X-Alchemy-Token: <auth_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "webhook_id": "wh_k63lg72rxda78gce",
  "is_active": false,
  "name": "Updated Webhook Name"
}
```

**Request Body Schema:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `webhook_id` | string | ✅ | Webhook-ID |
| `is_active` | boolean | ❌ | Webhook aktivieren/deaktivieren |
| `name` | string | ❌ | Neuer Name |

**Response (200 OK):**
```json
{
  "id": "wh_k63lg72rxda78gce",
  "network": "ETH_MAINNET",
  "webhook_type": "ADDRESS_ACTIVITY",
  "webhook_url": "https://example.com/webhook",
  "is_active": false,
  "time_created": 1706001746,
  "version": "V2",
  "signing_key": "whsec_a1b2c3d4e5f6789012345678901234567890",
  "name": "Updated Webhook Name"
}
```

**Error Responses:**
- `400 Bad Request` - Ungültige Parameter
- `401 Unauthorized` - Fehlender/ungültiger Auth Token
- `404 Not Found` - Webhook nicht gefunden

---

### 3.4 Update Webhook Addresses

**Endpoint:**
```http
PATCH /api/webhooks/update-webhook-addresses
```

**Request Headers:**
```http
X-Alchemy-Token: <auth_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "webhook_id": "wh_k63lg72rxda78gce",
  "addresses_to_add": [
    "0x1111111111111111111111111111111111111111",
    "0x2222222222222222222222222222222222222222"
  ],
  "addresses_to_remove": [
    "0x3333333333333333333333333333333333333333"
  ]
}
```

**Request Body Schema:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `webhook_id` | string | ✅ | Webhook-ID |
| `addresses_to_add` | string[] | ✅ | Adressen hinzufügen (leeres Array erlaubt) |
| `addresses_to_remove` | string[] | ✅ | Adressen entfernen (leeres Array erlaubt) |

**Response (200 OK):**
```json
{}
```

**Eigenschaften:**
- ✅ **Idempotent:** Identische Requests können mehrfach gemacht werden
- ✅ **Batch-Support:** Max. 500 Adressen pro Feld

**Error Responses:**
- `400 Bad Request` - Ungültige Parameter
- `401 Unauthorized` - Fehlender/ungültiger Auth Token
- `404 Not Found` - Webhook nicht gefunden

---

### 3.5 Get Webhook Addresses

**Endpoint:**
```http
GET /api/webhooks/webhook-addresses?webhook_id=wh_k63lg72rxda78gce
```

**Request Headers:**
```http
X-Alchemy-Token: <auth_token>
```

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `webhook_id` | string | ✅ | Webhook-ID |
| `limit` | number | ❌ | Max. Anzahl Adressen (default: 100) |
| `offset` | number | ❌ | Pagination-Offset (default: 0) |

**Response (200 OK):**
```json
{
  "data": [
    "0x1234567890123456789012345678901234567890",
    "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd"
  ],
  "totalCount": 2
}
```

**Error Responses:**
- `401 Unauthorized` - Fehlender/ungültiger Auth Token
- `404 Not Found` - Webhook nicht gefunden

---

### 3.6 Delete Webhook

**Endpoint:**
```http
DELETE /api/webhooks/delete-webhook?webhook_id=wh_k63lg72rxda78gce
```

**Request Headers:**
```http
X-Alchemy-Token: <auth_token>
```

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `webhook_id` | string | ✅ | Webhook-ID |

**Response (200 OK):**
```json
{}
```

**Error Responses:**
- `401 Unauthorized` - Fehlender/ungültiger Auth Token
- `404 Not Found` - Webhook nicht gefunden

---

## 4. Webhook Payload (Outgoing)

### 4.1 ADDRESS_ACTIVITY Webhook Payload

Wenn eine überwachte Adresse eine Transaktion sendet oder empfängt, wird ein HTTP POST Request an die registrierte `webhook_url` gesendet.

**HTTP Request:**
```http
POST <webhook_url>
Content-Type: application/json
X-Alchemy-Signature: <hmac_signature>
```

**Payload:**
```json
{
  "webhookId": "wh_k63lg72rxda78gce",
  "id": "whevt_vq499kv7elmlbp2v",
  "createdAt": "2024-01-23T07:42:26.411977228Z",
  "type": "ADDRESS_ACTIVITY",
  "event": {
    "network": "ETH_MAINNET",
    "activity": [
      {
        "fromAddress": "0x1234567890123456789012345678901234567890",
        "toAddress": "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd",
        "blockNum": "0xdf34a3",
        "hash": "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "value": 293.092129,
        "asset": "USDC",
        "category": "token",
        "rawContract": {
          "rawValue": "0x11766ab6",
          "decimals": 6,
          "address": "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
        },
        "erc721TokenId": null,
        "erc1155Metadata": null,
        "typeTraceAddress": null,
        "log": {
          "address": "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
          "topics": [
            "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
            "0x0000000000000000000000001234567890123456789012345678901234567890",
            "0x000000000000000000000000abcdefabcdefabcdefabcdefabcdefabcdefabcd"
          ],
          "data": "0x00000000000000000000000000000000000000000000000000000000011766ab6",
          "blockNumber": "0xdf34a3",
          "transactionHash": "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
          "transactionIndex": "0x5",
          "blockHash": "0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd",
          "logIndex": "0x10",
          "removed": false
        }
      }
    ]
  }
}
```

### 4.2 Payload Schema

#### Root Level
| Field | Type | Description |
|-------|------|-------------|
| `webhookId` | string | Webhook-ID |
| `id` | string | Event-ID (Format: `whevt_<random>`) |
| `createdAt` | string | ISO 8601 Timestamp |
| `type` | string | `"ADDRESS_ACTIVITY"` |
| `event` | object | Event-Daten |

#### Event Object
| Field | Type | Description |
|-------|------|-------------|
| `network` | string | Network enum (z.B. `"ETH_MAINNET"`) |
| `activity` | array | Array von Activity-Objekten |

#### Activity Object
| Field | Type | Description |
|-------|------|-------------|
| `fromAddress` | string | Sender-Adresse (lowercase, mit `0x`) |
| `toAddress` | string | Empfänger-Adresse (lowercase, mit `0x`) |
| `blockNum` | string | Block-Nummer (hex, mit `0x`) |
| `hash` | string | Transaction Hash (mit `0x`) |
| `value` | number | Transfer-Betrag (dezimal konvertiert) |
| `asset` | string | Asset-Symbol (z.B. `"USDC"`, `"ETH"`) |
| `category` | string | `"token"`, `"external"`, `"internal"` |
| `rawContract` | object | Raw Contract-Daten |
| `erc721TokenId` | string\|null | NFT Token-ID (falls ERC721) |
| `erc1155Metadata` | object\|null | NFT Metadata (falls ERC1155) |
| `typeTraceAddress` | string\|null | Trace-Adresse für Internal Transactions |
| `log` | object | Log-Daten |

#### RawContract Object
| Field | Type | Description |
|-------|------|-------------|
| `rawValue` | string | Raw Hex-Wert (mit `0x`) |
| `decimals` | number | Token-Decimals (z.B. 18 für ETH, 6 für USDC) |
| `address` | string | Contract-Adresse (lowercase, mit `0x`, `null` für ETH) |

#### Log Object
| Field | Type | Description |
|-------|------|-------------|
| `address` | string | Contract-Adresse |
| `topics` | string[] | Log-Topics (hex) |
| `data` | string | Log-Data (hex) |
| `blockNumber` | string | Block-Nummer (hex) |
| `transactionHash` | string | Transaction Hash |
| `transactionIndex` | string | Transaction-Index (hex) |
| `blockHash` | string | Block Hash |
| `logIndex` | string | Log-Index (hex) |
| `removed` | boolean | Log entfernt (bei Reorgs) |

### 4.3 Category Types

| Category | Beschreibung | Beispiel |
|----------|--------------|----------|
| `external` | Native Token-Transfer (ETH) | Wallet → Wallet ETH Transfer |
| `token` | ERC20 Token-Transfer | USDC, USDT, DAI Transfer |
| `internal` | Internal Transaction | Smart Contract Internal Call |
| `erc721` | NFT Transfer (ERC721) | NFT Ownership Transfer |
| `erc1155` | Multi-Token Transfer (ERC1155) | Gaming Items, Multi-NFTs |

### 4.4 Signature Verification

**Header:**
```
X-Alchemy-Signature: <signature>
```

**Berechnung:**
```javascript
const crypto = require('crypto');

function verifySignature(signingKey, requestBody, alchemySignature) {
  const hmac = crypto.createHmac('sha256', signingKey);
  hmac.update(JSON.stringify(requestBody));
  const computedSignature = hmac.digest('hex');

  return computedSignature === alchemySignature;
}
```

**Elixir-Implementierung:**
```elixir
defmodule WebhookSignature do
  def verify(signing_key, request_body, alchemy_signature) do
    computed = :crypto.mac(:hmac, :sha256, signing_key, request_body)
               |> Base.encode16(case: :lower)

    computed == alchemy_signature
  end
end
```

---

## 5. Datenbankschema

### 5.1 `webhooks` Tabelle

```sql
CREATE TABLE webhooks (
  id VARCHAR(255) PRIMARY KEY,              -- Format: wh_<random>
  user_id UUID NOT NULL,                     -- Referenz zu User/Team
  network VARCHAR(50) NOT NULL,              -- ETH_MAINNET, BASE_MAINNET, etc.
  webhook_type VARCHAR(50) NOT NULL,         -- ADDRESS_ACTIVITY
  webhook_url TEXT NOT NULL,                 -- Client-URL
  is_active BOOLEAN DEFAULT true,
  time_created BIGINT NOT NULL,              -- Unix timestamp
  version VARCHAR(10) DEFAULT 'V2',
  signing_key VARCHAR(255) NOT NULL,         -- Format: whsec_<random>
  name VARCHAR(255),
  app_id VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),

  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_network (user_id, network),
  INDEX idx_webhook_active (is_active),
  INDEX idx_signing_key (signing_key)
);
```

### 5.2 `webhook_addresses` Tabelle

```sql
CREATE TABLE webhook_addresses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  webhook_id VARCHAR(255) NOT NULL,
  address VARCHAR(42) NOT NULL,              -- Ethereum-Adresse (lowercase)
  created_at TIMESTAMP DEFAULT NOW(),

  CONSTRAINT fk_webhook FOREIGN KEY (webhook_id) REFERENCES webhooks(id) ON DELETE CASCADE,
  UNIQUE (webhook_id, address),
  INDEX idx_webhook_id (webhook_id),
  INDEX idx_address (address),
  INDEX idx_webhook_address (webhook_id, address)
);
```

### 5.3 `webhook_delivery_logs` Tabelle

```sql
CREATE TABLE webhook_delivery_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  webhook_id VARCHAR(255) NOT NULL,
  event_id VARCHAR(255) NOT NULL,            -- Format: whevt_<random>
  transaction_hash VARCHAR(66) NOT NULL,
  block_number BIGINT NOT NULL,
  payload JSONB NOT NULL,
  status VARCHAR(20) NOT NULL,               -- pending, success, failed
  attempts INT DEFAULT 0,
  last_attempt_at TIMESTAMP,
  next_retry_at TIMESTAMP,
  response_code INT,
  response_body TEXT,
  error_message TEXT,
  created_at TIMESTAMP DEFAULT NOW(),

  CONSTRAINT fk_webhook_log FOREIGN KEY (webhook_id) REFERENCES webhooks(id) ON DELETE CASCADE,
  INDEX idx_webhook_status (webhook_id, status),
  INDEX idx_event_id (event_id),
  INDEX idx_next_retry (next_retry_at) WHERE status = 'pending',
  INDEX idx_transaction (transaction_hash)
);
```

### 5.4 `auth_tokens` Tabelle

```sql
CREATE TABLE auth_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  token VARCHAR(255) NOT NULL,               -- Format: whauth_<random>
  name VARCHAR(255),
  is_active BOOLEAN DEFAULT true,
  last_used_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),

  CONSTRAINT fk_user_token FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE (token),
  INDEX idx_token (token) WHERE is_active = true,
  INDEX idx_user_tokens (user_id)
);
```

---

## 6. Technische Architektur

### 6.1 Modulstruktur (Elixir/Phoenix)

```
apps/block_scout_web/
├── lib/
│   └── block_scout_web/
│       ├── controllers/
│       │   └── api/
│       │       └── v2/
│       │           └── webhook_controller.ex
│       └── views/
│           └── api/
│               └── v2/
│                   └── webhook_view.ex

apps/explorer/
├── lib/
│   └── explorer/
│       ├── chain/
│       │   ├── events/
│       │   │   ├── listener.ex (EXISTING)
│       │   │   └── webhook_broadcaster.ex (NEW)
│       │   └── webhook/
│       │       ├── webhook.ex
│       │       ├── webhook_address.ex
│       │       ├── webhook_delivery_log.ex
│       │       └── auth_token.ex
│       └── webhook/
│           ├── manager.ex
│           ├── delivery_service.ex
│           ├── retry_service.ex
│           └── signature_service.ex

apps/indexer/
└── lib/
    └── indexer/
        └── fetcher/
            └── webhook_transaction_fetcher.ex
```

### 6.2 Komponenten-Übersicht

#### 6.2.1 API Layer (Phoenix)

**`WebhookController`**
- Verwaltet alle REST API Endpoints
- Authentifizierung via `X-Alchemy-Token` Header
- Input-Validierung
- Aufruf der Business Logic im `Explorer.Webhook.Manager`

**`WebhookView`**
- JSON-Rendering der Responses
- Alchemy-kompatibles Format

#### 6.2.2 Business Logic Layer

**`Explorer.Webhook.Manager`**
- Webhook CRUD-Operationen
- Adress-Management (Add/Remove)
- Webhook-Validierung

**`Explorer.Webhook.DeliveryService`**
- HTTP POST Requests an Client-URLs
- Payload-Generierung
- Signatur-Generierung
- Response-Handling
- Logging

**`Explorer.Webhook.RetryService`**
- GenServer für Retry-Mechanismus
- Exponential Backoff (1min, 5min, 15min, 1h, 6h)
- Max. 5 Retries
- Periodic Job alle 30 Sekunden

**`Explorer.Webhook.SignatureService`**
- HMAC-SHA256 Signatur-Generierung
- Signatur-Verifizierung

#### 6.2.3 Event Processing Layer

**`Explorer.Chain.Events.WebhookBroadcaster`**
- GenServer subscribed zu `Explorer.Chain.Events.Listener`
- Lauscht auf `:chain_event` Events mit Typ `:transactions`
- Filtert relevante Transaktionen (überwachte Adressen)
- Triggert Webhook-Delivery

**`Indexer.Fetcher.WebhookTransactionFetcher`**
- Verarbeitet neue Blöcke
- Extrahiert Transaction-Daten
- Mappt auf Alchemy-Payload-Format

### 6.3 Event Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  Blockchain (EVM Node)                                          │
└───────────────────┬─────────────────────────────────────────────┘
                    │
                    │ New Block
                    ▼
┌─────────────────────────────────────────────────────────────────┐
│  Blockscout Indexer                                             │
│  ├─ Block Fetcher                                               │
│  └─ Transaction Fetcher                                         │
└───────────────────┬─────────────────────────────────────────────┘
                    │
                    │ Insert Transaction
                    ▼
┌─────────────────────────────────────────────────────────────────┐
│  PostgreSQL Database                                            │
│  └─ transactions table                                          │
└───────────────────┬─────────────────────────────────────────────┘
                    │
                    │ PostgreSQL NOTIFY
                    ▼
┌─────────────────────────────────────────────────────────────────┐
│  Explorer.Chain.Events.Listener (GenServer)                     │
│  └─ Listens to PostgreSQL NOTIFY channel "chain_event"         │
└───────────────────┬─────────────────────────────────────────────┘
                    │
                    │ Broadcast via Registry
                    ▼
┌─────────────────────────────────────────────────────────────────┐
│  Explorer.Chain.Events.WebhookBroadcaster (NEW)                 │
│  ├─ Receives transaction events                                │
│  ├─ Queries webhook_addresses for matches                      │
│  └─ Builds Alchemy-compatible payload                           │
└───────────────────┬─────────────────────────────────────────────┘
                    │
                    │ For each matching webhook
                    ▼
┌─────────────────────────────────────────────────────────────────┐
│  Explorer.Webhook.DeliveryService                               │
│  ├─ Generate HMAC signature                                    │
│  ├─ HTTP POST to webhook_url                                   │
│  ├─ Log delivery attempt                                       │
│  └─ Schedule retry on failure                                  │
└───────────────────┬─────────────────────────────────────────────┘
                    │
                    │ HTTP POST
                    ▼
┌─────────────────────────────────────────────────────────────────┐
│  Client Application (e.g., DFXswiss API)                        │
│  └─ Webhook Handler Endpoint                                   │
└─────────────────────────────────────────────────────────────────┘
```

### 6.4 Retry-Mechanismus

**Retry-Strategie:**
```elixir
defmodule Explorer.Webhook.RetryService do
  # Exponential Backoff
  def next_retry_time(attempts) do
    case attempts do
      1 -> 1 * 60         # 1 minute
      2 -> 5 * 60         # 5 minutes
      3 -> 15 * 60        # 15 minutes
      4 -> 60 * 60        # 1 hour
      5 -> 6 * 60 * 60    # 6 hours
      _ -> nil            # Give up after 5 attempts
    end
  end
end
```

**Retry GenServer:**
- Läuft alle 30 Sekunden
- Query: `SELECT * FROM webhook_delivery_logs WHERE status = 'pending' AND next_retry_at <= NOW()`
- Versucht erneute Delivery
- Updated `attempts`, `last_attempt_at`, `next_retry_at`
- Setzt `status = 'failed'` nach 5 Versuchen

---

## 7. Implementierungs-Details

### 7.1 ID-Generierung

**Webhook IDs:**
```elixir
def generate_webhook_id do
  "wh_" <> :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
end
# Beispiel: wh_k63lg72rxda78gce
```

**Event IDs:**
```elixir
def generate_event_id do
  "whevt_" <> :crypto.strong_rand_bytes(12) |> Base.encode16(case: :lower)
end
# Beispiel: whevt_vq499kv7elmlbp2v
```

**Signing Keys:**
```elixir
def generate_signing_key do
  "whsec_" <> :crypto.strong_rand_bytes(32) |> Base.encode16(case: :lower)
end
# Beispiel: whsec_a1b2c3d4e5f6789012345678901234567890abcdef...
```

**Auth Tokens:**
```elixir
def generate_auth_token do
  "whauth_" <> :crypto.strong_rand_bytes(32) |> Base.encode16(case: :lower)
end
# Beispiel: whauth_123456789abcdef...
```

### 7.2 Address Normalization

Alle Adressen werden lowercase gespeichert:

```elixir
def normalize_address(address) do
  address
  |> String.downcase()
  |> ensure_0x_prefix()
end

defp ensure_0x_prefix("0x" <> _ = address), do: address
defp ensure_0x_prefix(address), do: "0x" <> address
```

### 7.3 Transaction → Payload Mapping

**Datenquellen in Blockscout:**
- `transactions` Tabelle: from_address, to_address, hash, block_number, value
- `token_transfers` Tabelle: from_address, to_address, token_contract_address, amount, token_id
- `logs` Tabelle: address, topics, data, transaction_hash
- `internal_transactions` Tabelle: from_address, to_address, value, type

**Mapping-Logik:**

```elixir
defmodule Explorer.Webhook.PayloadMapper do
  def map_transaction_to_activity(transaction, token_transfers, logs) do
    # External Transaction (Native Token)
    external_activity = if transaction.value > 0 do
      %{
        fromAddress: normalize_address(transaction.from_address_hash),
        toAddress: normalize_address(transaction.to_address_hash),
        blockNum: "0x" <> Integer.to_string(transaction.block_number, 16),
        hash: transaction.hash,
        value: Wei.to(:ether, transaction.value),
        asset: "ETH", # oder Chain-native Token
        category: "external",
        rawContract: %{
          rawValue: "0x" <> Integer.to_string(transaction.value, 16),
          decimals: 18,
          address: nil
        },
        erc721TokenId: nil,
        erc1155Metadata: nil,
        typeTraceAddress: nil,
        log: nil
      }
    end

    # Token Transfers (ERC20/ERC721/ERC1155)
    token_activities = Enum.map(token_transfers, fn transfer ->
      log = find_log_for_transfer(logs, transfer)

      %{
        fromAddress: normalize_address(transfer.from_address_hash),
        toAddress: normalize_address(transfer.to_address_hash),
        blockNum: "0x" <> Integer.to_string(transfer.block_number, 16),
        hash: transfer.transaction_hash,
        value: calculate_token_value(transfer),
        asset: get_token_symbol(transfer.token),
        category: get_transfer_category(transfer),
        rawContract: %{
          rawValue: "0x" <> Integer.to_string(transfer.amount, 16),
          decimals: transfer.token.decimals,
          address: normalize_address(transfer.token_contract_address_hash)
        },
        erc721TokenId: transfer.token_id,
        erc1155Metadata: get_erc1155_metadata(transfer),
        typeTraceAddress: nil,
        log: map_log(log)
      }
    end)

    [external_activity | token_activities]
    |> Enum.filter(&(&1 != nil))
  end

  defp map_log(nil), do: nil
  defp map_log(log) do
    %{
      address: normalize_address(log.address_hash),
      topics: Enum.map(log.topics, &("0x" <> &1)),
      data: "0x" <> log.data,
      blockNumber: "0x" <> Integer.to_string(log.block_number, 16),
      transactionHash: log.transaction_hash,
      transactionIndex: "0x" <> Integer.to_string(log.transaction_index, 16),
      blockHash: log.block_hash,
      logIndex: "0x" <> Integer.to_string(log.index, 16),
      removed: false
    }
  end
end
```

### 7.4 Batch Operations

**Address Batch Creation (max 500):**

```elixir
defmodule Explorer.Webhook.Manager do
  @max_addresses_per_request 500

  def create_webhook(attrs, addresses) do
    if length(addresses) > @max_addresses_per_request do
      {:error, "Maximum #{@max_addresses_per_request} addresses allowed"}
    else
      # Create webhook
      # Insert addresses in batch
      Repo.transaction(fn ->
        webhook = insert_webhook(attrs)
        insert_addresses_batch(webhook.id, addresses)
        webhook
      end)
    end
  end

  def update_addresses(webhook_id, addresses_to_add, addresses_to_remove) do
    Repo.transaction(fn ->
      # Remove addresses
      from(wa in WebhookAddress,
        where: wa.webhook_id == ^webhook_id and wa.address in ^addresses_to_remove
      )
      |> Repo.delete_all()

      # Add addresses (using INSERT ... ON CONFLICT DO NOTHING for idempotency)
      insert_addresses_batch(webhook_id, addresses_to_add)
    end)
  end

  defp insert_addresses_batch(webhook_id, addresses) do
    now = DateTime.utc_now()

    entries = Enum.map(addresses, fn address ->
      %{
        webhook_id: webhook_id,
        address: normalize_address(address),
        created_at: now
      }
    end)

    Repo.insert_all(WebhookAddress, entries,
      on_conflict: :nothing,
      conflict_target: [:webhook_id, :address]
    )
  end
end
```

### 7.5 HTTP Delivery

```elixir
defmodule Explorer.Webhook.DeliveryService do
  @timeout 30_000 # 30 seconds

  def deliver(webhook, payload) do
    event_id = generate_event_id()

    full_payload = %{
      webhookId: webhook.id,
      id: event_id,
      createdAt: DateTime.utc_now() |> DateTime.to_iso8601(),
      type: webhook.webhook_type,
      event: payload
    }

    json_body = Jason.encode!(full_payload)
    signature = SignatureService.generate_signature(webhook.signing_key, json_body)

    headers = [
      {"Content-Type", "application/json"},
      {"X-Alchemy-Signature", signature}
    ]

    case HTTPoison.post(webhook.webhook_url, json_body, headers, timeout: @timeout) do
      {:ok, %{status_code: code}} when code in 200..299 ->
        log_success(webhook.id, event_id, full_payload, code)
        {:ok, :delivered}

      {:ok, %{status_code: code, body: body}} ->
        log_failure(webhook.id, event_id, full_payload, code, body)
        schedule_retry(webhook.id, event_id, full_payload)
        {:error, :delivery_failed}

      {:error, reason} ->
        log_failure(webhook.id, event_id, full_payload, nil, inspect(reason))
        schedule_retry(webhook.id, event_id, full_payload)
        {:error, reason}
    end
  end
end
```

---

## 8. Security & Performance

### 8.1 Security Maßnahmen

**Authentication:**
- Bearer Token in `X-Alchemy-Token` Header
- Token-Validierung gegen `auth_tokens` Tabelle
- Rate Limiting pro Token (z.B. 100 Requests/Minute)

**Webhook Signature:**
- HMAC-SHA256 für jede Webhook-Delivery
- Client kann Payload-Authentizität verifizieren
- Verhindert Spoofing-Attacken

**Input Validation:**
- Ethereum-Adress-Validierung (42 Zeichen, Hex)
- URL-Validierung für `webhook_url`
- Limitierung auf HTTPS-URLs (optional konfigurierbar)

**SQL Injection Prevention:**
- Verwendung von Ecto Queries (parametrisiert)
- Keine Raw SQL-Statements mit User-Input

### 8.2 Performance Optimierungen

**Database Indexes:**
```sql
-- Kritisch für schnelle Lookups
CREATE INDEX idx_webhook_address ON webhook_addresses (webhook_id, address);
CREATE INDEX idx_address ON webhook_addresses (address);
CREATE INDEX idx_webhook_active ON webhooks (is_active);
CREATE INDEX idx_next_retry ON webhook_delivery_logs (next_retry_at)
  WHERE status = 'pending';
```

**Caching:**
```elixir
# In-Memory Cache für Webhook → Signing Key Mapping
defmodule Explorer.Webhook.Cache do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get_signing_key(webhook_id) do
    GenServer.call(__MODULE__, {:get_signing_key, webhook_id})
  end

  def init(_) do
    # Load all webhooks into memory
    webhooks = Repo.all(Webhook)
    cache = Map.new(webhooks, &{&1.id, &1.signing_key})
    {:ok, cache}
  end

  # Invalidate cache on webhook changes
  def handle_call({:invalidate, webhook_id}, _from, state) do
    {:reply, :ok, Map.delete(state, webhook_id)}
  end
end
```

**Async Processing:**
- Webhook-Delivery in separatem Process (via `Task.async`)
- Non-blocking API-Responses
- Background Job für Retries

**Batching:**
- Batch-Insert für Adressen (ON CONFLICT DO NOTHING)
- Batch-Processing für Transaction-Events

**Connection Pooling:**
- HTTPoison mit Connection Pool (z.B. 100 Connections)
- PostgreSQL Connection Pool über Ecto

---

## 9. Testing

### 9.1 Unit Tests

**Test-Coverage:**
- Webhook CRUD Operations
- Address Management (Add/Remove)
- Signature Generierung/Verifizierung
- Payload Mapping
- Retry-Logik

**Beispiel Test:**
```elixir
defmodule Explorer.Webhook.ManagerTest do
  use Explorer.DataCase

  alias Explorer.Webhook.Manager

  describe "create_webhook/2" do
    test "creates webhook with addresses" do
      user = insert(:user)
      addresses = ["0x1234...", "0x5678..."]

      attrs = %{
        network: "ETH_MAINNET",
        webhook_type: "ADDRESS_ACTIVITY",
        webhook_url: "https://example.com/webhook",
        name: "Test Webhook"
      }

      {:ok, webhook} = Manager.create_webhook(user, attrs, addresses)

      assert webhook.id =~ ~r/^wh_/
      assert webhook.signing_key =~ ~r/^whsec_/
      assert webhook.is_active == true
      assert length(Repo.preload(webhook, :addresses).addresses) == 2
    end

    test "rejects more than 500 addresses" do
      user = insert(:user)
      addresses = Enum.map(1..501, &"0x#{&1}")

      attrs = %{
        network: "ETH_MAINNET",
        webhook_type: "ADDRESS_ACTIVITY",
        webhook_url: "https://example.com/webhook"
      }

      {:error, _} = Manager.create_webhook(user, attrs, addresses)
    end
  end
end
```

### 9.2 Integration Tests

**Test-Szenarien:**
- API Endpoint Tests (Controller)
- Event Flow: Transaction → Webhook Delivery
- Retry-Mechanismus
- Signature Verification

**Beispiel Integration Test:**
```elixir
defmodule BlockScoutWeb.API.V2.WebhookControllerTest do
  use BlockScoutWeb.ConnCase

  test "POST /api/webhooks/create-webhook creates webhook", %{conn: conn} do
    user = insert(:user)
    auth_token = insert(:auth_token, user: user)

    payload = %{
      network: "ETH_MAINNET",
      webhook_type: "ADDRESS_ACTIVITY",
      webhook_url: "https://example.com/webhook",
      addresses: ["0x1234567890123456789012345678901234567890"],
      name: "Test Webhook"
    }

    conn =
      conn
      |> put_req_header("x-alchemy-token", auth_token.token)
      |> post("/api/webhooks/create-webhook", payload)

    assert %{"data" => webhook_data} = json_response(conn, 200)
    assert webhook_data["id"] =~ ~r/^wh_/
    assert webhook_data["network"] == "ETH_MAINNET"
    assert webhook_data["is_active"] == true
  end
end
```

### 9.3 Load Tests

**Performance-Benchmarks:**
- 1000 Webhooks mit je 100 Adressen
- 10.000 Transactions/Block
- Webhook-Delivery-Latenz < 5 Sekunden

**Test-Tool:** Apache Bench oder k6

```javascript
// k6 load test example
import http from 'k6/http';

export default function() {
  const payload = JSON.stringify({
    network: 'ETH_MAINNET',
    webhook_type: 'ADDRESS_ACTIVITY',
    webhook_url: 'https://example.com/webhook',
    addresses: ['0x1234...']
  });

  http.post('http://localhost:4000/api/webhooks/create-webhook', payload, {
    headers: {
      'X-Alchemy-Token': 'whauth_test',
      'Content-Type': 'application/json'
    }
  });
}
```

---

## 10. Deployment

### 10.1 Environment Variables

```bash
# .env

# Webhook Feature Toggle
WEBHOOK_SERVICE_ENABLED=true

# Webhook Delivery Settings
WEBHOOK_DELIVERY_TIMEOUT_MS=30000
WEBHOOK_MAX_RETRIES=5
WEBHOOK_RETRY_INTERVAL_SECONDS=30

# HTTP Client Settings
WEBHOOK_HTTP_POOL_SIZE=100
WEBHOOK_HTTP_TIMEOUT_MS=30000

# Rate Limiting
WEBHOOK_API_RATE_LIMIT=100  # Requests per minute per token
```

### 10.2 Database Migrations

**Migration 1: Create Tables**
```bash
mix ecto.gen.migration create_webhook_tables
```

```elixir
defmodule Explorer.Repo.Migrations.CreateWebhookTables do
  use Ecto.Migration

  def change do
    create table(:webhooks, primary_key: false) do
      add :id, :string, primary_key: true
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :network, :string, null: false
      add :webhook_type, :string, null: false
      add :webhook_url, :text, null: false
      add :is_active, :boolean, default: true
      add :time_created, :bigint, null: false
      add :version, :string, default: "V2"
      add :signing_key, :string, null: false
      add :name, :string
      add :app_id, :string

      timestamps()
    end

    create index(:webhooks, [:user_id, :network])
    create index(:webhooks, [:is_active])
    create index(:webhooks, [:signing_key])

    create table(:webhook_addresses, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :webhook_id, references(:webhooks, type: :string, on_delete: :delete_all), null: false
      add :address, :string, null: false

      timestamps(updated_at: false)
    end

    create unique_index(:webhook_addresses, [:webhook_id, :address])
    create index(:webhook_addresses, [:webhook_id])
    create index(:webhook_addresses, [:address])

    create table(:webhook_delivery_logs, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :webhook_id, references(:webhooks, type: :string, on_delete: :delete_all), null: false
      add :event_id, :string, null: false
      add :transaction_hash, :string, null: false
      add :block_number, :bigint, null: false
      add :payload, :map, null: false
      add :status, :string, null: false
      add :attempts, :integer, default: 0
      add :last_attempt_at, :utc_datetime
      add :next_retry_at, :utc_datetime
      add :response_code, :integer
      add :response_body, :text
      add :error_message, :text

      timestamps(updated_at: false)
    end

    create index(:webhook_delivery_logs, [:webhook_id, :status])
    create index(:webhook_delivery_logs, [:event_id])
    create index(:webhook_delivery_logs, [:transaction_hash])
    create index(:webhook_delivery_logs, [:next_retry_at],
      where: "status = 'pending'")

    create table(:auth_tokens, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :token, :string, null: false
      add :name, :string
      add :is_active, :boolean, default: true
      add :last_used_at, :utc_datetime

      timestamps()
    end

    create unique_index(:auth_tokens, [:token])
    create index(:auth_tokens, [:token], where: "is_active = true")
    create index(:auth_tokens, [:user_id])
  end
end
```

### 10.3 Monitoring & Logging

**Metrics zu überwachen:**
- Webhook-Delivery Success Rate
- Average Delivery Latency
- Retry Queue Size
- Failed Deliveries (> 5 attempts)
- Active Webhooks Count
- API Request Rate

**Log-Levels:**
```elixir
# Success
Logger.info("Webhook delivered successfully",
  webhook_id: webhook.id,
  event_id: event_id,
  response_code: 200,
  latency_ms: latency
)

# Failure
Logger.warn("Webhook delivery failed, will retry",
  webhook_id: webhook.id,
  event_id: event_id,
  attempt: 1,
  error: reason,
  next_retry_at: next_retry
)

# Final Failure
Logger.error("Webhook delivery failed after max retries",
  webhook_id: webhook.id,
  event_id: event_id,
  attempts: 5,
  last_error: reason
)
```

---

## 11. Dokumentation

### 11.1 API-Dokumentation

**OpenAPI/Swagger Spec:**
- Vollständige API-Dokumentation in `openapi.yaml`
- Hosted unter `/api/docs` im Blockscout-Frontend
- Interaktive API-Explorer

### 11.2 User Guide

**Setup-Guide für Clients:**
1. Account erstellen in Blockscout
2. Auth Token generieren (Dashboard → Webhooks → Generate Token)
3. Webhook erstellen via API
4. Endpoint implementieren für Webhook-Empfang
5. Signatur-Verifizierung implementieren

**Code-Beispiele für Clients:**

**Node.js Webhook Handler:**
```javascript
const express = require('express');
const crypto = require('crypto');

const app = express();
app.use(express.json());

const SIGNING_KEY = 'whsec_...'; // From webhook creation response

app.post('/webhook', (req, res) => {
  const signature = req.headers['x-alchemy-signature'];
  const body = JSON.stringify(req.body);

  // Verify signature
  const hmac = crypto.createHmac('sha256', SIGNING_KEY);
  hmac.update(body);
  const expectedSignature = hmac.digest('hex');

  if (signature !== expectedSignature) {
    return res.status(401).send('Invalid signature');
  }

  // Process webhook
  const { webhookId, event } = req.body;
  console.log('Received webhook:', webhookId);
  console.log('Activities:', event.activity);

  res.status(200).send('OK');
});

app.listen(3000);
```

---

## 12. Migration Guide (für DFXswiss)

### 12.1 Code-Änderungen

**Minimal Changes:**
Da die API exakt kompatibel zu Alchemy ist, sollte der DFXswiss-Code **ohne Änderungen** funktionieren.

**Einzige Änderung:**
```typescript
// Before (Alchemy)
const settings = {
  apiKey: config.alchemy.apiKey,
  authToken: config.alchemy.authToken,
};
const alchemy = new Alchemy(settings);

// After (Blockscout)
// Option 1: Use Blockscout SDK (to be created)
const blockscout = new BlockscoutWebhook({
  baseUrl: 'https://citrea.blockscout.com/api/webhooks',
  authToken: config.blockscout.authToken
});

// Option 2: Direct HTTP Calls (fallback)
const response = await fetch('https://citrea.blockscout.com/api/webhooks/create-webhook', {
  method: 'POST',
  headers: {
    'X-Alchemy-Token': authToken,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    network: 'CITREA_MAINNET',
    webhook_type: 'ADDRESS_ACTIVITY',
    webhook_url: 'https://api.dfx.swiss/alchemy/addressWebhook',
    addresses: ['0x...']
  })
});
```

### 12.2 Webhook-Empfang

**Keine Änderungen nötig:**
Der bestehende Webhook-Handler in DFXswiss sollte unverändert funktionieren:

```typescript
// src/integration/alchemy/controllers/alchemy.controller.ts
@Post('addressWebhook')
async receiveAddressWebhook(
  @Body() dto: AlchemyWebhookDto,
  @Headers('x-alchemy-signature') signature: string,
  @RawBody() rawBody: any
) {
  const isValid = this.alchemyWebhookService.isValidWebhookSignature(
    signature,
    dto.webhookId,
    rawBody
  );

  if (!isValid) {
    throw new UnauthorizedException('Invalid webhook signature');
  }

  this.alchemyWebhookService.processAddressWebhook(dto);
  return {};
}
```

---

## 13. Timeline & Milestones

### Phase 1: Foundation (Woche 1-2)
- ✅ Datenbankschema erstellen
- ✅ Basis-Module implementieren (Webhook, WebhookAddress Entities)
- ✅ Auth Token System
- ✅ ID-Generierungs-Helpers

### Phase 2: API Layer (Woche 2-3)
- ✅ REST API Endpoints (CRUD)
- ✅ Request Validation
- ✅ Response Formatting (Alchemy-kompatibel)
- ✅ Authentication Middleware

### Phase 3: Event Processing (Woche 3-4)
- ✅ WebhookBroadcaster GenServer
- ✅ Integration mit bestehenden Events
- ✅ Payload Mapping
- ✅ Address Filtering

### Phase 4: Delivery System (Woche 4-5)
- ✅ HTTP Delivery Service
- ✅ Signature Generation
- ✅ Logging
- ✅ Retry Service mit Exponential Backoff

### Phase 5: Testing (Woche 5-6)
- ✅ Unit Tests
- ✅ Integration Tests
- ✅ Load Tests
- ✅ DFXswiss Integration Test

### Phase 6: Documentation & Deployment (Woche 6-7)
- ✅ API-Dokumentation (OpenAPI)
- ✅ User Guide
- ✅ Code-Beispiele
- ✅ Production Deployment

---

## 14. Anhang

### 14.1 Referenzen

**Alchemy API Dokumentation:**
- https://docs.alchemy.com/reference/notify-api-quickstart
- https://docs.alchemy.com/reference/address-activity-webhook
- https://github.com/alchemyplatform/alchemy-sdk-js

**Blockscout Dokumentation:**
- https://docs.blockscout.com/
- https://github.com/blockscout/blockscout

**DFXswiss API:**
- /Users/me/Documents/GitHub/DFXswiss/api

### 14.2 Glossar

| Begriff | Beschreibung |
|---------|--------------|
| ADDRESS_ACTIVITY | Webhook-Typ für Token/ETH-Transfer-Benachrichtigungen |
| Auth Token | Authentifizierungs-Token für API-Zugriff |
| Signing Key | HMAC-Key für Webhook-Payload-Signierung |
| Webhook ID | Eindeutige ID eines Webhooks (Format: `wh_...`) |
| Event ID | Eindeutige ID eines Webhook-Events (Format: `whevt_...`) |
| At-least-once Delivery | Garantie dass Webhook mind. 1x zugestellt wird |
| Idempotent | Operation die mehrfach ausführbar ist ohne Seiteneffekte |

### 14.3 Offene Fragen

1. **Multi-Tenancy:** Wie werden User/Teams in Blockscout verwaltet?
   - Antwort: Nutze bestehendes `users` Schema

2. **Network Support:** Welche Networks soll die Citrea-Instanz unterstützen?
   - Antwort: Primär CITREA_MAINNET/TESTNET, optional andere EVM-Chains

3. **Rate Limiting:** Welche Limits sollen gelten?
   - Vorschlag: 100 Requests/Minute pro Auth Token

4. **Webhook URL Validation:** Nur HTTPS erlauben?
   - Vorschlag: Ja, außer in Dev-Umgebung

---

**Ende der Spezifikation**

Version: 1.0
Letzte Aktualisierung: 2025-10-25
