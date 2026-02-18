# Compliant Private Token Transfer Demo

> This tutorial represents an educational example to use a Chainlink system, product, or service and is provided to demonstrate how to interact with Chainlink’s systems, products, and services to integrate them into your own. This template is provided “AS IS” and “AS AVAILABLE” without warranties of any kind, it has not been audited, and it may be missing key checks or error handling to make the usage of the system, product or service more clear. Do not use the code in this example in a production environment without completing your own audits and application of best practices. Neither Chainlink Labs, the Chainlink Foundation, nor Chainlink node operators are responsible for unintended outputs that are generated due to errors in code.

This project demonstrates how to use the [Compliant Private Token Demo](https://convergence2026-token-api.cldev.cloud/) — a privacy-preserving token system powered by [Chainlink ACE (Automated Compliance Engine)](https://chain.link/automated-compliance-engine).

Users can deposit ERC-20 tokens into an on-chain vault, then transfer them privately off-chain while maintaining regulatory compliance. Withdrawals are handled via signed tickets redeemed on-chain.

## Architecture Overview

```
On-chain (Sepolia)                          Off-chain (API)
┌──────────────────────┐                   ┌──────────────────────────┐
│  ERC20 Token         │                   │  Private Token API       │
│  (SimpleToken)       │                   │                          │
├──────────────────────┤   deposit event   │  /balances               │
│  Vault Contract      │ ───────────────>  │  /private-transfer       │
│  0x615837B3...B12f   │                   │  /shielded-address       │
├──────────────────────┤   withdraw ticket │  /withdraw               │
│  PolicyEngine        │ <───────────────  │  /transactions           │
│  (Chainlink ACE)     │                   │                          │
└──────────────────────┘                   └──────────────────────────┘
```

- **Vault Contract**: Holds deposited tokens on-chain. Enforces compliance via PolicyEngine on deposit/withdraw.
- **PolicyEngine**: Chainlink ACE policy engine that validates all operations against configurable rules.
- **Off-chain API**: Manages private balances, transfers, and withdrawal tickets. All requests are authenticated via EIP-712 signatures.

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- [Git](https://git-scm.com/) installed (for `forge install`)
- A wallet with Sepolia ETH for gas fees
- [MetaMask](https://metamask.io/) or any EIP-712 compatible wallet (for interacting with the API)

## Setup

```bash
# Clone and install dependencies (already done if you cloned this repo)
forge install

# Compile the project
forge build --via-ir

# Set environment variables
export PRIVATE_KEY=<0xyour_private_key>
export RPC_URL=<your_eth_sepolia_rpc_url>
```

## Foundry Scripts

### Option A: All-in-One Setup

`SetupAll.s.sol` executes all 6 steps in a single script:

```bash
forge script script/SetupAll.s.sol:SetupAll \
  --rpc-url $RPC_URL --broadcast --via-ir
```

This will:
1. Deploy a SimpleToken (ERC20)
2. Deploy a PolicyEngine (behind an ERC1967 proxy, `defaultAllow = true`)
3. Mint 100 tokens to your address
4. Approve the Vault to spend your tokens
5. Register the token and PolicyEngine on the Vault
6. Deposit 10 tokens into the Vault

After the script completes, your private balance will be ready to use via the API.

### Option B: Step-by-Step

Run each script individually. This is useful if you want to inspect the results of each step or customize parameters along the way.

#### Step 1 — Deploy ERC20 Token

```bash
forge script script/01_DeployToken.s.sol:DeployToken \
  --rpc-url $RPC_URL --broadcast --via-ir
```

#### Step 2 — Deploy PolicyEngine

```bash
forge script script/02_DeployPolicyEngine.s.sol:DeployPolicyEngine \
  --rpc-url $RPC_URL --broadcast --via-ir
```

#### Step 3 — Mint 100 Tokens

```bash
export TOKEN_ADDRESS=<deployed_token_address>

forge script script/03_MintTokens.s.sol:MintTokens \
  --rpc-url $RPC_URL --broadcast --via-ir
```

#### Step 4 — Approve Vault

```bash
forge script script/04_ApproveVault.s.sol:ApproveVault \
  --rpc-url $RPC_URL --broadcast --via-ir
```

#### Step 5 — Register Token on Vault

Register your token and its PolicyEngine with the Vault contract. This must be done before deposits.

```bash
export POLICY_ENGINE_ADDRESS=<deployed_policy_engine_proxy_address>

forge script script/05_RegisterVault.s.sol:RegisterVault \
  --rpc-url $RPC_URL --broadcast --via-ir
```

#### Step 6 — Deposit Tokens into Vault

```bash
forge script script/06_DepositToVault.s.sol:DepositToVault \
  --rpc-url $RPC_URL --broadcast --via-ir
```

This deposits 10 tokens into the Vault. After the on-chain transaction confirms, the off-chain indexer will detect the `Deposit` event and credit your private balance.

## Using Private Transactions

Once tokens are deposited, you interact with the off-chain API to manage private balances, transfers, and withdrawals. All endpoints have a browser-based UI — just open the URL in your browser and sign with MetaMask.

> **API Base URL**: https://convergence2026-token-api.cldev.cloud  
> **API Documentation**: https://convergence2026-token-api.cldev.cloud/docs

This walkthrough uses two MetaMask accounts:
- **Account 1** (sender): The account that deployed and deposited tokens in the on-chain setup.
- **Account 2** (receiver): A different EOA that will receive a private transfer and withdraw.

### Step 7 — Connect Account 1 and Check Balance

Open https://convergence2026-token-api.cldev.cloud/balances in your browser. Make sure MetaMask is connected with **Account 1**. Sign the request to verify your private balance (should show 10 tokens after deposit).

### Step 8 — Switch to Account 2 and Verify Address

Switch MetaMask to **Account 2**. Refresh the `/balances` page and confirm the displayed address is Account 2's address.

### Step 9 — Check Balance for Account 2

Sign the balance request with Account 2. The balance should be 0 (Account 2 has not received any private tokens yet).

### Step 10 — Generate a Shielded Address for Account 2

Open https://convergence2026-token-api.cldev.cloud/shielded-address with Account 2 still connected. Sign the request to generate a shielded address. **Copy this address** — you will use it in the next step.

A shielded address:
- Looks like a normal Ethereum address but cannot be linked to Account 2's real address.
- Can be shared with senders without revealing Account 2's identity.
- The off-chain service resolves it and credits Account 2's real balance automatically.
- A user may generate multiple shielded addresses so that different senders cannot detect they are transferring to the same underlying account. 

> **Note to privacy directions:** Shielded addresses protect the **recipient's** identity from sender (i.e., the sender does not learn who they are paying). There is also a complementary feature - `hide-sender` flag - which protects the **sender's** identitiy from the recipient (the transfer itself is never exposeed on-chain, but the recipient normally sees where the token came from in their transaction history). We do not use `hide-sender` in this tutorial, but it can be added as a flag during private transfers.

### Step 11 — Switch Back to Account 1

Switch MetaMask back to **Account 1**.

### Step 12 — Private Transfer 1 Token to the Shielded Address

Open https://convergence2026-token-api.cldev.cloud/private-transfer with Account 1 connected. You will see a JSON file as below and fill shielded address generated in step 10 in the recipient. The field amount represents the amount token to be transferred, the field can be any number(in wei) less than the balance of the account.

```json
...
  "message": {
    "sender": "0xc2204bc9e2f41594c9a662dd157e34539ee0c5d1",
    "recipient": "<Add_shielded_addr_here>",
    "token": "<Add_your_token_addr_here>",
    "amount": "1000000000000000000",
    "flags": [],
    "timestamp": "1771250395936"
  }
...
```

Sign and submit. The off-chain service enforces compliance by calling the on-chain PolicyEngine's `checkPrivateTransferAllowed()` function via an off-chain read (`eth_call`), so no transaction information or metadata is exposed on-chain.

### Step 13 — Switch to Account 2 and Verify Transfer

Switch MetaMask to **Account 2**. Open https://convergence2026-token-api.cldev.cloud/balances and sign the balance request. The balance should now show the tokens received from Account 1's private transfer (e.g., 1 token).


### Step 14 — Request Withdrawal

Switch MetaMask to **Account 2**. Open https://convergence2026-token-api.cldev.cloud/withdraw and sign a withdrawal request for the token you just received.

**Note**, do not forget fill in the token field in the JSON on the page. 
```json
...
  "message": {
    "account": "0x93df365bafc36e655cbd30d736a6c5401583d7b2",
    "token": "<Add_your_token_addr_here>",
    "amount": "1000000000000000000",
    "timestamp": "1771251317389"
  }
...
```

The API will return a response as below:
```json
{
  "id": "019c66ce-49dc-756b-bbde-9c98edeff72f",
  "account": "0x93dF365BAFc36E655cbd30D736A6c5401583D7b2",
  "token": "0xa82893525C95197Da290a50EE4CA0d81b77bfb5B",
  "amount": "1000000000000000000",
  "deadline": 1771254921,
  "ticket": "0x16fc6a505bffb6ffff41fd8f03f1f1be00000000699334892ac36e7c67074b4e2a33a8bbc2644134e2cdbc58ad5198432fb09177d0c614216c69a72f26f3908149e78244bf7c0e1ccd18bf89e7169546f94c7d30734c73401c"
}
```

**Copy the `ticket`, `amount` values** — you will need them for the next step.

### Step 15 — Redeem the Ticket On-chain (Script)

Run the `07_WithdrawWithTicket.s.sol` script using **Account 2's private key**:

```bash
export PRIVATE_KEY_2=<0xaccount_2_private_key>
export TOKEN_ADDRESS=<your_token_address>
export WITHDRAW_AMOUNT=<amount_in_wei_from_api_response>
export TICKET=<ticket_hex_from_api_response>

forge script script/07_WithdrawWithTicket.s.sol:WithdrawWithTicket \
  --rpc-url $RPC_URL --broadcast --via-ir
```

After the transaction confirms, Account 2 will have the tokens in their public ERC20 balance on Sepolia.

> If the ticket is not redeemed within 1 hour, the balance is automatically refunded to Account 2's private balance.

## Using Private Transactions via CLI Scripts

As an alternative to the browser-based UI, you can use the TypeScript CLI scripts in the `api-scripts/` folder. These scripts sign EIP-712 requests with your private key and call the API directly from the command line.

This walkthrough uses two private keys:
- **`PRIVATE_KEY`** (Account 1 / sender): The account that deployed and deposited tokens in the on-chain setup.
- **`PRIVATE_KEY_2`** (Account 2 / receiver): A different EOA that will receive a private transfer and withdraw.

### Setup

```bash
cd api-scripts
npm install

# Set environment variables
export PRIVATE_KEY=<0xaccount_1_private_key>
export PRIVATE_KEY_2=<0xaccount_2_private_key>
```

### Step 7 — Account 1: Check Balance

Use Account 1's private key to query its private balance (should show 10 tokens after deposit).

```bash
npx tsx src/balances.ts
```

### Step 8 & 9 — Account 2: Check Balance

Check Account 2's balance. Since Account 2 has not received any private tokens yet, the balance should be 0.

> Note: The `balances.ts` script uses `PRIVATE_KEY` by default. To query Account 2's balance, temporarily set `PRIVATE_KEY` to Account 2's key, or use the browser UI.

```bash
PRIVATE_KEY=$PRIVATE_KEY_2 npx tsx src/balances.ts
```

### Step 10 — Account 2: Generate a Shielded Address

Generate a shielded address for Account 2. This script uses `PRIVATE_KEY_2`.

```bash
npx tsx src/shielded-address.ts
```

The response will contain a shielded address. **Copy this address** — you will use it in the next step.

A shielded address:
- Looks like a normal Ethereum address but cannot be linked to Account 2's real address.
- Can be shared with senders without revealing Account 2's identity.
- The off-chain service resolves it and credits Account 2's real balance automatically.
- A user may generate multiple shielded addresses so that different senders cannot detect they are transferring to the same underlying account.

> **Note on privacy directions:** Shielded addresses protect the **recipient's** identity from the sender (i.e., the sender does not learn who they are paying). There is also a complementary feature — the `hide-sender` flag — which protects the **sender's** identity from the recipient (the transfer itself is never exposed on-chain, but the recipient normally sees where the tokens came from in their transaction history). We do not use `hide-sender` in this tutorial, but it can be added as a flag during private transfers.

### Step 11 & 12 — Account 1: Private Transfer to the Shielded Address

Transfer tokens from Account 1 to Account 2's shielded address. This script uses `PRIVATE_KEY` (Account 1).

```bash
npx tsx src/private-transfer.ts <shielded_address> <token_address> <amount_in_wei>
```

Example (transfer 1 token):

```bash
npx tsx src/private-transfer.ts 0xShieldedAddress 0xTokenAddress 1000000000000000000
```

To hide the sender's address from the recipient, add the `hide-sender` flag:

```bash
npx tsx src/private-transfer.ts 0xShieldedAddress 0xTokenAddress 1000000000000000000 hide-sender
```

The off-chain service enforces compliance by calling the on-chain PolicyEngine's `checkPrivateTransferAllowed()` function via an off-chain read (`eth_call`), so no transaction information or metadata is exposed on-chain.

### Step 13 — Account 2: Request Withdrawal

Request a withdrawal ticket for Account 2. This script uses `PRIVATE_KEY_2`.

```bash
npx tsx src/withdraw.ts <token_address> <amount_in_wei>
```

Example (withdraw 1 token):

```bash
npx tsx src/withdraw.ts 0xTokenAddress 1000000000000000000
```

The API will return a response containing `ticket`, `amount`, and `deadline`. **Copy the `ticket` and `amount` values** — you will need them for the next step.

### Step 14 — Account 2: Redeem the Ticket On-chain

Run the `07_WithdrawWithTicket.s.sol` script using **Account 2's private key**:

```bash
export TOKEN_ADDRESS=<your_token_address>
export WITHDRAW_AMOUNT=<amount_in_wei_from_api_response>
export TICKET=<ticket_hex_from_api_response>

forge script script/07_WithdrawWithTicket.s.sol:WithdrawWithTicket \
  --rpc-url $RPC_URL --broadcast --via-ir
```

After the transaction confirms, Account 2 will have the tokens in their public ERC20 balance on Sepolia.

> If the ticket is not redeemed within 1 hour, the balance is automatically refunded to Account 2's private balance.

### Bonus — List Transaction History

You can view your transaction history at any time:

```bash
# Account 1's transactions (default limit=10)
npx tsx src/transactions.ts

# Account 2's transactions
PRIVATE_KEY=$PRIVATE_KEY_2 npx tsx src/transactions.ts

# With custom limit and pagination cursor
npx tsx src/transactions.ts 20
npx tsx src/transactions.ts 10 <cursor_from_previous_response>
```

## Complete End-to-End Flow

```
On-chain setup (Option A: SetupAll.s.sol, or Option B: steps 1–6)
  1. Deploy ERC20 Token               (01_DeployToken.s.sol)
  2. Deploy PolicyEngine              (02_DeployPolicyEngine.s.sol)
  3. Mint 100 tokens                  (03_MintTokens.s.sol)
  4. Approve Vault                    (04_ApproveVault.s.sol)
  5. Register on Vault                (05_RegisterVault.s.sol)
  6. Deposit 10 tokens                (06_DepositToVault.s.sol)

Off-chain private transactions (Browser UI or CLI scripts)
  7. Account 1: check balance         (Browser: /balances       | CLI: npx tsx src/balances.ts)
  8. Switch to Account 2              (Browser: MetaMask switch  | CLI: use PRIVATE_KEY_2)
  9. Account 2: check balance         (Browser: /balances       | CLI: PRIVATE_KEY=$PRIVATE_KEY_2 npx tsx src/balances.ts)
 10. Account 2: generate shielded addr(Browser: /shielded-address| CLI: npx tsx src/shielded-address.ts)
 11. Switch back to Account 1         (Browser: MetaMask switch  | CLI: uses PRIVATE_KEY by default)
 12. Account 1: transfer to shielded  (Browser: /private-transfer| CLI: npx tsx src/private-transfer.ts ...)
 13. Account 2: request withdraw      (Browser: /withdraw       | CLI: npx tsx src/withdraw.ts ...)
 14. Account 2: redeem ticket on-chain(07_WithdrawWithTicket.s.sol)
```

## Key Addresses

| Contract | Address | Network |
|---|---|---|
| Vault | `0xE588a6c73933BFD66Af9b4A07d48bcE59c0D2d13` | Ethereum Sepolia |

## References

- [API Documentation](https://convergence2026-token-api.cldev.cloud/docs)
- [Chainlink ACE GitHub](https://github.com/smartcontractkit/chainlink-ace)
- [Chainlink ACE Getting Started Guide](https://github.com/smartcontractkit/chainlink-ace/blob/main/getting_started/GETTING_STARTED.md)
