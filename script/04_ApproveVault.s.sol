// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title ApproveVault
/// @notice Approves the Vault contract to spend tokens on behalf of the caller.
///         Set TOKEN_ADDRESS env var to the ERC20 token address.
contract ApproveVault is Script {
    address constant VAULT = 0xE588a6c73933BFD66Af9b4A07d48bcE59c0D2d13;

    function run() external {
        uint256 deployerPK = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPK);

        address tokenAddr = vm.envAddress("TOKEN_ADDRESS");
        uint256 amount = type(uint256).max; // Max approval

        console.log("Token:", tokenAddr);
        console.log("Vault:", VAULT);
        console.log("Approver:", deployer);

        vm.startBroadcast(deployerPK);

        IERC20(tokenAddr).approve(VAULT, amount);

        vm.stopBroadcast();

        console.log("------------------------------------");
        console.log("Approved vault to spend tokens");
        console.log("------------------------------------");
    }
}
