// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
contract MockNFT is ERC721 {
    uint256 public nextId;
    constructor() ERC721("MockNFT","MNFT") {}
    function mint(address to) external returns (uint256) { _mint(to,++nextId); return nextId; }
}
contract VulnerableBROVault {
    MockNFT public nft;
    mapping(address=>uint256) public broBalance;
    uint256 public constant RATE = 1_000_000;
    constructor(address _nft) { nft=MockNFT(_nft); }
    function mint(uint256 tokenId) external {
        nft.safeTransferFrom(msg.sender,address(this),tokenId); // ❌ Interaction first
        broBalance[msg.sender]+=RATE;                           // ❌ Effect after
    }
    function onERC721Received(address,address,uint256,bytes calldata) external pure returns(bytes4){ return this.onERC721Received.selector; }
}
