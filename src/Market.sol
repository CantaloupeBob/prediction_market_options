// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {MarketStorage} from "src/MarketStorage.sol";
import {ERC1155} from "@solady/tokens/ERC1155.sol";
import {ECDSA} from "@solady/utils/ECDSA.sol";
import {EIP712} from "@solady/utils/EIP712.sol";
import {SignatureCheckerLib} from "@solady/utils/SignatureCheckerLib.sol";
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";
import {IMarket} from "src/interfaces/IMarket.sol";
import {console} from "forge-std/console.sol";

contract Market is IMarket, MarketStorage, EIP712 {
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

    bytes32 public constant OPTION_TYPEHASH = keccak256(
        "Option(uint256 id,uint256 size,uint256 optionTokenId,uint16 strike,uint256 premium,address premiumToken,address seller,address buyer,uint32 expiry)"
    );

    address constant CTF_CONTRACT = 0x4D97DCd97eC945f40cF65F87097ACe5EA0476045;

    MarketConfig public marketConfig;

    constructor(MarketConfig memory config) {
        marketConfig = config;
    }

    function writeOption(Option memory params, bytes memory signature) external {
        _verifyWriteSig(OPTION_TYPEHASH, params, signature);
        _validateOptionParams(params);

        params.id = ++optionsCount;
        params.isPendingFill = true;
        optionsWritten[params.seller].push(params);
        options.push(params);
        optionIdx[params.id] = options.length - 1;

        ERC1155(CTF_CONTRACT).safeTransferFrom(params.seller, address(this), params.optionTokenId, params.size, hex"");

        emit OptionWritten(marketConfig, params);
    }

    function buyOption(uint256 id) external {
        // _mint(params.buyer, _optionId);
        // _verifyWriteSig(OPTION_TYPEHASH,);
    }

    function settleOption(uint256 id) external {}

    function cancelOption(uint256 id) external {}

    function _validateOptionParams(Option memory params) private view {
        require(
            params.optionTokenId == marketConfig.yOutcomeId || params.optionTokenId == marketConfig.nOutcomeId,
            Market__InvalidTokenId()
        );
        require(
            params.strike >= marketConfig.lowerStrikeBound && params.strike <= marketConfig.upperStrikeBound,
            Market__InvalidStrike()
        );
        require(params.expiry >= block.timestamp && params.expiry <= marketConfig.marketExpiry, Market__InvalidExpiry());
        require(params.size != 0, Market__InvalidSize());
        require(params.premium != 0, Market__InvalidPremium());
        require(params.id == 0, Market__InvalidOptionId());
        require(params.seller != address(0), Market__ZA());
        require(params.buyer == address(0), Market__ZA());
    }

    function getOption(uint256 id) external view returns (Option memory) {
        return options[optionIdx[id]];
    }

    function getOptions(address holder, bool isSeller) external view returns (Option[] memory) {
        return isSeller ? optionsWritten[holder] : optionsBought[holder];
    }

    function _verifyWriteSig(bytes32 typehash, Option memory params, bytes memory signature) private view {
        bytes32 structHash;
        if (typehash == OPTION_TYPEHASH) {
            structHash = keccak256(
                abi.encode(
                    OPTION_TYPEHASH,
                    params.id,
                    params.size,
                    params.optionTokenId,
                    params.strike,
                    params.premium,
                    params.premiumToken,
                    params.seller,
                    params.buyer,
                    params.expiry
                )
            );
        }
        bytes32 digest = keccak256(abi.encodePacked(hex"1901", _domainSeparator(), structHash));
        address _recovered = ECDSA.tryRecover(digest, signature);
        require(_recovered == params.seller, Market__InvalidSignature());
    }

    function getDomainSeparator() public view returns (bytes32) {
        return _domainSeparator();
    }

    function _domainNameAndVersion()
        internal
        view
        virtual
        override
        returns (string memory name_, string memory version_)
    {
        name_ = "Market";
        version_ = "1.0";
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

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory)
        public
        pure
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }
}
