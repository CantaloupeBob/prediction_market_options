// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {MarketFactory} from "../src/MarketFactory.sol";
import {Market} from "../src/Market.sol";

contract MarketScript is Script {
    MarketFactory public factory;

    function run() public {
        vm.startBroadcast();
        Market marketImpl = new Market();
        factory = new MarketFactory(msg.sender, address(marketImpl));
        vm.stopBroadcast();
    }
}
