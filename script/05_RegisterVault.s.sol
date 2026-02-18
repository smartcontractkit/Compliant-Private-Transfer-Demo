// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";

interface IVault {
    function register(address token, address policyEngine) external;
}

/// @title RegisterVault
/// @notice Registers an ERC20 token and its PolicyEngine on the Vault contract.
///         Set TOKEN_ADDRESS and POLICY_ENGINE_ADDRESS env vars.
contract RegisterVault is Script {
    address constant VAULT = 0xE588a6c73933BFD66Af9b4A07d48bcE59c0D2d13;

    function run() external {
        uint256 deployerPK = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPK);

        address tokenAddr = vm.envAddress("TOKEN_ADDRESS");
        address policyEngineAddr = vm.envAddress("POLICY_ENGINE_ADDRESS");

        console.log("Registrar:", deployer);
        console.log("Token:", tokenAddr);
        console.log("PolicyEngine:", policyEngineAddr);
        console.log("Vault:", VAULT);

        vm.startBroadcast(deployerPK);

        IVault(VAULT).register(tokenAddr, policyEngineAddr);

        vm.stopBroadcast();

        console.log("------------------------------------");
        console.log("Successfully registered token and PolicyEngine on vault");
        console.log("------------------------------------");
    }
}
