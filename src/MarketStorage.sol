// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {ERC721} from "@solady/tokens/ERC721.sol";
import {IMarket} from "src/interfaces/IMarket.sol";

abstract contract MarketStorage is ERC721 {
    uint256 public optionsCount;

    IMarket.Option[] public options;

    mapping(uint256 optionId => uint256 storedIdx) public optionIdx;
    mapping(address seller => IMarket.Option[]) public optionsWritten;
    mapping(address buyer => IMarket.Option[]) public optionsBought;
}
