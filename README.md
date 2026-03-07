# Prediction Market Options Protocol with CRE Settlement Support

An on-chain options protocol built on top of prediction markets. It lets users write, buy, and settle **call and put options** on prediction market outcome tokens (e.g. from Polymarket).

---

### Key Source Files for CRE (links)

- [`CreReceiver.sol`](https://github.com/CantaloupeBob/prediction_market_options/blob/main/src/cre/CreReceiver.sol) — CreReciever contract. Any inheriting contract becomes a consumer that can handle CRE reports.

## How It Works

### 1. A Market Is Created

An admin creates an **Option Market** tied to a specific prediction market question (e.g. _"Will X happen before 2027?"_). The market is configured with:

- The **Yes** and **No** outcome token IDs from the underlying prediction market
- An **expiry date** (options can't outlast the underlying market)
- **Strike price bounds** that constrain valid option strikes, derived from the prediction market's orderbook

### 2. A Seller Writes an Option

A seller who holds prediction market outcome tokens can **write** an option. They sign a message specifying the terms:

- **Size** — how many outcome tokens are being put up
- **Strike** — the price threshold that determines who wins
- **Premium** — the price a buyer must pay to purchase the option
- **Expiry** — when the option expires
- **Call or Put** — whether it's a call option or a put option

When the option is written, the seller's outcome tokens are transferred into the market contract as collateral. The option is now listed and waiting for a buyer.

### 3. A Buyer Purchases the Option

A buyer who wants the option signs a message and pays the **premium** (in a stablecoin like USDC) directly to the seller. In return, they receive an NFT representing ownership of the option contract.

### 4. The Option Is Settled

Once the outcome of the underlying prediction market is known, a designated **settler** calls the exercise function with the resolved price. The protocol then determines the winner:

- **Call option** — the buyer wins if the final price is **at or above** the strike
- **Put option** — the buyer wins if the final price is **below** the strike

The collateral (outcome tokens) is transferred to the winning party.

### 5. Cancellation

If an option hasn't been bought yet, the seller can **cancel** it and reclaim their collateral.
