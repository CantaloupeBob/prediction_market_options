// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

interface IMarket {
    struct MarketConfig {
        string marketName;
        string marketSymbol;
        uint256 yOutcomeId;
        uint256 nOutcomeId;
        address settler;
        address marketFactory;
        uint32 marketExpiry;
        uint16 upperStrikeBound;
        uint16 lowerStrikeBound;
    }

    struct Option {
        uint256 id;
        uint256 size;
        uint256 optionTokenId;
        uint16 strike;
        uint256 premium;
        address premiumToken;
        address seller;
        address buyer;
        uint32 expiry;
        bool isCall;
        bool isPendingFill;
        bool isSettled;
    }

    function writeOption(Option memory params, address sellerOwner, bytes memory signature) external returns (uint256);
    function buyOption(uint256 optionId, address buyer, bytes memory signature) external returns (uint256);
    function exercise(uint256 optionId, uint16 p) external returns (uint256);
    function cancelOption(uint256 optionId, address sellerOwner, bytes memory signature) external;
}
