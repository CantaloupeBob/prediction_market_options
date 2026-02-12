// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Market} from "src/Market.sol";
import {Ownable} from "@solady/auth/Ownable.sol";
import {UpgradeableBeacon} from "@solady/utils/UpgradeableBeacon.sol";
import {LibClone} from "@solady/utils/LibClone.sol";
import {IMarket} from "src/interfaces/IMarket.sol";

contract MarketFactory is UpgradeableBeacon {
    error MarketFactory__Unauthorized();

    event CreateMarket(IMarket.MarketConfig indexed marketConfig);

    address[] public markets;
    mapping(address => bool) public canCreate;

    constructor(address creator, address marketImpl) UpgradeableBeacon(creator, marketImpl) {
        canCreate[creator] = true;
    }

    function createMarket(IMarket.MarketConfig calldata config) external onlyCreator(msg.sender) returns (address) {
        address market = LibClone.deployERC1967BeaconProxy(address(this));
        Market(market).initialize(config);
        markets.push(market);
        emit CreateMarket(config);
        return market;
    }

    function setCreator(address creator, bool isEnabled) external onlyOwner {
        canCreate[creator] = isEnabled;
    }

    modifier onlyCreator(address creator) {
        require(canCreate[creator], MarketFactory__Unauthorized());
        _;
    }
}
