/**
 * Withdraw Tokens
 *
 * Usage:
 *   npx tsx src/withdraw.ts <token> <amount>
 *
 * Arguments:
 *   token   - Token contract address (0x-prefixed)
 *   amount  - Amount to withdraw in wei (e.g. "1000000000000000000" for 1 token)
 *
 * Environment:
 *   PRIVATE_KEY_2  - The private key of the account requesting withdrawal (0x-prefixed)
 */

import { ethers } from "ethers";
import {
  currentTimestamp,
  signTypedData,
  postApi,
  requiredArg,
  setUsage,
} from "./common.js";

setUsage("npx tsx src/withdraw.ts <token> <amount>");

const EIP712_TYPES = {
  "Withdraw Tokens": [
    { name: "account", type: "address" },
    { name: "token", type: "address" },
    { name: "amount", type: "uint256" },
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

  const token = requiredArg(0, "token");
  const amount = requiredArg(1, "amount");

  console.log(`Account:   ${account}`);
  console.log(`Token:     ${token}`);
  console.log(`Amount:    ${amount}`);
  console.log(`Timestamp: ${timestamp}`);

  const message = { account, token, amount, timestamp };
  const auth = await signTypedData(wallet, EIP712_TYPES, message);

  await postApi("/withdraw", {
    account,
    token,
    amount,
    timestamp,
    auth,
  });
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
