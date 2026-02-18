// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {SimpleToken} from "../src/SimpleToken.sol";

/// @title MintTokens
/// @notice Mints 100 tokens (with 18 decimals) to a specified address.
///         Set TOKEN_ADDRESS env var to the deployed SimpleToken address.
///         Set MINT_TO env var to the recipient address (defaults to deployer).
contract MintTokens is Script {
    function run() external {
        uint256 deployerPK = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPK);

        address tokenAddr = vm.envAddress("TOKEN_ADDRESS");
        address mintTo = vm.envOr("MINT_TO", deployer);
        uint256 amount = 100 ether; // 100 tokens with 18 decimals

        SimpleToken token = SimpleToken(tokenAddr);

        console.log("Token:", tokenAddr);
        console.log("Mint to:", mintTo);
        console.log("Amount:", amount);

        vm.startBroadcast(deployerPK);

        token.mint(mintTo, amount);

        vm.stopBroadcast();

        console.log("------------------------------------");
        console.log("Successfully minted 100 tokens to", mintTo);
        console.log("------------------------------------");
    }
}
