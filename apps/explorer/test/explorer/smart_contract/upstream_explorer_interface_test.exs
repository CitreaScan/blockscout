defmodule Explorer.SmartContract.UpstreamExplorerInterfaceTest do
  use ExUnit.Case, async: false

  alias Explorer.SmartContract.UpstreamExplorerInterface

  describe "fetch_verified_source/1" do
    setup do
      bypass = Bypass.open()

      Application.put_env(:tesla, :adapter, Tesla.Adapter.Mint)

      Application.put_env(:explorer, UpstreamExplorerInterface,
        service_url: "http://localhost:#{bypass.port}"
      )

      on_exit(fn ->
        Application.put_env(:tesla, :adapter, Explorer.Mock.TeslaAdapter)
        Application.put_env(:explorer, UpstreamExplorerInterface, service_url: nil)
        Bypass.down(bypass)
      end)

      {:ok, bypass: bypass}
    end

    test "returns transformed data for verified contract with valid source", %{bypass: bypass} do
      address = "0x0000000000000000000000000000000000000001"

      response = %{
        "is_verified" => true,
        "file_path" => "contracts/Token.sol",
        "source_code" => "pragma solidity ^0.8.0; contract Token {}",
        "name" => "Token",
        "compiler_version" => "v0.8.20",
        "language" => "solidity",
        "abi" => [%{"type" => "function", "name" => "name"}],
        "compiler_settings" => %{
          "evmVersion" => "paris",
          "optimizer" => %{"enabled" => true, "runs" => 200}
        },
        "is_partially_verified" => false,
        "constructor_args" => "0x1234",
        "additional_sources" => []
      }

      Bypass.expect_once(bypass, "GET", "/api/v2/smart-contracts/#{address}", fn conn ->
        Plug.Conn.resp(conn, 200, Jason.encode!(response))
      end)

      assert {:ok, result} = UpstreamExplorerInterface.fetch_verified_source(address)
      assert result["sourceType"] == "SOLIDITY"
      assert result["matchType"] == "FULL"
      assert result["contractName"] == "Token"
      assert result["fileName"] == "contracts/Token.sol"
      assert result["compilerVersion"] == "v0.8.20"
      assert result["sourceFiles"] == %{"contracts/Token.sol" => "pragma solidity ^0.8.0; contract Token {}"}
    end

    test "returns {:error, :missing_source} when verified but file_path is missing", %{bypass: bypass} do
      address = "0x0000000000000000000000000000000000000002"

      response = %{
        "is_verified" => true,
        "source_code" => "pragma solidity ^0.8.0;"
      }

      Bypass.expect_once(bypass, "GET", "/api/v2/smart-contracts/#{address}", fn conn ->
        Plug.Conn.resp(conn, 200, Jason.encode!(response))
      end)

      assert {:error, :missing_source} = UpstreamExplorerInterface.fetch_verified_source(address)
    end

    test "returns {:error, :missing_source} when verified but file_path is empty", %{bypass: bypass} do
      address = "0x0000000000000000000000000000000000000003"

      response = %{
        "is_verified" => true,
        "file_path" => "",
        "source_code" => "pragma solidity ^0.8.0;"
      }

      Bypass.expect_once(bypass, "GET", "/api/v2/smart-contracts/#{address}", fn conn ->
        Plug.Conn.resp(conn, 200, Jason.encode!(response))
      end)

      assert {:error, :missing_source} = UpstreamExplorerInterface.fetch_verified_source(address)
    end

    test "returns {:error, :missing_source} when verified but source_code is missing", %{bypass: bypass} do
      address = "0x0000000000000000000000000000000000000004"

      response = %{
        "is_verified" => true,
        "file_path" => "contracts/Token.sol"
      }

      Bypass.expect_once(bypass, "GET", "/api/v2/smart-contracts/#{address}", fn conn ->
        Plug.Conn.resp(conn, 200, Jason.encode!(response))
      end)

      assert {:error, :missing_source} = UpstreamExplorerInterface.fetch_verified_source(address)
    end

    test "returns {:error, :missing_source} when verified but source_code is empty", %{bypass: bypass} do
      address = "0x0000000000000000000000000000000000000005"

      response = %{
        "is_verified" => true,
        "file_path" => "contracts/Token.sol",
        "source_code" => ""
      }

      Bypass.expect_once(bypass, "GET", "/api/v2/smart-contracts/#{address}", fn conn ->
        Plug.Conn.resp(conn, 200, Jason.encode!(response))
      end)

      assert {:error, :missing_source} = UpstreamExplorerInterface.fetch_verified_source(address)
    end

    test "returns {:error, :missing_source} when verified but file_path is nil", %{bypass: bypass} do
      address = "0x0000000000000000000000000000000000000006"

      response = %{
        "is_verified" => true,
        "file_path" => nil,
        "source_code" => "pragma solidity ^0.8.0;"
      }

      Bypass.expect_once(bypass, "GET", "/api/v2/smart-contracts/#{address}", fn conn ->
        Plug.Conn.resp(conn, 200, Jason.encode!(response))
      end)

      assert {:error, :missing_source} = UpstreamExplorerInterface.fetch_verified_source(address)
    end

    test "returns {:error, :not_verified_upstream} when not verified", %{bypass: bypass} do
      address = "0x0000000000000000000000000000000000000007"

      response = %{"is_verified" => false}

      Bypass.expect_once(bypass, "GET", "/api/v2/smart-contracts/#{address}", fn conn ->
        Plug.Conn.resp(conn, 200, Jason.encode!(response))
      end)

      assert {:error, :not_verified_upstream} = UpstreamExplorerInterface.fetch_verified_source(address)
    end

    test "returns {:error, {:http_status, status}} for non-200 responses", %{bypass: bypass} do
      address = "0x0000000000000000000000000000000000000008"

      Bypass.expect_once(bypass, "GET", "/api/v2/smart-contracts/#{address}", fn conn ->
        Plug.Conn.resp(conn, 404, "not found")
      end)

      assert {:error, {:http_status, 404}} = UpstreamExplorerInterface.fetch_verified_source(address)
    end

    test "returns partial match type for partially verified contracts", %{bypass: bypass} do
      address = "0x0000000000000000000000000000000000000009"

      response = %{
        "is_verified" => true,
        "file_path" => "contracts/Token.sol",
        "source_code" => "pragma solidity ^0.8.0;",
        "is_partially_verified" => true,
        "name" => "Token",
        "abi" => [],
        "compiler_settings" => %{},
        "compiler_version" => "v0.8.20"
      }

      Bypass.expect_once(bypass, "GET", "/api/v2/smart-contracts/#{address}", fn conn ->
        Plug.Conn.resp(conn, 200, Jason.encode!(response))
      end)

      assert {:ok, result} = UpstreamExplorerInterface.fetch_verified_source(address)
      assert result["matchType"] == "PARTIAL"
    end
  end

  describe "transform_response/1" do
    test "includes additional sources in sourceFiles" do
      data = %{
        "file_path" => "contracts/Main.sol",
        "source_code" => "pragma solidity ^0.8.0;",
        "additional_sources" => [
          %{"file_path" => "contracts/Lib.sol", "source_code" => "library Lib {}"}
        ],
        "name" => "Main",
        "abi" => [],
        "compiler_settings" => %{},
        "compiler_version" => "v0.8.20",
        "language" => "solidity"
      }

      result = UpstreamExplorerInterface.transform_response(data)

      assert result["sourceFiles"] == %{
               "contracts/Main.sol" => "pragma solidity ^0.8.0;",
               "contracts/Lib.sol" => "library Lib {}"
             }
    end

    test "maps vyper language to VYPER source type" do
      data = %{
        "file_path" => "contracts/Token.vy",
        "source_code" => "@external\ndef foo(): pass",
        "language" => "vyper",
        "name" => "Token",
        "abi" => [],
        "compiler_settings" => %{},
        "compiler_version" => "0.3.10"
      }

      result = UpstreamExplorerInterface.transform_response(data)
      assert result["sourceType"] == "VYPER"
    end
  end
end
