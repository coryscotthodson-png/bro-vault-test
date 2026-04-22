// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./VulnerableBROVault.sol";

contract FixedBROVault is IERC721Receiver {
    MockNFT public nft;
    mapping(address => uint256) public broBalance;
    uint256 public constant RATE = 1_000_000;
    bool private _locked;

    constructor(address _nft) { nft = MockNFT(_nft); }

    // ✅ FIXED: CEI + reentrancy guard
    function mint(uint256 tokenId) external {
        require(!_locked, "reentrant");
        _locked = true;
        broBalance[msg.sender] += RATE;                           // ← effect first
        nft.safeTransferFrom(msg.sender, address(this), tokenId); // ← interaction last
        _locked = false;
    }

    function onERC721Received(address, address, uint256, bytes calldata)
        external pure override returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }
}
