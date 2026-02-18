/**
 * Generate Shielded Address
 *
 * Usage:
 *   npx tsx src/shielded-address.ts
 *
 * Environment:
 *   PRIVATE_KEY_2  - The private key of the account to generate a shielded address for (0x-prefixed)
 */

import { ethers } from "ethers";
import { currentTimestamp, signTypedData, postApi, setUsage } from "./common.js";

setUsage("npx tsx src/shielded-address.ts");

const EIP712_TYPES = {
  "Generate Shielded Address": [
    { name: "account", type: "address" },
    { name: "timestamp", type: "uint256" },
  ],
};

async function main() {
  const privateKey = process.env.PRIVATE_KEY_2;
  if (!privateKey) {
    console.error("Error: PRIVATE_KEY_2 environment variable is not set.");
    process.exit(1);
  }
  const wallet = new ethers.Wallet(privateKey);
  const account = wallet.address;
  const timestamp = currentTimestamp();

  console.log(`Account: ${account}`);
  console.log(`Timestamp: ${timestamp}`);

  const message = { account, timestamp };
  const auth = await signTypedData(wallet, EIP712_TYPES, message);

  await postApi("/shielded-address", {
    account,
    timestamp,
    auth,
  });
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
