// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test} from "forge-std/Test.sol";
import {MockNFT as VulnNFT, VulnerableBROVault} from "../src/VulnerableBROVault.sol";
import {MockNFT as FixedNFT, FixedBROVault} from "../src/FixedBROVault.sol";

contract DualHandler is Test {
    VulnNFT public vulnNft;
    FixedNFT public fixedNft;
    VulnerableBROVault public vuln;
    FixedBROVault public fixedVault;

    address public user1   = address(0x1);
    address public user2   = address(0x2);
    address public attacker = address(0xBEEF);

    uint256 public fixedExpected;

    constructor(
        VulnNFT _vulnNft,
        FixedNFT _fixedNft,
        VulnerableBROVault _vuln,
        FixedBROVault _fixedVault
    ) {
        vulnNft    = _vulnNft;
        fixedNft   = _fixedNft;
        vuln       = _vuln;
        fixedVault = _fixedVault;
    }

    function mintBoth(uint256 seed) public {
        address actor;
        if      (seed % 3 == 0) actor = user1;
        else if (seed % 3 == 1) actor = user2;
        else                    actor = attacker;

        uint256 vulnId  = vulnNft.mint(actor);
        uint256 fixedId = fixedNft.mint(actor);

        vm.startPrank(actor);
        vulnNft.approve(address(vuln),       vulnId);
        fixedNft.approve(address(fixedVault), fixedId);
        vuln.mint(vulnId);
        fixedVault.mint(fixedId);
        vm.stopPrank();

        fixedExpected += fixedVault.RATE();
    }

    function fixedTotal() public view returns (uint256) {
        return fixedVault.broBalance(user1) +
               fixedVault.broBalance(user2) +
               fixedVault.broBalance(attacker);
    }

    function vulnTotal() public view returns (uint256) {
        return vuln.broBalance(user1) +
               vuln.broBalance(user2) +
               vuln.broBalance(attacker);
    }
}

contract BROVaultDualInvariantTest is StdInvariant, Test {
    VulnNFT vulnNft;
    FixedNFT fixedNft;
    VulnerableBROVault vuln;
    FixedBROVault fixedVault;
    DualHandler handler;

    function setUp() public {
        vulnNft    = new VulnNFT();
        fixedNft   = new FixedNFT();
        vuln       = new VulnerableBROVault(address(vulnNft));
        fixedVault = new FixedBROVault(address(fixedNft));
        handler    = new DualHandler(vulnNft, fixedNft, vuln, fixedVault);
        targetContract(address(handler));
    }

    function invariant_fixedMatchesExpected() public view {
        assertEq(handler.fixedTotal(), handler.fixedExpected(),
            "fixed vault accounting drifted");
    }

    function invariant_vulnerableNotLessThanFixed() public view {
        assertGe(handler.vulnTotal(), handler.fixedTotal(),
            "vulnerable vault should not under-credit vs fixed");
    }
}
