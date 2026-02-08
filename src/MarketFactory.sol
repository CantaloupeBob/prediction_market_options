// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Market} from "src/Market.sol";
import {Ownable} from "@solady/auth/Ownable.sol";
import {IMarket} from "src/interfaces/IMarket.sol";

contract MarketFacotry is Ownable {
    constructor(address _owner) {
        _initializeOwner(_owner);
    }

    function createMarket(IMarket.MarketConfig calldata _config) external {
        Market market = new Market(_config);
    }
}
