// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test} from "forge-std/Test.sol";
import {MockNFT, FixedBROVault} from "../src/FixedBROVault.sol";

contract FixedHandler is Test {
    MockNFT public nft;
    FixedBROVault public vault;

    address public user1    = address(0x1);
    address public user2    = address(0x2);
    address public attacker = address(0xBEEF);
    uint256 public expectedTotal;

    constructor(MockNFT _nft, FixedBROVault _vault) {
        nft   = _nft;
        vault = _vault;
    }

    function mintAs(uint256 seed) public {
        address actor;
        if      (seed % 3 == 0) actor = user1;
        else if (seed % 3 == 1) actor = user2;
        else                    actor = attacker;
        uint256 id = nft.mint(actor);
        vm.startPrank(actor);
        nft.approve(address(vault), id);
        vault.mint(id);
        vm.stopPrank();
        expectedTotal += vault.RATE();
    }

    function actualTotal() public view returns (uint256) {
        return vault.broBalance(user1) +
               vault.broBalance(user2) +
               vault.broBalance(attacker);
    }
}

contract BROVaultInvariantTest is StdInvariant, Test {
    MockNFT nft;
    FixedBROVault vault;
    FixedHandler handler;

    function setUp() public {
        nft     = new MockNFT();
        vault   = new FixedBROVault(address(nft));
        handler = new FixedHandler(nft, vault);
        targetContract(address(handler));
    }

    function invariant_balanceAccounting() public view {
        assertEq(handler.actualTotal(), handler.expectedTotal(),
            "fixed vault balance accounting drifted");
    }
}
