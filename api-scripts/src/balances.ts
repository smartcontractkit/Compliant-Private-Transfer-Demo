/**
 * Retrieve Balances
 *
 * Usage:
 *   npx tsx src/balances.ts
 *
 * Environment:
 *   PRIVATE_KEY  - The private key of the account to query (0x-prefixed)
 */

import { getWallet, currentTimestamp, signTypedData, postApi, setUsage } from "./common.js";

setUsage("npx tsx src/balances.ts");

const EIP712_TYPES = {
  "Retrieve Balances": [
    { name: "account", type: "address" },
    { name: "timestamp", type: "uint256" },
  ],
};

async function main() {
  const wallet = getWallet();
  const account = wallet.address;
  const timestamp = currentTimestamp();

  console.log(`Account: ${account}`);
  console.log(`Timestamp: ${timestamp}`);

  const message = { account, timestamp };
  const auth = await signTypedData(wallet, EIP712_TYPES, message);

  await postApi("/balances", {
    account,
    timestamp,
    auth,
  });
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
