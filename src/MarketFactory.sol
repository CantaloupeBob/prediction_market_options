// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Market} from "src/Market.sol";
import {CreReceiver} from "src/cre/CreReceiver.sol";
import {LibClone} from "@solady/utils/LibClone.sol";
import {IMarket} from "src/interfaces/IMarket.sol";
import {IMarketFactory} from "src/interfaces/IMarketFactory.sol";
import {Initializable} from "@solady/utils/Initializable.sol";

contract MarketFactory is IMarketFactory, CreReceiver, Initializable {
    error MarketFactory__Unauthorized();
    error MarketFactory__CallFailed();
    error MarketFactory__InvalidOperation();

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
        assembly {
            sstore(0x911c5a209f08d5ec5e, _marketImpl)
            sstore(0x4343a0dc92ed22dbfc, _owner)
        }
    }

    function createMarket(IMarket.MarketConfig calldata config) external onlyCreator(msg.sender) returns (address) {
        address market = LibClone.deployERC1967BeaconProxy(address(this));
        Market(market).initialize(config);
        markets.push(market);
        emit CreateMarket(config);
        return market;
    }

    function _processReport(bytes calldata data) internal override {
        _executeOperation(data);
    }

    function _executeOperation(bytes calldata data) private {
        (address market, IMarketFactory.Op op, bytes memory execData) =
            abi.decode(data, (address, IMarketFactory.Op, bytes));
        bytes memory callData;

        if (op == IMarketFactory.Op.WRITE) {
            (IMarket.Option memory option, address sellerOwner, bytes memory signature) =
                abi.decode(execData, (IMarket.Option, address, bytes));
            callData = abi.encodeCall(IMarket.writeOption, (option, sellerOwner, signature));
        } else if (op == IMarketFactory.Op.BUY) {
            (uint256 optionId, address buyer, bytes memory signature) = abi.decode(execData, (uint256, address, bytes));
            callData = abi.encodeCall(IMarket.buyOption, (optionId, buyer, signature));
        } else if (op == IMarketFactory.Op.EXERCISE) {
            (uint256 optionId, uint16 p) = abi.decode(execData, (uint256, uint16));
            callData = abi.encodeCall(IMarket.exercise, (optionId, p));
        } else if (op == IMarketFactory.Op.CANCEL) {
            (uint256 optionId, address sellerOwner, bytes memory signature) =
                abi.decode(execData, (uint256, address, bytes));
            callData = abi.encodeCall(IMarket.cancelOption, (optionId, sellerOwner, signature));
        } else {
            revert MarketFactory__InvalidOperation();
        }

        (bool success,) = market.call(callData);
        require(success, MarketFactory__CallFailed());
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
