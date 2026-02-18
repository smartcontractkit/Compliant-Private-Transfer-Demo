// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";

interface IVault {
    function withdrawWithTicket(address token, uint256 amount, bytes calldata ticket) external;
}

/// @title WithdrawWithTicket
/// @notice Redeems a withdrawal ticket on-chain to withdraw tokens from the Vault.
///         This script is intended to be run by the account that requested the ticket
///         (e.g. Account 2 who received tokens via private transfer).
///
///         Required env vars:
///           PRIVATE_KEY_2   - Private key of the withdrawing account (Account 2)
///           TOKEN_ADDRESS   - ERC20 token address
///           WITHDRAW_AMOUNT - Amount in wei (e.g. "1000000000000000000" for 1 token)
///           TICKET          - The ticket hex string returned by the /withdraw API
contract WithdrawWithTicket is Script {
    address constant VAULT = 0xE588a6c73933BFD66Af9b4A07d48bcE59c0D2d13;

    function run() external {
        uint256 accountPK = vm.envUint("PRIVATE_KEY_2");
        address account = vm.addr(accountPK);

        address tokenAddr = vm.envAddress("TOKEN_ADDRESS");
        uint256 amount = vm.envUint("WITHDRAW_AMOUNT");
        bytes memory ticket = vm.envBytes("TICKET");

        console.log("Account:", account);
        console.log("Token:", tokenAddr);
        console.log("Amount:", amount);
        console.log("Vault:", VAULT);

        vm.startBroadcast(accountPK);

        IVault(VAULT).withdrawWithTicket(tokenAddr, amount, ticket);

        vm.stopBroadcast();

        console.log("------------------------------------");
        console.log("Successfully withdrew tokens from vault");
        console.log("------------------------------------");
    }
}
