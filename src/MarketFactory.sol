// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Market} from "src/Market.sol";
import {Ownable} from "@solady/auth/Ownable.sol";
import {IMarket} from "src/interfaces/IMarket.sol";

contract MarketFactory is Ownable {
    event CreateMarket(IMarket.MarketConfig indexed marketConfig);

    address[] public markets;

    constructor(address _owner) {
        _initializeOwner(_owner);
    }

    function createMarket(IMarket.MarketConfig calldata config) external onlyOwner returns (address) {
        address _market = address(new Market(config));
        markets.push(_market);
        emit CreateMarket(config);
        return _market;
    }
}
