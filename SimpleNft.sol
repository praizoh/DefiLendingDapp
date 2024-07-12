// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.2/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.2/contracts/access/Ownable.sol";

contract SimpleNFT is ERC721, Ownable {
    uint256 private tokenIdCounter;

    constructor(address initialOwner) ERC721("SimpleNFT", "SNFT") Ownable(initialOwner) {
        tokenIdCounter = 0;
    }

    function mint(address to) external {
        uint256 newTokenId = tokenIdCounter;
        _safeMint(to, newTokenId);
        tokenIdCounter++;
    }

    function ownerOf(uint256 tokenId) override public view returns (address) {
        return ERC721.ownerOf(tokenId);
    }

    function approve(address to, uint256 tokenId, address from) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId, from, true);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        // Check for approval or ownership
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _isApprovedOrOwner(address _address, uint256 tokenId) public view returns (bool) {
        // require(exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return _address==owner || getApproved(tokenId) == _address;
    }

    // Public exists function to check if a token exists
    // function exists(uint256 tokenId) public view returns (bool) {
    //     return exists(tokenId);
    // }
}
