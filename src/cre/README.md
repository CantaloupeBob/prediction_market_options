# Chainlink CRE Integration

This directory contains the **CRE (Chainlink Runtime Environment)** integration layer that allows the protocol's core operations to be triggered by automated Chainlink workflows instead of direct onchain calls.

---

## How It Fits Into the Protocol

The `MarketFactory` contract inherits from `CreReceiver`, making it the onchain entry point for all CRE-driven operations. The flow looks like this:

```
Off-chain Workflow → Chainlink Forwarder → MarketFactory.onReport() → Market.writeOption / buyOption / exercise / cancelOption
```

1. An offchain Chainlink workflow determines that an action needs to happen (e.g. a user signed a new option, or a market needs to be settled).
2. The workflow sends a report through the Chainlink Forwarder contract.
3. The Forwarder calls `onReport()` on the `MarketFactory`.
4. `CreReceiver` validates the report's metadata (sender, workflow ID, author, name) against its configured permissions.
5. If all checks pass, the report payload is decoded into a **target market address**, an **operation type**, and the **operation data**.
6. The factory then routes the call to the target `Market` proxy.

### Supported Operations

| Operation  | Description                                                   |
| ---------- | ------------------------------------------------------------- |
| `WRITE`    | Write a new option on a market (seller deposits collateral)   |
| `BUY`      | Purchase an existing option (buyer pays premium to seller)    |
| `EXERCISE` | Settle an option with the resolved price                      |
| `CANCEL`   | Cancel an unfilled option and return collateral to the seller |

Each operation is encoded as an `IMarketFactory.Op` enum and bundled with its corresponding data (signatures, option parameters, etc.) before being sent as the CRE report payload.

---

## Report Payload Format

The report payload (the actual business data) is ABI-encoded as:

```
abi.encode(marketAddress, operation, operationData)
```

Where:

- **`marketAddress`** — the target `Market` contract to call
- **`operation`** — the `IMarketFactory.Op` enum (`WRITE`, `BUY`, `EXERCISE`, `CANCEL`)
- **`operationData`** — ABI-encoded arguments specific to the operation (option params, signatures, etc.)
