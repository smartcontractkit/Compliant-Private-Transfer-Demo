/**
 * List Transactions
 *
 * Usage:
 *   npx tsx src/transactions.ts [limit] [cursor]
 *
 * Arguments:
 *   limit   - (optional) Maximum number of results to return (default: 10)
 *   cursor  - (optional) Pagination cursor (UUID from previous response)
 *
 * Environment:
 *   PRIVATE_KEY  - The private key of the account to query (0x-prefixed)
 */

import {
  getWallet,
  currentTimestamp,
  signTypedData,
  postApi,
  optionalArg,
  setUsage,
} from "./common.js";

setUsage("npx tsx src/transactions.ts [limit] [cursor]");

const EIP712_TYPES = {
  "List Transactions": [
    { name: "account", type: "address" },
    { name: "timestamp", type: "uint256" },
    { name: "cursor", type: "string" },
    { name: "limit", type: "uint256" },
  ],
};

async function main() {
  const wallet = getWallet();
  const account = wallet.address;
  const timestamp = currentTimestamp();

  const limit = parseInt(optionalArg(0) ?? "10", 10);
  const cursor = optionalArg(1) ?? "";

  console.log(`Account: ${account}`);
  console.log(`Timestamp: ${timestamp}`);
  console.log(`Limit: ${limit}`);
  if (cursor) console.log(`Cursor: ${cursor}`);

  const message = { account, timestamp, cursor, limit };
  const auth = await signTypedData(wallet, EIP712_TYPES, message);

  const body: Record<string, unknown> = {
    account,
    timestamp,
    auth,
    limit,
  };
  if (cursor) {
    body.cursor = cursor;
  }

  await postApi("/transactions", body);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
