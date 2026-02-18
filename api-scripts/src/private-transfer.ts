/**
 * Private Token Transfer
 *
 * Usage:
 *   npx tsx src/private-transfer.ts <recipient> <token> <amount> [flags]
 *
 * Arguments:
 *   recipient - Recipient address (public or shielded, 0x-prefixed)
 *   token     - Token contract address (0x-prefixed)
 *   amount    - Amount to transfer in wei (e.g. "1000000000000000000" for 1 token)
 *   flags     - (optional) Comma-separated flags, e.g. "hide-sender"
 *
 * Environment:
 *   PRIVATE_KEY  - The private key of the sender account (0x-prefixed)
 */

import {
  getWallet,
  currentTimestamp,
  signTypedData,
  postApi,
  requiredArg,
  optionalArg,
  setUsage,
} from "./common.js";

setUsage(
  "npx tsx src/private-transfer.ts <recipient> <token> <amount> [flags]"
);

const EIP712_TYPES = {
  "Private Token Transfer": [
    { name: "sender", type: "address" },
    { name: "recipient", type: "address" },
    { name: "token", type: "address" },
    { name: "amount", type: "uint256" },
    { name: "flags", type: "string[]" },
    { name: "timestamp", type: "uint256" },
  ],
};

async function main() {
  const wallet = getWallet();
  const sender = wallet.address;
  const timestamp = currentTimestamp();

  const recipient = requiredArg(0, "recipient");
  const token = requiredArg(1, "token");
  const amount = requiredArg(2, "amount");
  const flagsRaw = optionalArg(3);
  const flags = flagsRaw ? flagsRaw.split(",").map((f) => f.trim()) : [];

  console.log(`Sender:    ${sender}`);
  console.log(`Recipient: ${recipient}`);
  console.log(`Token:     ${token}`);
  console.log(`Amount:    ${amount}`);
  console.log(`Flags:     ${JSON.stringify(flags)}`);
  console.log(`Timestamp: ${timestamp}`);

  const message = { sender, recipient, token, amount, flags, timestamp };
  const auth = await signTypedData(wallet, EIP712_TYPES, message);

  await postApi("/private-transfer", {
    account: sender,
    recipient,
    token,
    amount,
    flags,
    timestamp,
    auth,
  });
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
