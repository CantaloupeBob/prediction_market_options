// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {MarketFactory} from "../src/MarketFactory.sol";
import {Market} from "../src/Market.sol";
import {IMarket} from "../src/interfaces/IMarket.sol";
import {console} from "forge-std/console.sol";

contract MarketScript is Script {
    // Will Jesus Christ return before 2027? Polymarket Info
    string constant SLUG = "will-jesus-christ-return-before-2027";
    string constant SYMBOL = "will-jesus-christ-return-before-2027";
    bytes32 constant CONDITION_ID = 0x0b4cc3b739e1dfe5d73274740e7308b6fb389c5af040c3a174923d928d134bee;
    uint256 constant Y_OUTCOME = 69324317355037271422943965141382095011871956039434394956830818206664869608517;
    uint256 constant N_OUTCOME = 51797157743046504218541616681751597845468055908324407922581755135522797852101;
    uint32 constant END_DATE_TIMESTAMP = 1798675200;

    // Protocol
    address constant SETTLER = 0x54db3299809370E4821bCd6C6A884ED5C32283c4;
    MarketFactory constant FACTORY = MarketFactory(0xdcb242588414BEAaD781232b3AF0EB967e4F771F);

    function deploy() external {
        vm.startBroadcast();
        Market marketImpl = new Market();
        new MarketFactory(SETTLER, address(marketImpl));
        vm.stopBroadcast();
    }

    function createMarket() external {
        IMarket.MarketConfig memory marketConfig = IMarket.MarketConfig({
            marketName: SLUG,
            marketSymbol: SLUG,
            yOutcomeId: Y_OUTCOME,
            nOutcomeId: N_OUTCOME,
            settler: SETTLER,
            marketExpiry: END_DATE_TIMESTAMP,
            upperStrikeBound: 99,
            lowerStrikeBound: 1
        });
        vm.broadcast();
        FACTORY.createMarket(marketConfig);
    }

    function viewCanCreate() external view {
        address creator = 0x42A7b811d096Cba5b3bbf346361106bDe275C8d7;
        console.log(FACTORY.canCreate(creator));
    }

    function viewOwner() external view {
        console.log(FACTORY.owner());
    }

    function viewMarkets() external view {
        console.log(FACTORY.markets(0));
    }
}
