// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
contract FixedBROVault is ReentrancyGuard {
    ERC721 public nft;
    mapping(address=>uint256) public broBalance;
    uint256 public constant RATE = 1_000_000;
    constructor(address _nft) { nft=ERC721(_nft); }
    function mint(uint256 tokenId) external nonReentrant {
        require(nft.ownerOf(tokenId)==msg.sender,"Not owner");
        broBalance[msg.sender]+=RATE;                           // ✅ Effect first
        nft.safeTransferFrom(msg.sender,address(this),tokenId); // ✅ Interaction last
    }
    function onERC721Received(address,address,uint256,bytes calldata) external pure returns(bytes4){ return this.onERC721Received.selector; }
}
