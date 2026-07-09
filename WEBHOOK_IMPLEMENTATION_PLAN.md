# Blockscout Webhook Service - Implementierungsplan

**Projekt:** CitreaScan Blockscout Webhook Service
**Erstellt:** 25. Oktober 2025
**Dauer:** 6-8 Wochen
**Team-Größe:** 1-2 Entwickler

---

## Inhaltsverzeichnis

1. [Executive Summary](#1-executive-summary)
2. [Projekt-Scope](#2-projekt-scope)
3. [Technologie-Stack](#3-technologie-stack)
4. [Implementierungs-Phasen](#4-implementierungs-phasen)
5. [Detaillierte Task-Liste](#5-detaillierte-task-liste)
6. [Abhängigkeiten & Risiken](#6-abhängigkeiten--risiken)
7. [Ressourcen-Planung](#7-ressourcen-planung)
8. [Qualitätssicherung](#8-qualitätssicherung)
9. [Deployment-Strategie](#9-deployment-strategie)
10. [Success Metrics](#10-success-metrics)

---

## 1. Executive Summary

### Projektziel
Implementierung eines produktionsreifen, Alchemy-kompatiblen ADDRESS_ACTIVITY Webhook-Services für Blockscout, der es Clients (primär DFXswiss) ermöglicht, Real-time Benachrichtigungen über Blockchain-Transaktionen zu erhalten.

### Key Deliverables
- ✅ REST API mit 6 Endpoints (Create, Read, Update, Delete, List, Get Addresses)
- ✅ Event Processing Pipeline (Blockchain → Webhook Delivery)
- ✅ Retry-Mechanismus mit exponential backoff
- ✅ Signatur-Verifizierung (HMAC-SHA256)
- ✅ Umfassende Tests (Unit, Integration, Load)
- ✅ API-Dokumentation (OpenAPI/Swagger)

### Timeline
- **Start:** Woche 1
- **Alpha:** Woche 4 (Intern testbar)
- **Beta:** Woche 6 (DFXswiss Integration)
- **Production:** Woche 8

### Budget
- **Entwicklung:** 280-400 Stunden (1-2 Entwickler)
- **Testing/QA:** 80 Stunden
- **Dokumentation:** 40 Stunden
- **Deployment:** 20 Stunden
- **Gesamt:** 420-540 Stunden

---

## 2. Projekt-Scope

### In Scope ✅
- ADDRESS_ACTIVITY Webhook-Typ
- REST API für Webhook-Management
- HTTP-basierte Webhook-Delivery
- HMAC-Signatur-Verifizierung
- Retry-Mechanismus (5 Versuche)
- Auth Token System
- Multi-Blockchain Support (alle EVM-Chains in Blockscout)
- API-Dokumentation
- Unit & Integration Tests
- DFXswiss Integration

### Out of Scope ❌
- Andere Webhook-Typen (NFT_ACTIVITY, GRAPHQL, MINED_TRANSACTION, DROPPED_TRANSACTION)
- WebSocket-basierte Webhooks
- GraphQL API
- SDK für JavaScript/TypeScript
- Mobile Apps
- Admin-Dashboard (UI)
- Advanced Analytics
- Third-party Integrations (außer DFXswiss)

### Nice-to-Have 🎯
- Admin-Dashboard für Webhook-Management
- JavaScript SDK
- Webhook-Replay-Feature
- Advanced Filtering (z.B. nur ERC20 Transfers > $1000)
- Webhook-Templates

---

## 3. Technologie-Stack

### Backend
- **Language:** Elixir 1.14+
- **Framework:** Phoenix 1.7+
- **Database:** PostgreSQL 14+
- **ORM:** Ecto 3.10+
- **HTTP Client:** HTTPoison oder Req
- **JSON:** Jason

### Testing
- **Unit Tests:** ExUnit
- **Integration Tests:** ExUnit + Phoenix.ConnTest
- **Load Tests:** k6 oder Apache Bench
- **Mocking:** Mox

### Deployment
- **Container:** Docker
- **Orchestration:** Kubernetes (falls verwendet)
- **CI/CD:** GitHub Actions
- **Monitoring:** Prometheus + Grafana (optional)
- **Logging:** Elixir Logger + Logstash (optional)

### Documentation
- **API Docs:** OpenAPI 3.0 (Swagger)
- **Code Docs:** ExDoc
- **User Guide:** Markdown

---

## 4. Implementierungs-Phasen

### Phase 1: Foundation & Setup (Woche 1-2) 🏗️
**Dauer:** 10 Arbeitstage
**Team:** 1 Entwickler
**Output:** Datenbankschema, Basis-Entities, Auth-System

### Phase 2: API Layer (Woche 2-3) 🌐
**Dauer:** 8 Arbeitstage
**Team:** 1-2 Entwickler
**Output:** REST API Endpoints, Request Validation, Response Formatting

### Phase 3: Event Processing (Woche 3-4) 🔄
**Dauer:** 8 Arbeitstage
**Team:** 1 Entwickler
**Output:** Event Listener, Payload Mapping, Address Filtering

### Phase 4: Delivery System (Woche 4-5) 📤
**Dauer:** 8 Arbeitstage
**Team:** 1 Entwickler
**Output:** HTTP Delivery, Retry Service, Signature Generation

### Phase 5: Testing & QA (Woche 5-6) ✅
**Dauer:** 8 Arbeitstage
**Team:** 1-2 Entwickler
**Output:** Test Suite, Bug Fixes, Performance Optimization

### Phase 6: Documentation & Deployment (Woche 6-8) 📚
**Dauer:** 10 Arbeitstage
**Team:** 1 Entwickler
**Output:** API Docs, User Guide, Production Deployment

---

## 5. Detaillierte Task-Liste

### Phase 1: Foundation & Setup (80 Stunden)

#### 1.1 Projektstruktur & Setup (8h)
```bash
# Tasks:
- [ ] Repository-Fork/Branch erstellen
- [ ] Entwicklungsumgebung setup
- [ ] Dependencies hinzufügen (HTTPoison, etc.)
- [ ] Konfigurationsdateien erstellen
- [ ] Feature-Flag einrichten (WEBHOOK_SERVICE_ENABLED)
```

**Files:**
- `config/config.exs` - Feature flags
- `mix.exs` - Dependencies
- `.env.example` - Environment variables

**Dependencies:**
```elixir
# mix.exs
defp deps do
  [
    {:httpoison, "~> 2.0"},      # HTTP client
    {:jason, "~> 1.4"},          # JSON encoding
    {:mox, "~> 1.0", only: :test} # Mocking
  ]
end
```

#### 1.2 Datenbankschema (16h)
```bash
# Tasks:
- [ ] Migration erstellen: webhooks table
- [ ] Migration erstellen: webhook_addresses table
- [ ] Migration erstellen: webhook_delivery_logs table
- [ ] Migration erstellen: auth_tokens table
- [ ] Indexes anlegen
- [ ] Migration testen (up/down)
```

**Files:**
- `apps/explorer/priv/repo/migrations/XXXXXX_create_webhook_tables.exs`

**Migration:**
```elixir
defmodule Explorer.Repo.Migrations.CreateWebhookTables do
  use Ecto.Migration

  def change do
    # webhooks table
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
    create unique_index(:webhooks, [:signing_key])

    # webhook_addresses table
    create table(:webhook_addresses, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :webhook_id, references(:webhooks, type: :string, on_delete: :delete_all), null: false
      add :address, :string, null: false, size: 42
      add :created_at, :utc_datetime, null: false, default: fragment("NOW()")
    end

    create unique_index(:webhook_addresses, [:webhook_id, :address])
    create index(:webhook_addresses, [:webhook_id])
    create index(:webhook_addresses, [:address])

    # webhook_delivery_logs table
    create table(:webhook_delivery_logs, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
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
      add :created_at, :utc_datetime, null: false, default: fragment("NOW()")
    end

    create index(:webhook_delivery_logs, [:webhook_id, :status])
    create index(:webhook_delivery_logs, [:event_id])
    create index(:webhook_delivery_logs, [:transaction_hash])
    create index(:webhook_delivery_logs, [:next_retry_at], where: "status = 'pending'")

    # auth_tokens table
    create table(:auth_tokens, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
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

#### 1.3 Schema/Entity Definitions (20h)
```bash
# Tasks:
- [ ] Webhook Entity erstellen
- [ ] WebhookAddress Entity erstellen
- [ ] WebhookDeliveryLog Entity erstellen
- [ ] AuthToken Entity erstellen
- [ ] Changesets definieren
- [ ] Validierungen implementieren
- [ ] Relationships definieren
```

**Files:**
- `apps/explorer/lib/explorer/chain/webhook/webhook.ex`
- `apps/explorer/lib/explorer/chain/webhook/webhook_address.ex`
- `apps/explorer/lib/explorer/chain/webhook/webhook_delivery_log.ex`
- `apps/explorer/lib/explorer/chain/webhook/auth_token.ex`

**Example Entity:**
```elixir
# apps/explorer/lib/explorer/chain/webhook/webhook.ex
defmodule Explorer.Chain.Webhook do
  use Explorer.Schema

  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "webhooks" do
    field :user_id, Ecto.UUID
    field :network, :string
    field :webhook_type, :string
    field :webhook_url, :string
    field :is_active, :boolean, default: true
    field :time_created, :integer
    field :version, :string, default: "V2"
    field :signing_key, :string
    field :name, :string
    field :app_id, :string

    has_many :addresses, Explorer.Chain.WebhookAddress, foreign_key: :webhook_id
    has_many :delivery_logs, Explorer.Chain.WebhookDeliveryLog, foreign_key: :webhook_id

    timestamps()
  end

  @required_fields ~w(user_id network webhook_type webhook_url time_created signing_key)a
  @optional_fields ~w(is_active version name app_id)a

  def changeset(webhook, attrs \\ %{}) do
    webhook
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:webhook_type, ["ADDRESS_ACTIVITY"])
    |> validate_url(:webhook_url)
    |> unique_constraint(:signing_key)
  end

  defp validate_url(changeset, field) do
    validate_change(changeset, field, fn _, url ->
      case URI.parse(url) do
        %URI{scheme: scheme, host: host} when scheme in ["http", "https"] and not is_nil(host) ->
          []
        _ ->
          [{field, "must be a valid HTTP(S) URL"}]
      end
    end)
  end
end
```

#### 1.4 Helper Modules (16h)
```bash
# Tasks:
- [ ] ID-Generator erstellen (webhook_id, event_id, signing_key, auth_token)
- [ ] Address-Normalizer erstellen
- [ ] Signature Service erstellen (HMAC-SHA256)
- [ ] Error-Handler erstellen
- [ ] Unit Tests schreiben
```

**Files:**
- `apps/explorer/lib/explorer/webhook/id_generator.ex`
- `apps/explorer/lib/explorer/webhook/address_normalizer.ex`
- `apps/explorer/lib/explorer/webhook/signature_service.ex`

**Example Helper:**
```elixir
# apps/explorer/lib/explorer/webhook/id_generator.ex
defmodule Explorer.Webhook.IdGenerator do
  @moduledoc """
  Generates unique IDs for webhooks, events, signing keys, and auth tokens.
  """

  def generate_webhook_id do
    "wh_" <> random_string(16)
  end

  def generate_event_id do
    "whevt_" <> random_string(12)
  end

  def generate_signing_key do
    "whsec_" <> random_string(32)
  end

  def generate_auth_token do
    "whauth_" <> random_string(32)
  end

  defp random_string(bytes) do
    bytes
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
  end
end

# apps/explorer/lib/explorer/webhook/signature_service.ex
defmodule Explorer.Webhook.SignatureService do
  @moduledoc """
  HMAC-SHA256 signature generation and verification for webhooks.
  """

  def generate_signature(signing_key, payload) when is_binary(payload) do
    :crypto.mac(:hmac, :sha256, signing_key, payload)
    |> Base.encode16(case: :lower)
  end

  def generate_signature(signing_key, payload) do
    generate_signature(signing_key, Jason.encode!(payload))
  end

  def verify_signature(signing_key, payload, expected_signature) do
    computed = generate_signature(signing_key, payload)
    Plug.Crypto.secure_compare(computed, expected_signature)
  end
end

# apps/explorer/lib/explorer/webhook/address_normalizer.ex
defmodule Explorer.Webhook.AddressNormalizer do
  @moduledoc """
  Normalizes Ethereum addresses to lowercase with 0x prefix.
  """

  def normalize(address) when is_binary(address) do
    address
    |> String.downcase()
    |> ensure_0x_prefix()
  end

  def normalize(addresses) when is_list(addresses) do
    Enum.map(addresses, &normalize/1)
  end

  defp ensure_0x_prefix("0x" <> _ = address), do: address
  defp ensure_0x_prefix(address), do: "0x" <> address

  def valid?(address) do
    Regex.match?(~r/^0x[a-f0-9]{40}$/i, address)
  end
end
```

#### 1.5 Repository Layer (20h)
```bash
# Tasks:
- [ ] WebhookRepository erstellen
- [ ] WebhookAddressRepository erstellen
- [ ] WebhookDeliveryLogRepository erstellen
- [ ] AuthTokenRepository erstellen
- [ ] Query-Funktionen implementieren
- [ ] Transaction-Support
- [ ] Unit Tests schreiben
```

**Files:**
- `apps/explorer/lib/explorer/webhook/webhook_repository.ex`

**Example Repository:**
```elixir
# apps/explorer/lib/explorer/webhook/webhook_repository.ex
defmodule Explorer.Webhook.WebhookRepository do
  import Ecto.Query

  alias Explorer.Repo
  alias Explorer.Chain.{Webhook, WebhookAddress}

  def get(id) do
    Repo.get(Webhook, id)
  end

  def get_with_addresses(id) do
    Webhook
    |> preload(:addresses)
    |> Repo.get(id)
  end

  def list_by_user(user_id) do
    Webhook
    |> where([w], w.user_id == ^user_id)
    |> order_by([w], desc: w.time_created)
    |> Repo.all()
  end

  def list_active_by_network(network) do
    Webhook
    |> where([w], w.network == ^network and w.is_active == true)
    |> preload(:addresses)
    |> Repo.all()
  end

  def create(attrs) do
    %Webhook{}
    |> Webhook.changeset(attrs)
    |> Repo.insert()
  end

  def update(webhook, attrs) do
    webhook
    |> Webhook.changeset(attrs)
    |> Repo.update()
  end

  def delete(webhook) do
    Repo.delete(webhook)
  end

  def add_addresses(webhook_id, addresses) do
    now = DateTime.utc_now()

    entries = Enum.map(addresses, fn address ->
      %{
        webhook_id: webhook_id,
        address: address,
        created_at: now
      }
    end)

    Repo.insert_all(WebhookAddress, entries,
      on_conflict: :nothing,
      conflict_target: [:webhook_id, :address]
    )
  end

  def remove_addresses(webhook_id, addresses) do
    from(wa in WebhookAddress,
      where: wa.webhook_id == ^webhook_id and wa.address in ^addresses
    )
    |> Repo.delete_all()
  end

  def get_addresses(webhook_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)
    offset = Keyword.get(opts, :offset, 0)

    query =
      from(wa in WebhookAddress,
        where: wa.webhook_id == ^webhook_id,
        select: wa.address,
        limit: ^limit,
        offset: ^offset
      )

    addresses = Repo.all(query)

    count_query =
      from(wa in WebhookAddress,
        where: wa.webhook_id == ^webhook_id,
        select: count()
      )

    total_count = Repo.one(count_query)

    {addresses, total_count}
  end

  def find_webhooks_for_address(address, network) do
    from(w in Webhook,
      join: wa in WebhookAddress,
      on: wa.webhook_id == w.id,
      where: wa.address == ^address and w.network == ^network and w.is_active == true
    )
    |> Repo.all()
  end
end
```

---

### Phase 2: API Layer (64 Stunden)

#### 2.1 Authentication Middleware (8h)
```bash
# Tasks:
- [ ] AuthTokenPlug erstellen
- [ ] Token-Validierung implementieren
- [ ] Error-Handling
- [ ] Rate-Limiting (optional)
- [ ] Tests schreiben
```

**Files:**
- `apps/block_scout_web/lib/block_scout_web/plugs/auth_token_plug.ex`

**Example Plug:**
```elixir
# apps/block_scout_web/lib/block_scout_web/plugs/auth_token_plug.ex
defmodule BlockScoutWeb.Plugs.AuthTokenPlug do
  import Plug.Conn
  import Phoenix.Controller

  alias Explorer.Webhook.AuthTokenRepository

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_req_header(conn, "x-alchemy-token") do
      [token] ->
        case AuthTokenRepository.validate(token) do
          {:ok, auth_token} ->
            conn
            |> assign(:current_auth_token, auth_token)
            |> assign(:current_user_id, auth_token.user_id)

          {:error, :invalid_token} ->
            conn
            |> put_status(:unauthorized)
            |> json(%{error: "Invalid authentication token"})
            |> halt()

          {:error, :token_inactive} ->
            conn
            |> put_status(:unauthorized)
            |> json(%{error: "Authentication token is inactive"})
            |> halt()
        end

      [] ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Missing X-Alchemy-Token header"})
        |> halt()
    end
  end
end
```

#### 2.2 API Controller (24h)
```bash
# Tasks:
- [ ] WebhookController erstellen
- [ ] POST /create-webhook implementieren
- [ ] GET /team-webhooks implementieren
- [ ] PUT /update-webhook implementieren
- [ ] PATCH /update-webhook-addresses implementieren
- [ ] GET /webhook-addresses implementieren
- [ ] DELETE /delete-webhook implementieren
- [ ] Input-Validierung
- [ ] Error-Handling
```

**Files:**
- `apps/block_scout_web/lib/block_scout_web/controllers/api/v2/webhook_controller.ex`

**Example Controller:**
```elixir
# apps/block_scout_web/lib/block_scout_web/controllers/api/v2/webhook_controller.ex
defmodule BlockScoutWeb.API.V2.WebhookController do
  use BlockScoutWeb, :controller

  alias Explorer.Webhook.Manager
  alias BlockScoutWeb.API.V2.WebhookView

  plug BlockScoutWeb.Plugs.AuthTokenPlug

  def create(conn, params) do
    user_id = conn.assigns.current_user_id

    with {:ok, webhook} <- Manager.create_webhook(user_id, params) do
      conn
      |> put_status(:created)
      |> render("webhook.json", %{webhook: webhook})
    else
      {:error, changeset} ->
        conn
        |> put_status(:bad_request)
        |> render("error.json", %{changeset: changeset})
    end
  end

  def list(conn, _params) do
    user_id = conn.assigns.current_user_id
    webhooks = Manager.list_webhooks(user_id)
    total_count = length(webhooks)

    conn
    |> render("webhooks.json", %{webhooks: webhooks, total_count: total_count})
  end

  def update(conn, %{"webhook_id" => webhook_id} = params) do
    user_id = conn.assigns.current_user_id

    with {:ok, webhook} <- Manager.get_webhook(webhook_id, user_id),
         {:ok, updated} <- Manager.update_webhook(webhook, params) do
      conn
      |> render("webhook.json", %{webhook: updated})
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Webhook not found"})

      {:error, changeset} ->
        conn
        |> put_status(:bad_request)
        |> render("error.json", %{changeset: changeset})
    end
  end

  def update_addresses(conn, %{"webhook_id" => webhook_id} = params) do
    user_id = conn.assigns.current_user_id
    addresses_to_add = Map.get(params, "addresses_to_add", [])
    addresses_to_remove = Map.get(params, "addresses_to_remove", [])

    with {:ok, _webhook} <- Manager.get_webhook(webhook_id, user_id),
         :ok <- Manager.update_addresses(webhook_id, addresses_to_add, addresses_to_remove) do
      conn
      |> json(%{})
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Webhook not found"})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  def get_addresses(conn, %{"webhook_id" => webhook_id} = params) do
    user_id = conn.assigns.current_user_id
    limit = Map.get(params, "limit", 100)
    offset = Map.get(params, "offset", 0)

    with {:ok, _webhook} <- Manager.get_webhook(webhook_id, user_id),
         {addresses, total_count} <- Manager.get_addresses(webhook_id, limit: limit, offset: offset) do
      conn
      |> json(%{data: addresses, totalCount: total_count})
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Webhook not found"})
    end
  end

  def delete(conn, %{"webhook_id" => webhook_id}) do
    user_id = conn.assigns.current_user_id

    with {:ok, webhook} <- Manager.get_webhook(webhook_id, user_id),
         {:ok, _deleted} <- Manager.delete_webhook(webhook) do
      conn
      |> json(%{})
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Webhook not found"})
    end
  end
end
```

#### 2.3 View Layer (8h)
```bash
# Tasks:
- [ ] WebhookView erstellen
- [ ] JSON-Rendering implementieren (Alchemy-Format)
- [ ] Error-Rendering
- [ ] Tests schreiben
```

**Files:**
- `apps/block_scout_web/lib/block_scout_web/views/api/v2/webhook_view.ex`

**Example View:**
```elixir
# apps/block_scout_web/lib/block_scout_web/views/api/v2/webhook_view.ex
defmodule BlockScoutWeb.API.V2.WebhookView do
  use BlockScoutWeb, :view

  def render("webhook.json", %{webhook: webhook}) do
    %{
      data: serialize_webhook(webhook)
    }
  end

  def render("webhooks.json", %{webhooks: webhooks, total_count: total_count}) do
    %{
      data: Enum.map(webhooks, &serialize_webhook/1),
      totalCount: total_count
    }
  end

  def render("error.json", %{changeset: changeset}) do
    %{
      errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
    }
  end

  defp serialize_webhook(webhook) do
    %{
      id: webhook.id,
      network: webhook.network,
      webhook_type: webhook.webhook_type,
      webhook_url: webhook.webhook_url,
      is_active: webhook.is_active,
      time_created: webhook.time_created,
      version: webhook.version,
      signing_key: webhook.signing_key,
      name: webhook.name,
      app_id: webhook.app_id
    }
    |> remove_nil_values()
  end

  defp remove_nil_values(map) do
    map
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.into(%{})
  end
end
```

#### 2.4 Business Logic Layer (16h)
```bash
# Tasks:
- [ ] Manager-Module erstellen
- [ ] Create-Webhook-Logik
- [ ] Update-Webhook-Logik
- [ ] Delete-Webhook-Logik
- [ ] Address-Management
- [ ] Validierungen
- [ ] Transaction-Handling
- [ ] Tests schreiben
```

**Files:**
- `apps/explorer/lib/explorer/webhook/manager.ex`

#### 2.5 Router & Routes (4h)
```bash
# Tasks:
- [ ] Routen definieren
- [ ] Scope erstellen
- [ ] Pipeline konfigurieren
```

**Files:**
- `apps/block_scout_web/lib/block_scout_web/router.ex`

**Example Routes:**
```elixir
# apps/block_scout_web/lib/block_scout_web/router.ex
scope "/api/webhooks", BlockScoutWeb.API.V2 do
  pipe_through :api

  post "/create-webhook", WebhookController, :create
  get "/team-webhooks", WebhookController, :list
  put "/update-webhook", WebhookController, :update
  patch "/update-webhook-addresses", WebhookController, :update_addresses
  get "/webhook-addresses", WebhookController, :get_addresses
  delete "/delete-webhook", WebhookController, :delete
end
```

#### 2.6 Integration Tests (8h)
```bash
# Tasks:
- [ ] Controller Tests schreiben
- [ ] Authentication Tests
- [ ] CRUD-Operation Tests
- [ ] Edge-Case Tests
```

---

### Phase 3: Event Processing (64 Stunden)

#### 3.1 Event Listener Integration (16h)
```bash
# Tasks:
- [ ] WebhookBroadcaster GenServer erstellen
- [ ] Registry-Subscription zu Explorer.Chain.Events.Listener
- [ ] Event-Filtering
- [ ] Tests schreiben
```

**Files:**
- `apps/explorer/lib/explorer/chain/events/webhook_broadcaster.ex`

**Example GenServer:**
```elixir
# apps/explorer/lib/explorer/chain/events/webhook_broadcaster.ex
defmodule Explorer.Chain.Events.WebhookBroadcaster do
  use GenServer

  require Logger

  alias Explorer.Chain.Events.Listener
  alias Explorer.Webhook.{TransactionProcessor, DeliveryService}

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Registry.register(Registry.ChainEvents, :transactions, [])
    {:ok, %{}}
  end

  def handle_info({:chain_event, :transactions, :realtime, transactions}, state) do
    Task.Supervisor.async_nolink(WebhookTaskSupervisor, fn ->
      process_transactions(transactions)
    end)

    {:noreply, state}
  end

  def handle_info({:chain_event, _event_type}, state) do
    # Ignore other events
    {:noreply, state}
  end

  def handle_info({_ref, :ok}, state) do
    # Task completed successfully
    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, _pid, :normal}, state) do
    # Task process ended normally
    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, _pid, reason}, state) do
    Logger.error("Webhook processing task failed: #{inspect(reason)}")
    {:noreply, state}
  end

  defp process_transactions(transactions) do
    transactions
    |> Enum.each(&TransactionProcessor.process/1)
  end
end
```

#### 3.2 Transaction Processor (20h)
```bash
# Tasks:
- [ ] TransactionProcessor erstellen
- [ ] Address-Matching implementieren
- [ ] Transaction → Activity Mapping
- [ ] Token-Transfer-Handling
- [ ] Internal-Transaction-Handling
- [ ] Tests schreiben
```

**Files:**
- `apps/explorer/lib/explorer/webhook/transaction_processor.ex`
- `apps/explorer/lib/explorer/webhook/payload_mapper.ex`

**Example Processor:**
```elixir
# apps/explorer/lib/explorer/webhook/transaction_processor.ex
defmodule Explorer.Webhook.TransactionProcessor do
  require Logger

  alias Explorer.Chain.{Transaction, TokenTransfer, InternalTransaction}
  alias Explorer.Repo
  alias Explorer.Webhook.{WebhookRepository, PayloadMapper, DeliveryService}

  import Ecto.Query

  def process(%Transaction{} = transaction) do
    # Get network
    network = get_network()

    # Find matching webhooks
    involved_addresses = get_involved_addresses(transaction)

    matching_webhooks =
      involved_addresses
      |> Enum.flat_map(&WebhookRepository.find_webhooks_for_address(&1, network))
      |> Enum.uniq_by(& &1.id)

    if Enum.any?(matching_webhooks) do
      # Load related data
      transaction = Repo.preload(transaction, [:token_transfers, :logs, :internal_transactions])

      # Build payload
      payload = PayloadMapper.build_payload(transaction, network)

      # Deliver to each webhook
      Enum.each(matching_webhooks, fn webhook ->
        DeliveryService.deliver(webhook, payload)
      end)
    end
  end

  defp get_involved_addresses(%Transaction{} = tx) do
    base_addresses = [
      normalize_address(tx.from_address_hash),
      normalize_address(tx.to_address_hash)
    ]

    # Add token transfer addresses
    token_addresses =
      tx.token_transfers
      |> Enum.flat_map(fn tt ->
        [
          normalize_address(tt.from_address_hash),
          normalize_address(tt.to_address_hash)
        ]
      end)

    # Add internal transaction addresses
    internal_addresses =
      tx.internal_transactions
      |> Enum.flat_map(fn it ->
        [
          normalize_address(it.from_address_hash),
          normalize_address(it.to_address_hash)
        ]
      end)

    (base_addresses ++ token_addresses ++ internal_addresses)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp normalize_address(nil), do: nil
  defp normalize_address(hash) do
    hash
    |> to_string()
    |> String.downcase()
  end

  defp get_network do
    # Get from config or environment
    Application.get_env(:explorer, :network) || "ETH_MAINNET"
  end
end
```

#### 3.3 Payload Mapper (20h)
```bash
# Tasks:
- [ ] PayloadMapper erstellen
- [ ] External-Transaction Mapping
- [ ] Token-Transfer Mapping (ERC20/721/1155)
- [ ] Log-Mapping
- [ ] Value-Konvertierung (Wei → Decimal)
- [ ] Asset-Symbol-Resolution
- [ ] Tests schreiben
```

**Files:**
- `apps/explorer/lib/explorer/webhook/payload_mapper.ex`

#### 3.4 Integration Tests (8h)
```bash
# Tasks:
- [ ] End-to-End Event Flow Tests
- [ ] Address-Matching Tests
- [ ] Payload-Format Tests
```

---

### Phase 4: Delivery System (64 Stunden)

#### 4.1 Delivery Service (20h)
```bash
# Tasks:
- [ ] DeliveryService erstellen
- [ ] HTTP POST Implementation
- [ ] Signature-Generation
- [ ] Response-Handling
- [ ] Logging (Success/Failure)
- [ ] Timeout-Handling
- [ ] Connection-Pooling
- [ ] Tests schreiben
```

**Files:**
- `apps/explorer/lib/explorer/webhook/delivery_service.ex`

**Example Service:**
```elixir
# apps/explorer/lib/explorer/webhook/delivery_service.ex
defmodule Explorer.Webhook.DeliveryService do
  require Logger

  alias Explorer.Webhook.{IdGenerator, SignatureService, DeliveryLogRepository}
  alias HTTPoison.Response

  @timeout 30_000
  @max_body_size 1_000_000

  def deliver(webhook, payload) do
    event_id = IdGenerator.generate_event_id()

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

    start_time = System.monotonic_time()

    case HTTPoison.post(webhook.webhook_url, json_body, headers, timeout: @timeout, recv_timeout: @timeout) do
      {:ok, %Response{status_code: code, body: body}} when code in 200..299 ->
        latency = System.monotonic_time() - start_time
        log_success(webhook.id, event_id, full_payload, code, body, latency)
        {:ok, :delivered}

      {:ok, %Response{status_code: code, body: body}} ->
        log_failure(webhook.id, event_id, full_payload, code, body, "HTTP #{code}")
        schedule_retry(webhook.id, event_id, full_payload)
        {:error, :delivery_failed}

      {:error, %HTTPoison.Error{reason: reason}} ->
        log_failure(webhook.id, event_id, full_payload, nil, nil, inspect(reason))
        schedule_retry(webhook.id, event_id, full_payload)
        {:error, reason}
    end
  rescue
    error ->
      Logger.error("Webhook delivery exception: #{inspect(error)}")
      log_failure(webhook.id, event_id, full_payload, nil, nil, Exception.message(error))
      schedule_retry(webhook.id, event_id, full_payload)
      {:error, :exception}
  end

  defp log_success(webhook_id, event_id, payload, code, body, latency) do
    Logger.info("Webhook delivered successfully",
      webhook_id: webhook_id,
      event_id: event_id,
      response_code: code,
      latency_ms: System.convert_time_unit(latency, :native, :millisecond)
    )

    DeliveryLogRepository.create(%{
      webhook_id: webhook_id,
      event_id: event_id,
      transaction_hash: get_transaction_hash(payload),
      block_number: get_block_number(payload),
      payload: payload,
      status: "success",
      attempts: 1,
      last_attempt_at: DateTime.utc_now(),
      response_code: code,
      response_body: truncate_body(body)
    })
  end

  defp log_failure(webhook_id, event_id, payload, code, body, error) do
    Logger.warn("Webhook delivery failed",
      webhook_id: webhook_id,
      event_id: event_id,
      response_code: code,
      error: error
    )

    DeliveryLogRepository.create(%{
      webhook_id: webhook_id,
      event_id: event_id,
      transaction_hash: get_transaction_hash(payload),
      block_number: get_block_number(payload),
      payload: payload,
      status: "pending",
      attempts: 1,
      last_attempt_at: DateTime.utc_now(),
      response_code: code,
      response_body: truncate_body(body),
      error_message: error,
      next_retry_at: calculate_next_retry(1)
    })
  end

  defp schedule_retry(webhook_id, event_id, payload) do
    # Retry will be handled by RetryService
    :ok
  end

  defp calculate_next_retry(attempts) do
    delay_seconds = case attempts do
      1 -> 60          # 1 minute
      2 -> 300         # 5 minutes
      3 -> 900         # 15 minutes
      4 -> 3600        # 1 hour
      5 -> 21600       # 6 hours
      _ -> nil
    end

    if delay_seconds do
      DateTime.utc_now() |> DateTime.add(delay_seconds, :second)
    else
      nil
    end
  end

  defp get_transaction_hash(%{event: %{activity: [first | _]}}), do: first[:hash]
  defp get_transaction_hash(_), do: "unknown"

  defp get_block_number(%{event: %{activity: [first | _]}}) do
    case first[:blockNum] do
      "0x" <> hex -> String.to_integer(hex, 16)
      _ -> 0
    end
  end
  defp get_block_number(_), do: 0

  defp truncate_body(nil), do: nil
  defp truncate_body(body) when byte_size(body) > @max_body_size do
    binary_part(body, 0, @max_body_size) <> "... (truncated)"
  end
  defp truncate_body(body), do: body
end
```

#### 4.2 Retry Service (20h)
```bash
# Tasks:
- [ ] RetryService GenServer erstellen
- [ ] Periodic Job (30s interval)
- [ ] Query pending deliveries
- [ ] Exponential Backoff implementieren
- [ ] Max-Retry-Handling (5 attempts)
- [ ] Tests schreiben
```

**Files:**
- `apps/explorer/lib/explorer/webhook/retry_service.ex`

**Example Service:**
```elixir
# apps/explorer/lib/explorer/webhook/retry_service.ex
defmodule Explorer.Webhook.RetryService do
  use GenServer

  require Logger

  alias Explorer.Webhook.{DeliveryLogRepository, WebhookRepository, DeliveryService}

  @interval 30_000  # 30 seconds
  @max_retries 5

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    schedule_work()
    {:ok, %{}}
  end

  def handle_info(:process_retries, state) do
    process_pending_deliveries()
    schedule_work()
    {:noreply, state}
  end

  defp schedule_work do
    Process.send_after(self(), :process_retries, @interval)
  end

  defp process_pending_deliveries do
    pending = DeliveryLogRepository.get_pending_retries()

    Logger.info("Processing #{length(pending)} pending webhook deliveries")

    Enum.each(pending, &retry_delivery/1)
  end

  defp retry_delivery(log) do
    if log.attempts >= @max_retries do
      mark_as_failed(log)
    else
      webhook = WebhookRepository.get(log.webhook_id)

      if webhook && webhook.is_active do
        attempt_delivery(webhook, log)
      else
        Logger.warn("Webhook #{log.webhook_id} not found or inactive, skipping retry")
      end
    end
  end

  defp attempt_delivery(webhook, log) do
    case DeliveryService.deliver(webhook, log.payload.event) do
      {:ok, :delivered} ->
        DeliveryLogRepository.mark_as_success(log.id)

      {:error, _reason} ->
        DeliveryLogRepository.increment_attempts(log.id, calculate_next_retry(log.attempts + 1))
    end
  end

  defp mark_as_failed(log) do
    Logger.error("Webhook delivery failed after #{@max_retries} attempts",
      webhook_id: log.webhook_id,
      event_id: log.event_id
    )

    DeliveryLogRepository.mark_as_failed(log.id)
  end

  defp calculate_next_retry(attempts) do
    delay_seconds = case attempts do
      1 -> 60
      2 -> 300
      3 -> 900
      4 -> 3600
      5 -> 21600
      _ -> nil
    end

    if delay_seconds do
      DateTime.utc_now() |> DateTime.add(delay_seconds, :second)
    else
      nil
    end
  end
end
```

#### 4.3 Delivery Log Repository (8h)
```bash
# Tasks:
- [ ] DeliveryLogRepository erstellen
- [ ] CRUD-Operationen
- [ ] Query-Funktionen (pending, failed, etc.)
- [ ] Tests schreiben
```

#### 4.4 Supervision Tree (8h)
```bash
# Tasks:
- [ ] Supervisor für Webhook-Services erstellen
- [ ] Task Supervisor für Async-Delivery
- [ ] Application-Integration
```

**Files:**
- `apps/explorer/lib/explorer/webhook/supervisor.ex`

**Example Supervisor:**
```elixir
# apps/explorer/lib/explorer/webhook/supervisor.ex
defmodule Explorer.Webhook.Supervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(_init_arg) do
    children = [
      {Task.Supervisor, name: Explorer.Webhook.TaskSupervisor},
      Explorer.Chain.Events.WebhookBroadcaster,
      Explorer.Webhook.RetryService
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

#### 4.5 Integration Tests (8h)
```bash
# Tasks:
- [ ] Delivery Flow Tests
- [ ] Retry Logic Tests
- [ ] Mock HTTP Server
```

---

### Phase 5: Testing & QA (64 Stunden)

#### 5.1 Unit Tests (24h)
```bash
# Tasks:
- [ ] Entity Tests (Changeset-Validierung)
- [ ] Repository Tests
- [ ] Helper Module Tests
- [ ] Payload Mapper Tests
- [ ] Signature Service Tests
- [ ] ID Generator Tests
```

#### 5.2 Integration Tests (24h)
```bash
# Tasks:
- [ ] API Endpoint Tests (alle 6 Endpoints)
- [ ] Authentication Tests
- [ ] Event Flow Tests (Transaction → Delivery)
- [ ] Retry Mechanism Tests
- [ ] Error Handling Tests
```

#### 5.3 Load Tests (8h)
```bash
# Tasks:
- [ ] k6 Test-Scripts schreiben
- [ ] API Load Test (100 req/s)
- [ ] Webhook Delivery Load Test (1000 webhooks)
- [ ] Database Performance Test
```

**Example k6 Script:**
```javascript
// load_test.js
import http from 'k6/http';
import { check } from 'k6';

export let options = {
  stages: [
    { duration: '30s', target: 20 },
    { duration: '1m', target: 50 },
    { duration: '30s', target: 0 },
  ],
};

const BASE_URL = 'http://localhost:4000/api/webhooks';
const AUTH_TOKEN = 'whauth_test123';

export default function() {
  let payload = JSON.stringify({
    network: 'ETH_MAINNET',
    webhook_type: 'ADDRESS_ACTIVITY',
    webhook_url: 'https://example.com/webhook',
    addresses: ['0x' + '1'.repeat(40)],
    name: 'Load Test Webhook'
  });

  let params = {
    headers: {
      'X-Alchemy-Token': AUTH_TOKEN,
      'Content-Type': 'application/json'
    }
  };

  let res = http.post(`${BASE_URL}/create-webhook`, payload, params);

  check(res, {
    'status is 201': (r) => r.status === 201,
    'response has webhook id': (r) => JSON.parse(r.body).data.id !== undefined,
  });
}
```

#### 5.4 Bug Fixes & Optimization (8h)
```bash
# Tasks:
- [ ] Bug-Fixing basierend auf Tests
- [ ] Performance-Optimierung
- [ ] Memory-Leak-Checks
- [ ] Code-Review
```

---

### Phase 6: Documentation & Deployment (80 Stunden)

#### 6.1 API Documentation (16h)
```bash
# Tasks:
- [ ] OpenAPI 3.0 Spec schreiben
- [ ] Swagger UI integrieren
- [ ] Request/Response Beispiele
- [ ] Error Codes dokumentieren
```

**Files:**
- `apps/block_scout_web/priv/static/openapi.yaml`

#### 6.2 User Guide (12h)
```bash
# Tasks:
- [ ] Getting Started Guide
- [ ] Setup Instructions
- [ ] Code Examples (Node.js, Python, Elixir)
- [ ] Troubleshooting Guide
```

**Files:**
- `WEBHOOK_USER_GUIDE.md`

#### 6.3 Developer Documentation (12h)
```bash
# Tasks:
- [ ] Architecture Documentation
- [ ] Code Documentation (ExDoc)
- [ ] Database Schema Documentation
- [ ] Contribution Guide
```

#### 6.4 Deployment Preparation (20h)
```bash
# Tasks:
- [ ] Environment Variables dokumentieren
- [ ] Docker Image erstellen/anpassen
- [ ] Database Migration Plan
- [ ] Rollback Plan
- [ ] Health Checks
- [ ] Monitoring Setup (Prometheus/Grafana)
```

#### 6.5 Staging Deployment (10h)
```bash
# Tasks:
- [ ] Staging-Umgebung Setup
- [ ] Migrations ausführen
- [ ] Smoke Tests
- [ ] Performance Tests
```

#### 6.6 Production Deployment (10h)
```bash
# Tasks:
- [ ] Production-Migrations
- [ ] Feature Flag aktivieren
- [ ] Monitoring aktivieren
- [ ] Post-Deployment Tests
- [ ] DFXswiss Integration Test
```

---

## 6. Abhängigkeiten & Risiken

### 6.1 Technische Abhängigkeiten

| Abhängigkeit | Beschreibung | Risiko | Mitigation |
|--------------|--------------|---------|-----------|
| **PostgreSQL NOTIFY** | Event-System nutzt PG NOTIFY | Mittel | Bereits im Einsatz, gut getestet |
| **Blockscout Indexer** | Transaktionen müssen indexiert sein | Niedrig | Stabil, produktionsreif |
| **HTTPoison** | HTTP Client für Delivery | Niedrig | Mature Library |
| **User Schema** | Auth Tokens brauchen User-Referenz | Mittel | Falls kein User-System → JWT Alternative |

### 6.2 Risiken

#### Risiko 1: Performance bei hohem Transaction-Volumen
**Wahrscheinlichkeit:** Mittel
**Impact:** Hoch
**Mitigation:**
- Async Processing via Task.Supervisor
- Connection Pooling
- Database Indexing
- Load Testing vor Production

#### Risiko 2: Webhook-Client Downtime
**Wahrscheinlichkeit:** Hoch
**Impact:** Mittel
**Mitigation:**
- Retry-Mechanismus (5 Versuche)
- Exponential Backoff
- Delivery Logs für Debugging

#### Risiko 3: Inkompatibilität mit DFXswiss
**Wahrscheinlichkeit:** Niedrig
**Impact:** Hoch
**Mitigation:**
- Exakte Alchemy-Kompatibilität
- Integration Tests mit DFXswiss-Code
- Beta-Phase mit Real-World Testing

#### Risiko 4: Datenbankgröße (Delivery Logs)
**Wahrscheinlichkeit:** Mittel
**Impact:** Mittel
**Mitigation:**
- Retention Policy (z.B. 30 Tage)
- Archivierungs-Job
- Partitioning (optional)

#### Risiko 5: Security (DDoS, Injection)
**Wahrscheinlichkeit:** Niedrig
**Impact:** Hoch
**Mitigation:**
- Rate Limiting
- Input Validation
- Ecto Queries (SQL Injection Prevention)
- HTTPS-Only Webhooks

### 6.3 Projekt-Risiken

| Risiko | Wahrscheinlichkeit | Impact | Mitigation |
|--------|-------------------|--------|-----------|
| Scope Creep | Mittel | Hoch | Strikte Scope-Definition, Phasen-Approach |
| Verzögerungen | Mittel | Mittel | Buffer-Zeit eingeplant (6-8 Wochen) |
| Ressourcen-Mangel | Niedrig | Hoch | Klare Task-Aufteilung, 1-2 Devs ausreichend |
| Testing-Lücken | Mittel | Hoch | Umfassende Test-Suite, QA-Phase |

---

## 7. Ressourcen-Planung

### 7.1 Team-Struktur

**Minimal Setup (1 Entwickler):**
- Senior Elixir/Phoenix Developer
- Erfahrung mit Ecto, GenServer, HTTP APIs
- Timeline: 8 Wochen

**Optimal Setup (2 Entwickler):**
- Lead Developer: Architecture, Core Logic
- Junior/Mid Developer: API Layer, Tests, Documentation
- Timeline: 6 Wochen

### 7.2 Skill Requirements

**Erforderlich:**
- ✅ Elixir & Phoenix Framework
- ✅ Ecto & PostgreSQL
- ✅ REST API Design
- ✅ GenServer & OTP
- ✅ HTTP Client/Server
- ✅ Testing (ExUnit)

**Nice-to-Have:**
- 🎯 Blockchain/Ethereum Knowledge
- 🎯 Alchemy API Erfahrung
- 🎯 Docker/Kubernetes
- 🎯 Prometheus/Grafana

### 7.3 Tools & Software

| Tool | Zweck | Lizenz |
|------|-------|--------|
| Elixir 1.14+ | Backend Development | Apache 2.0 |
| Phoenix 1.7+ | Web Framework | MIT |
| PostgreSQL 14+ | Database | PostgreSQL |
| HTTPoison/Req | HTTP Client | MIT |
| k6 | Load Testing | AGPL |
| ExDoc | Documentation | Apache 2.0 |
| GitHub Actions | CI/CD | Free |

---

## 8. Qualitätssicherung

### 8.1 Code Quality Standards

**Code Coverage:**
- Target: 80%+
- Critical Paths: 95%+

**Linting:**
```bash
mix credo --strict
mix format --check-formatted
mix dialyzer
```

**Code Review:**
- Pull Request für jede Phase
- Peer Review vor Merge
- Automated CI Checks

### 8.2 Testing-Strategie

**Test-Pyramide:**
```
       /\
      /E2E\         10% - Integration Tests
     /------\
    /  API  \       20% - API Tests
   /----------\
  /    Unit    \    70% - Unit Tests
 /--------------\
```

**Test-Kategorien:**
1. **Unit Tests:** Entities, Helpers, Mappers
2. **Integration Tests:** API Endpoints, Event Flow
3. **Load Tests:** Performance, Scalability
4. **Manual Tests:** DFXswiss Integration, Production Smoke Tests

### 8.3 Performance Benchmarks

**API Endpoints:**
- Response Time: < 200ms (p95)
- Throughput: 100 req/s
- Error Rate: < 0.1%

**Webhook Delivery:**
- Delivery Latency: < 5s (from transaction to webhook)
- Success Rate: > 95% (first attempt)
- Retry Success: > 99% (after retries)

**Database:**
- Query Time: < 50ms (p95)
- Connection Pool: 20-50 connections
- Write Throughput: 1000 TPS

---

## 9. Deployment-Strategie

### 9.1 Deployment-Phasen

#### Phase 1: Staging (Woche 6)
```bash
# 1. Backup erstellen
pg_dump blockscout_staging > backup_pre_webhook.sql

# 2. Migrations ausführen
mix ecto.migrate

# 3. Deployment
docker-compose up -d

# 4. Smoke Tests
./scripts/smoke_test.sh
```

#### Phase 2: Production Canary (Woche 7)
```bash
# 1. Feature Flag: 10% Traffic
WEBHOOK_SERVICE_ROLLOUT_PERCENTAGE=10

# 2. Monitoring aktivieren
# 3. 48h Observation
# 4. Rollout auf 50%
# 5. Rollout auf 100%
```

#### Phase 3: Full Production (Woche 8)
```bash
# 1. Feature Flag: 100%
WEBHOOK_SERVICE_ENABLED=true

# 2. Monitoring & Alerting
# 3. DFXswiss Integration aktivieren
```

### 9.2 Rollback-Plan

**Bei Kritischen Problemen:**
```bash
# 1. Feature Flag deaktivieren
WEBHOOK_SERVICE_ENABLED=false

# 2. Traffic umleiten (falls nötig)
# 3. Logs analysieren
# 4. Fix deployen
# 5. Re-enable
```

**Bei Datenbank-Problemen:**
```bash
# 1. Service stoppen
# 2. Restore Backup
pg_restore -d blockscout backup_pre_webhook.sql

# 3. Rollback Migration
mix ecto.rollback
```

### 9.3 Monitoring & Alerting

**Metrics:**
```
# Prometheus Metrics
webhook_deliveries_total{status="success|failed"}
webhook_delivery_latency_seconds
webhook_retry_queue_size
webhook_api_requests_total{endpoint="..."}
```

**Alerts:**
- Webhook Delivery Success Rate < 90%
- Retry Queue Size > 10000
- API Error Rate > 5%
- Delivery Latency p95 > 10s

**Dashboards:**
- Grafana Dashboard: Webhook Service Overview
- Panels: Delivery Rate, Latency, Queue Size, API Requests

---

## 10. Success Metrics

### 10.1 Launch Criteria (Go-Live Checklist)

- [ ] Alle 6 API Endpoints funktionieren
- [ ] Test Coverage > 80%
- [ ] Load Tests bestanden (100 req/s)
- [ ] DFXswiss Integration erfolgreich
- [ ] API Dokumentation veröffentlicht
- [ ] Monitoring & Alerting aktiv
- [ ] Rollback-Plan getestet
- [ ] Production Smoke Tests bestanden

### 10.2 Post-Launch Success Metrics (30 Tage)

**Technische Metriken:**
- ✅ Uptime: > 99.9%
- ✅ Webhook Delivery Success Rate: > 95%
- ✅ API Error Rate: < 1%
- ✅ p95 Latency: < 5s

**Business Metriken:**
- ✅ DFXswiss Integration läuft produktiv
- ✅ Keine kritischen Bugs
- ✅ < 10 Support-Tickets

### 10.3 Long-Term Success (90 Tage)

- ✅ 5+ aktive Webhook-Nutzer
- ✅ 100+ Webhooks erstellt
- ✅ 1M+ Webhook-Deliveries
- ✅ API-Dokumentation aktuell
- ✅ Community-Feedback positiv

---

## 11. Nächste Schritte

### Woche 1 - Kick-off
1. ✅ Team-Zusammenstellung
2. ✅ Repository-Setup
3. ✅ Sprint Planning
4. 🚀 **START Phase 1: Foundation**

### Woche 2-8 - Implementierung
- Sprint-basierte Entwicklung (2-Wochen Sprints)
- Wöchentliche Status-Updates
- Continuous Integration & Testing

### Nach Launch - Maintenance
- Bug Fixes & Support
- Performance Optimization
- Feature Requests (Nice-to-Haves)

---

## Anhang

### A. Wichtige Dokumente
- `WEBHOOK_IMPLEMENTATION_SPEC.md` - Technische Spezifikation
- `WEBHOOK_USER_GUIDE.md` - User Guide (erstellen in Phase 6)
- `openapi.yaml` - API Spec (erstellen in Phase 6)

### B. Kontakte
- **Product Owner:** TBD
- **Tech Lead:** TBD
- **DFXswiss Contact:** TBD

### C. Links
- Blockscout Repository: https://github.com/blockscout/blockscout
- Alchemy API Docs: https://docs.alchemy.com/reference/notify-api-quickstart
- DFXswiss API: /Users/me/Documents/GitHub/DFXswiss/api

---

**Dokument-Version:** 1.0
**Erstellt:** 2025-10-25
**Letzte Aktualisierung:** 2025-10-25

**Status:** ✅ Ready for Implementation
