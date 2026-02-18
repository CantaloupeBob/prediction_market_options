// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Market} from "src/Market.sol";
import {CreReceiver} from "src/cre/CreReceiver.sol";
import {LibClone} from "@solady/utils/LibClone.sol";
import {IMarket} from "src/interfaces/IMarket.sol";
import {Initializable} from "@solady/utils/Initializable.sol";

contract MarketFactory is CreReceiver, Initializable {
    error MarketFactory__Unauthorized();

    event CreateMarket(IMarket.MarketConfig indexed marketConfig);

    address[] public markets;
    mapping(address => bool) public canCreate;

    constructor(address _creForwarder, address _owner, address _marketImpl)
        CreReceiver(_creForwarder, _owner, _marketImpl)
    {
        _disableInitializers();
    }

    function initialize(address _owner, address _marketImpl) external initializer {
        canCreate[_owner] = true;
        // Initialize the beacon's implementation and owner in proxy storage
        assembly {
            sstore(0x911c5a209f08d5ec5e, _marketImpl)
            sstore(0x4343a0dc92ed22dbfc, _owner)
        }
    }

    function _processReport(
        bytes calldata 
    )
        internal
        override
    {}

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

    function getMarkets() external view returns (address[] memory) {
        return markets;
    }

    modifier onlyCreator(address creator) {
        require(canCreate[creator], MarketFactory__Unauthorized());
        _;
    }
}
