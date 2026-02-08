// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {MarketStorage} from "src/MarketStorage.sol";
import {ERC1155} from "@solady/tokens/ERC1155.sol";
import {ECDSA} from "@solady/utils/ECDSA.sol";
import {SignatureCheckerLib} from "@solady/utils/SignatureCheckerLib.sol";
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";
import {IMarket} from "src/interfaces/IMarket.sol";

contract Market is IMarket, MarketStorage {
    using SafeTransferLib for address;

    error Market__InvalidSize();
    error Market__InvalidPremium();
    error Market__InvalidExpiry();
    error Market__InvalidStrike();
    error Market__InvalidTokenId();
    error Market__InvalidOptionId();
    error Market__InvalidSignature();
    error Market__ZA();

    event OptionWritten(MarketConfig indexed marketConfig, Option indexed option);

    string constant WRITE_OPTION_TYPEHASH =
        "Option(uint256 id,uint256 size,uint256 optionTokenId,uint16 strike, uint256 premium,address premiumToken,address seller,addres buyer,uint32 expiry,bool isExpired)";
    address constant CTF_CONTRACT = 0x4D97DCd97eC945f40cF65F87097ACe5EA0476045;

    MarketConfig public marketConfig;

    constructor(MarketConfig memory config) {
        marketConfig = config;
    }

    function writeOption(Option memory params) external {
        _verifyWriteSig(params);
        _validateOptionParams(params);

        uint256 _optionId = optionsCount++;
        params.id = _optionId;
        optionsWritten[params.seller].push(params);
        options.push(params);

        params.premiumToken.safeTransferFrom(params.buyer, params.seller, params.premium);
        ERC1155(CTF_CONTRACT).safeTransferFrom(params.seller, address(this), params.optionTokenId, params.size, hex"");
        _mint(params.buyer, _optionId);

        emit OptionWritten(marketConfig, params);
    }

    function buyOption(uint256 optionId) external {}

    function settleOption(uint256 optionId) external {}

    function cancelOption(uint256 id) external {}

    function _validateOptionParams(Option memory params) private view {
        require(params.expiry >= block.timestamp && params.expiry < marketConfig.marketExpiry, Market__InvalidExpiry());
        require(
            params.strike >= marketConfig.lowerStrikeBound && params.strike <= marketConfig.upperStrikeBound,
            Market__InvalidStrike()
        );
        require(params.size != 0, Market__InvalidSize());
        require(params.optionTokenId != 0, Market__InvalidTokenId());
        require(params.premium != 0, Market__InvalidPremium());
        require(params.id == 0, Market__InvalidOptionId());
        require(params.seller == address(0), Market__ZA());
        require(params.buyer != address(0), Market__ZA());
    }

    function _verifyWriteSig(Option memory params) private view {
        bytes32 _digest = keccak256(
            abi.encode(
                WRITE_OPTION_TYPEHASH,
                params.id,
                params.size,
                params.optionTokenId,
                params.strike,
                params.premium,
                params.premiumToken,
                params.seller,
                params.buyer,
                params.expiry,
                params.isExpired
            )
        );
        address _recovered = ECDSA.tryRecover(_digest, params.sellerSignature);
        require(_recovered == params.seller, Market__InvalidSignature());
    }

    function name() public view virtual override returns (string memory) {
        return marketConfig.marketName;
    }

    function symbol() public view virtual override returns (string memory) {
        return marketConfig.marketSymbol;
    }

    function tokenURI(uint256) public view virtual override returns (string memory) {
        return ""; // TODO - Do we care abt this?
    }
}
