defmodule Explorer.SmartContract.UpstreamExplorerInterface do
  @moduledoc """
  Interface for fetching verified smart contract sources from an upstream
  Blockscout explorer (e.g. the official Citrea explorer).

  When a contract is not verified locally and not found in eth-bytecode-db,
  this module queries the upstream explorer's v2 API as a last-resort fallback.
  """

  alias Explorer.HttpClient

  require Logger

  @recv_timeout :timer.seconds(30)

  @spec enabled?() :: boolean()
  def enabled? do
    url = service_url()
    is_binary(url) and url != ""
  end

  @spec fetch_verified_source(String.t()) :: {:ok, map()} | {:error, any()}
  def fetch_verified_source(address_hash_string) do
    url = "#{service_url()}/api/v2/smart-contracts/#{address_hash_string}"

    case HttpClient.get(url, [], recv_timeout: @recv_timeout) do
      {:ok, %{body: body, status_code: 200}} ->
        parse_and_transform(body)

      {:ok, %{status_code: status}} ->
        {:error, {:http_status, status}}

      {:error, reason} ->
        Logger.error("UpstreamExplorerInterface: HTTP error for #{address_hash_string}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp parse_and_transform(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, decoded} -> parse_and_transform(decoded)
      {:error, _} = err -> err
    end
  end

  defp parse_and_transform(%{"is_verified" => true} = data) do
    {:ok, transform_response(data)}
  end

  defp parse_and_transform(%{"is_verified" => false}) do
    {:error, :not_verified_upstream}
  end

  defp parse_and_transform(_), do: {:error, :unexpected_response}

  @spec transform_response(map()) :: map()
  def transform_response(data) do
    source_files = build_source_files(data)

    %{
      "sourceType" => source_type(data["language"]),
      "matchType" => match_type(data["is_partially_verified"]),
      "sourceFiles" => source_files,
      "abi" => Jason.encode!(data["abi"] || []),
      "compilerSettings" => Jason.encode!(data["compiler_settings"] || %{}),
      "constructorArguments" => data["constructor_args"] || "",
      "contractName" => data["name"] || "",
      "fileName" => data["file_path"] || "",
      "compilerVersion" => data["compiler_version"] || "",
      "evmVersion" => get_in(data, ["compiler_settings", "evmVersion"]) || "default",
      "optimizationRuns" =>
        to_string(get_in(data, ["compiler_settings", "optimizer", "runs"]) || "200"),
      "isOptimization" => get_in(data, ["compiler_settings", "optimizer", "enabled"]) || false
    }
  end

  defp build_source_files(data) do
    main_source =
      if data["file_path"] && data["source_code"] do
        %{data["file_path"] => data["source_code"]}
      else
        %{}
      end

    additional =
      (data["additional_sources"] || [])
      |> Enum.reduce(%{}, fn item, acc ->
        Map.put(acc, item["file_path"] || "unknown", item["source_code"] || "")
      end)

    Map.merge(main_source, additional)
  end

  defp source_type("vyper"), do: "VYPER"
  defp source_type("yul"), do: "YUL"
  defp source_type(_), do: "SOLIDITY"

  defp match_type(true), do: "PARTIAL"
  defp match_type(_), do: "FULL"

  defp service_url do
    Application.get_env(:explorer, __MODULE__)[:service_url]
  end
end
