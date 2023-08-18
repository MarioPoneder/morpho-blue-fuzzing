// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../BaseTest.sol";

contract IntegrationCreateMarketTest is BaseTest {
    using MorphoLib for Morpho;
    using MarketLib for Info;
    using MathLib for uint256;

    function testCreateMarketWithNotEnabledIrmAndNotEnabledLltv(Info memory marketFuzz) public {
        vm.assume(marketFuzz.irm != address(irm) && marketFuzz.lltv != LLTV);

        vm.prank(OWNER);
        vm.expectRevert(bytes(ErrorsLib.IRM_NOT_ENABLED));
        morpho.createMarket(marketFuzz);
    }

    function testCreateMarketWithNotEnabledIrmAndEnabledLltv(Info memory marketFuzz) public {
        vm.assume(marketFuzz.irm != address(irm));
        marketFuzz.lltv = _boundValidLltv(marketFuzz.lltv);

        vm.startPrank(OWNER);
        if (marketFuzz.lltv != LLTV) morpho.enableLltv(marketFuzz.lltv);

        vm.expectRevert(bytes(ErrorsLib.IRM_NOT_ENABLED));
        morpho.createMarket(marketFuzz);
        vm.stopPrank();
    }

    function testCreateMarketWithEnabledIrmAndNotEnabledLltv(Info memory marketFuzz) public {
        vm.assume(marketFuzz.lltv != LLTV);

        vm.startPrank(OWNER);
        if (marketFuzz.irm != market.irm) morpho.enableIrm(marketFuzz.irm);

        vm.expectRevert(bytes(ErrorsLib.LLTV_NOT_ENABLED));
        morpho.createMarket(marketFuzz);
        vm.stopPrank();
    }

    function testCreateMarketWithEnabledIrmAndLltv(Info memory marketFuzz) public {
        marketFuzz.lltv = _boundValidLltv(marketFuzz.lltv);
        Id marketFuzzId = marketFuzz.id();

        vm.startPrank(OWNER);
        if (marketFuzz.irm != market.irm) morpho.enableIrm(marketFuzz.irm);
        if (marketFuzz.lltv != LLTV) morpho.enableLltv(marketFuzz.lltv);

        vm.expectEmit(true, true, true, true, address(morpho));
        emit EventsLib.CreateMarket(marketFuzz.id(), marketFuzz);
        morpho.createMarket(marketFuzz);
        vm.stopPrank();

        assertEq(morpho.lastUpdate(marketFuzzId), block.timestamp, "lastUpdate != block.timestamp");
        assertEq(morpho.totalSupply(marketFuzzId), 0, "totalSupply != 0");
        assertEq(morpho.totalSupplyShares(marketFuzzId), 0, "totalSupplyShares != 0");
        assertEq(morpho.totalBorrow(marketFuzzId), 0, "totalBorrow != 0");
        assertEq(morpho.totalBorrowShares(marketFuzzId), 0, "totalBorrowShares != 0");
        assertEq(morpho.fee(marketFuzzId), 0, "fee != 0");
    }

    function testCreateMarketAlreadyCreated(Info memory marketFuzz) public {
        marketFuzz.lltv = _boundValidLltv(marketFuzz.lltv);

        vm.startPrank(OWNER);
        if (marketFuzz.irm != market.irm) morpho.enableIrm(marketFuzz.irm);
        if (marketFuzz.lltv != LLTV) morpho.enableLltv(marketFuzz.lltv);
        morpho.createMarket(marketFuzz);

        vm.expectRevert(bytes(ErrorsLib.MARKET_ALREADY_CREATED));
        morpho.createMarket(marketFuzz);
        vm.stopPrank();
    }
}
