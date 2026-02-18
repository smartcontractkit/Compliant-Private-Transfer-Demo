// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {SimpleToken} from "../src/SimpleToken.sol";

/// @title DeployToken
/// @notice Deploys the SimpleToken ERC20 contract on Sepolia.
contract DeployToken is Script {
    function run() external {
        uint256 deployerPK = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPK);

        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPK);

        SimpleToken token = new SimpleToken("DemoToken", "DEMO", deployer);

        vm.stopBroadcast();

        console.log("------------------------------------");
        console.log("SimpleToken deployed at:", address(token));
        console.log("------------------------------------");
    }
}
