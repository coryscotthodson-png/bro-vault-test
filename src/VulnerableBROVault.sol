// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract MockNFT is ERC721 {
    uint256 public nextId;
    constructor() ERC721("MockNFT", "MNFT") {}

    function mint(address to) external returns (uint256) {
        _mint(to, ++nextId);
        return nextId;
    }
}

contract VulnerableBROVault is IERC721Receiver {
    MockNFT public nft;
    mapping(address => uint256) public broBalance;
    uint256 public constant RATE = 1_000_000;
    address private _currentCaller;

    constructor(address _nft) {
        nft = MockNFT(_nft);
    }

    function mint(uint256 tokenId) external {
        _currentCaller = msg.sender;
        nft.safeTransferFrom(msg.sender, address(this), tokenId);
        broBalance[msg.sender] += RATE;
        _currentCaller = address(0);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external override returns (bytes4) {
        if (_currentCaller != address(0)) {
            // forward callback — ignore return value intentionally
            (bool _success,) = _currentCaller.call(abi.encodeWithSignature("reentryHook()"));
            _success;
        }
        return IERC721Receiver.onERC721Received.selector;
    }
}
