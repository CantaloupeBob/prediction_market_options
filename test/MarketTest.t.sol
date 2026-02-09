// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {MarketFactory} from "src/MarketFactory.sol";
import {Market} from "src/Market.sol";
import {ERC1155} from "@solady/tokens/ERC1155.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {IMarket} from "src/interfaces/IMarket.sol";
import {IConditionalTokens} from "src/interfaces/IConditionalTokens.sol";
import {console2} from "forge-std/console2.sol";

contract MarketTest is Test {
    IConditionalTokens constant CONDITIONAL_TOKENS = IConditionalTokens(0x4D97DCd97eC945f40cF65F87097ACe5EA0476045);
    ERC20 constant USDC = ERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    uint256 constant TEN_USDC = 10e6;
    address constant MAIN_EXCHANGE = 0x4bFb41d5B3570DeFd03C39a9A4D8dE6Bd8B8982E;
    address constant NEG_RISK_MARKET = 0xC5d563A36AE78145C45a50134d48A1215220f80a;
    address constant NEG_RISK_ADAPTER = 0xd91E80cF2E7be2e162c6513ceD06f1dD0dA35296;

    // Will Jesus Christ return before 2027? Polymarket Info
    string constant SLUG = "slug=will-jesus-christ-return-before-2027";
    string constant SYMBOL = "slug=will-jesus-christ-return-before-2027";
    bytes32 constant CONDITION_ID = 0x0b4cc3b739e1dfe5d73274740e7308b6fb389c5af040c3a174923d928d134bee;
    uint256 constant Y_OUTCOME = 69324317355037271422943965141382095011871956039434394956830818206664869608517;
    uint256 constant N_OUTCOME = 51797157743046504218541616681751597845468055908324407922581755135522797852101;
    uint32 constant END_DATE_TIMESTAMP = 1798675200;

    MarketFactory factory;

    Vm.Wallet admin;
    Vm.Wallet executor;
    Vm.Wallet seller;
    Vm.Wallet buyer;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("polygon"));

        admin = vm.createWallet("admin");
        executor = vm.createWallet("executor");
        seller = vm.createWallet("seller");
        buyer = vm.createWallet("buyer");

        factory = new MarketFactory(admin.addr);
    }

    function test_createOptionMarket() external {
        IMarket.MarketConfig memory marketConfig = IMarket.MarketConfig({
            marketName: SLUG,
            marketSymbol: SLUG,
            yOutcomeId: Y_OUTCOME,
            nOutcomeId: N_OUTCOME,
            marketExpiry: END_DATE_TIMESTAMP,
            upperStrikeBound: 99,
            lowerStrikeBound: 1
        });

        vm.expectEmit();
        emit MarketFactory.CreateMarket(marketConfig);
        vm.prank(admin.addr);
        Market market = Market(factory.createMarket(marketConfig));

        (string memory mn, string memory ms, uint256 yId, uint256 nId, uint32 me, uint16 usb, uint16 lsb) =
            market.marketConfig();

        assertEq(mn, marketConfig.marketName);
        assertEq(ms, marketConfig.marketSymbol);
        assertEq(yId, marketConfig.yOutcomeId);
        assertEq(nId, marketConfig.nOutcomeId);
        assertEq(me, marketConfig.marketExpiry);
        assertEq(usb, marketConfig.upperStrikeBound);
        assertEq(lsb, marketConfig.lowerStrikeBound);
        assertEq(factory.markets(0), address(market));
        assertEq(market.name(), SLUG);
        assertEq(market.symbol(), SLUG);
    }

    function test_writeOption() external {
        Market market = _createDefaultOptionMarket();
        (,,,, uint32 marketExpiry,,) = market.marketConfig();
        uint32 optionExpiry = uint32(block.timestamp) + uint32(((marketExpiry - block.timestamp) / 2));
        IMarket.Option memory optionParams = IMarket.Option({
            id: 0,
            size: 5000,
            optionTokenId: Y_OUTCOME,
            strike: 50,
            premium: 10e6,
            premiumToken: address(USDC),
            seller: seller.addr,
            buyer: address(0),
            expiry: optionExpiry,
            isPendingFill: false,
            isExpired: false
        });
        bytes memory sellerSignature = _signOptionData(seller, market, optionParams);

        _createShares({recipient: seller, conditionId: CONDITION_ID, amount: 5000});
        _approveShares({owner: seller, operator: address(market), approved: true});

        assertEq(CONDITIONAL_TOKENS.balanceOf(seller.addr, Y_OUTCOME), 5000);
        assertEq(CONDITIONAL_TOKENS.balanceOf(address(market), Y_OUTCOME), 0);
        assertEq(market.optionsCount(), 0);

        vm.prank(executor.addr);
        market.writeOption(optionParams, sellerSignature);

        assertEq(CONDITIONAL_TOKENS.balanceOf(seller.addr, Y_OUTCOME), 0);
        assertEq(CONDITIONAL_TOKENS.balanceOf(address(market), Y_OUTCOME), 5000);

        assertEq(market.optionsCount(), 1);

        IMarket.Option memory option = market.getOption(1);
        assertEq(option.id, 1);
        assertEq(option.size, 5000);
        assertEq(option.optionTokenId, Y_OUTCOME);
        assertEq(option.strike, 50);
        assertEq(option.premium, 10e6);
        assertEq(option.premiumToken, address(USDC));
        assertEq(option.seller, seller.addr);
        assertEq(option.buyer, address(0));
        assertEq(option.expiry, optionExpiry);
        assertEq(option.isPendingFill, true);
        assertEq(option.isExpired, false);

        IMarket.Option[] memory sellerOptions = market.getOptions(seller.addr, true);
        assertEq(sellerOptions.length, 1);
        assertEq(sellerOptions[0].id, 1);
        assertEq(sellerOptions[0].size, 5000);
        assertEq(sellerOptions[0].seller, seller.addr);

        assertEq(market.optionIdx(1), 0);
    }

    function _createDefaultOptionMarket() private returns (Market market_) {
        IMarket.MarketConfig memory marketConfig = IMarket.MarketConfig({
            marketName: SLUG,
            marketSymbol: SLUG,
            yOutcomeId: Y_OUTCOME,
            nOutcomeId: N_OUTCOME,
            marketExpiry: END_DATE_TIMESTAMP,
            upperStrikeBound: 99,
            lowerStrikeBound: 1
        });
        vm.expectEmit();
        emit MarketFactory.CreateMarket(marketConfig);
        vm.prank(admin.addr);
        market_ = Market(factory.createMarket(marketConfig));
    }

    function _approveShares(Vm.Wallet memory owner, address operator, bool approved) private {
        vm.prank(owner.addr);
        CONDITIONAL_TOKENS.setApprovalForAll(operator, approved);
    }

    function _createShares(Vm.Wallet memory recipient, bytes32 conditionId, uint256 amount) private {
        uint256[] memory partition = new uint256[](2);
        partition[0] = 1;
        partition[1] = 2;
        deal(address(USDC), recipient.addr, amount);
        vm.startPrank(recipient.addr);
        USDC.approve(address(CONDITIONAL_TOKENS), type(uint256).max);
        CONDITIONAL_TOKENS.splitPosition(address(USDC), hex"", conditionId, partition, amount);
        vm.stopPrank();
        assertEq(CONDITIONAL_TOKENS.balanceOf(recipient.addr, Y_OUTCOME), amount);
        assertEq(CONDITIONAL_TOKENS.balanceOf(recipient.addr, N_OUTCOME), amount);
    }

    function _signOptionData(Vm.Wallet memory signer, Market market, IMarket.Option memory params)
        private
        view
        returns (bytes memory)
    {
        bytes32 domainSeparator = market.getDomainSeparator();
        bytes32 structHash = keccak256(
            abi.encode(
                market.OPTION_TYPEHASH(),
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
        bytes32 digest = keccak256(abi.encodePacked(hex"1901", domainSeparator, structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signer.privateKey, digest);
        return abi.encodePacked(r, s, v);
    }
}
