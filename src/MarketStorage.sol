// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {ERC721} from "@solady/tokens/ERC721.sol";
import {EnumerableSetLib} from "@solady/utils/EnumerableSetLib.sol";
import {IMarket} from "src/interfaces/IMarket.sol";

abstract contract MarketStorage is ERC721 {
    using EnumerableSetLib for EnumerableSetLib.Uint256Set;

    uint256 public optionsCount;

    mapping(uint256 => IMarket.Option) public options;

    EnumerableSetLib.Uint256Set internal _allOptionIds;
    mapping(address => EnumerableSetLib.Uint256Set) internal _optionsWritten;
    mapping(address => EnumerableSetLib.Uint256Set) internal _optionsBought;
}