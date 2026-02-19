// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

interface IMarketFactory {
    enum Op {
        WRITE,
        BUY,
        EXERCISE,
        CANCEL
    }
}
