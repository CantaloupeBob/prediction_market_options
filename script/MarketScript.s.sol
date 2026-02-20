// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {MarketFactory} from "../src/MarketFactory.sol";
import {Market} from "../src/Market.sol";
import {IMarket} from "../src/interfaces/IMarket.sol";
import {console} from "forge-std/console.sol";
import {ERC1967Factory} from "@solady/utils/ERC1967Factory.sol";

contract MarketScript is Script {
    // Will Jesus Christ return before 2027? Polymarket Info
    string constant SLUG = "will-jesus-christ-return-before-2027";
    string constant SYMBOL = "will-jesus-christ-return-before-2027";
    bytes32 constant CONDITION_ID = 0x0b4cc3b739e1dfe5d73274740e7308b6fb389c5af040c3a174923d928d134bee;
    uint256 constant Y_OUTCOME = 69324317355037271422943965141382095011871956039434394956830818206664869608517;
    uint256 constant N_OUTCOME = 51797157743046504218541616681751597845468055908324407922581755135522797852101;
    uint32 constant END_DATE_TIMESTAMP = 1798675200;

    address constant SETTLER = 0x54db3299809370E4821bCd6C6A884ED5C32283c4;
    address constant POLYGON_CRE_FORWARDER_PROD = 0x76c9cf548b4179F8901cda1f8623568b58215E62;
    address constant POLYGON_CRE_FORWARDER_SIM = 0xF458D621885E29a5003eA9bbBA5280D54e19b1Ce;
    MarketFactory constant FACTORY = MarketFactory(0xD729A94d6366a4fEac4A6869C8b3573cEe4701A9); // Deployed protocol instance
    ERC1967Factory constant PROXY_FACTORY = ERC1967Factory(0x0000000000006396FF2a80c067f99B3d2Ab4Df24);

    function deployProtocol() external {
        vm.startBroadcast();
        address deployer = 0x42A7b811d096Cba5b3bbf346361106bDe275C8d7;
        Market marketImpl = new Market();
        MarketFactory factoryImpl = new MarketFactory(POLYGON_CRE_FORWARDER_PROD, deployer, address(marketImpl));
        address factoryProxy = PROXY_FACTORY.deploy(address(factoryImpl), deployer);
        MarketFactory(factoryProxy).initialize(deployer, address(marketImpl));

        console.log("Market Implementation:", address(marketImpl));
        console.log("Factory Implementation:", address(factoryImpl));
        console.log("Factory Proxy:", factoryProxy);
        console.log("Proxy Admin:", deployer);

        vm.stopBroadcast();
    }

    function upgradeToNewMarketImpl() external {
        console.log("Old Market Impl", FACTORY.implementation());

        vm.startBroadcast();
        Market newImpl = new Market();
        FACTORY.upgradeTo(address(newImpl));
        vm.stopBroadcast();

        console.log("New Market Impl", FACTORY.implementation());
    }

    function createMarket() external {
        IMarket.MarketConfig memory marketConfig = IMarket.MarketConfig({
            marketName: SLUG,
            marketSymbol: SLUG,
            yOutcomeId: Y_OUTCOME,
            nOutcomeId: N_OUTCOME,
            settler: SETTLER,
            marketFactory: address(0),
            marketExpiry: END_DATE_TIMESTAMP,
            upperStrikeBound: 99,
            lowerStrikeBound: 1
        });
        vm.broadcast();
        FACTORY.createMarket(marketConfig);
    }

    function setCreator() external {
        address creator = 0xddB2303e730eeFb9ADC7727Bd256Eb7F722cE07b;
        vm.broadcast();
        FACTORY.setCreator(creator, true);
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
