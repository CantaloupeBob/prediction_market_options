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

    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner, address _marketImpl, address _creForwarder) external initializer {
        canCreate[_owner] = true;
        _initializeUpgradeableBeacon(_owner, _marketImpl);
        _initializeCreReceiver(_creForwarder);
    }

    function createMarket(IMarket.MarketConfig calldata config) external onlyCreator returns (address) {
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

        (bool success, bytes memory returnData) = market.call(callData);
        /// @dev Bubble up the revert
        if (!success) {
            assembly {
                revert(add(returnData, 0x20), mload(returnData))
            }
        }
    }

    function setCreator(address creator, bool isEnabled) external onlyOwner {
        canCreate[creator] = isEnabled;
    }

    function getMarkets() external view returns (address[] memory) {
        return markets;
    }

    modifier onlyCreator() {
        require(canCreate[msg.sender], MarketFactory__Unauthorized());
        _;
    }
}
