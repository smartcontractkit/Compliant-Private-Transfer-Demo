// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {PolicyEngine} from "@chainlink/policy-management/core/PolicyEngine.sol";
import {SimpleToken} from "../src/SimpleToken.sol";

interface IVault {
    function register(address token, address policyEngine) external;
    function deposit(address token, uint256 amount) external;
}

/// @title SetupAll
/// @notice All-in-one script that performs the full setup:
///         1. Deploy ERC20 token
///         2. Deploy PolicyEngine (behind proxy)
///         3. Mint 100 tokens
///         4. Approve Vault
///         5. Register token + PolicyEngine on Vault
///         6. Deposit 10 tokens into Vault
contract SetupAll is Script {
    address constant VAULT = 0xE588a6c73933BFD66Af9b4A07d48bcE59c0D2d13;

    function run() external {
        uint256 deployerPK = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPK);

        console.log("Deployer:", deployer);
        console.log("Vault:", VAULT);

        vm.startBroadcast(deployerPK);

        // 1. Deploy SimpleToken ERC20
        SimpleToken token = new SimpleToken("DemoToken", "DEMO", deployer);
        console.log("1) SimpleToken deployed at:", address(token));

        // 2. Deploy PolicyEngine (behind proxy)
        PolicyEngine policyEngineImpl = new PolicyEngine();
        bytes memory initData = abi.encodeWithSelector(
            PolicyEngine.initialize.selector,
            true,    // defaultAllow = true
            deployer
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(policyEngineImpl), initData);
        console.log("2) PolicyEngine impl deployed at:", address(policyEngineImpl));
        console.log("   PolicyEngine proxy deployed at:", address(proxy));

        // 3. Mint 100 tokens to deployer
        uint256 mintAmount = 100 ether;
        token.mint(deployer, mintAmount);
        console.log("3) Minted 100 tokens to:", deployer);

        // 4. Approve Vault to spend all tokens
        token.approve(VAULT, type(uint256).max);
        console.log("4) Approved vault to spend tokens");

        // 5. Register token + PolicyEngine on Vault
        IVault(VAULT).register(address(token), address(proxy));
        console.log("5) Registered token and PolicyEngine on vault");

        // 6. Deposit 10 tokens into Vault
        uint256 depositAmount = 10 ether;
        IVault(VAULT).deposit(address(token), depositAmount);
        console.log("6) Deposited 10 tokens into vault");

        vm.stopBroadcast();

        console.log("");
        console.log("============================================");
        console.log("  SETUP COMPLETE");
        console.log("============================================");
        console.log("SimpleToken:        ", address(token));
        console.log("PolicyEngine proxy: ", address(proxy));
        console.log("PolicyEngine impl:  ", address(policyEngineImpl));
        console.log("Vault:              ", VAULT);
        console.log("Minted:              100 tokens");
        console.log("Deposited:           10 tokens");
        console.log("============================================");
        console.log("");
        console.log("You can now use the Private Token API:");
        console.log("  - Check balance:    https://convergence2026-token-api.cldev.cloud/balances");
        console.log("  - Private transfer: https://convergence2026-token-api.cldev.cloud/private-transfer");
        console.log("  - Shielded address: https://convergence2026-token-api.cldev.cloud/shielded-address");
        console.log("  - Withdraw:         https://convergence2026-token-api.cldev.cloud/withdraw");
        console.log("  - Transactions:     https://convergence2026-token-api.cldev.cloud/transactions");
    }
}
