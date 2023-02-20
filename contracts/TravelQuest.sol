// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TravelQuest is ERC1155, Ownable {
    string public name = "TravelQuest";

    uint256[] public supplies = [50, 50, 50];
    uint256[] public minted = [0, 0, 0];
    uint256[] public fees = [0.1 ether, 0.001 ether, 0.01 ether];
    mapping(uint256 => mapping(address => bool)) public member;

    constructor()
        ERC1155(
            "ipfs://QmWvTFLtW97TM6pWGiFdj6W71PooPEWEr8oQ2SfFqh42W5/{id}.json"
        )
    {}

    function uri(
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(_tokenId <= supplies.length - 1, "NFT does not exist");
        return
            string(
                abi.encodePacked(
                    "ipfs://QmWvTFLtW97TM6pWGiFdj6W71PooPEWEr8oQ2SfFqh42W5/",
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }

    function mint(uint256 _tokenId) public payable {
        require(
            !member[_tokenId][msg.sender],
            "You have already claimed this NFT."
        );
        require(_tokenId <= supplies.length - 1, "NFT does not exist");

        uint256 index = _tokenId;

        require(msg.value >= fees[index], "Not enough fund sent ");

        require(
            minted[index] + 1 <= supplies[index],
            "All the NFT have been minted"
        );
        _mint(msg.sender, _tokenId, 1, "");
        minted[index] += 1;
        member[_tokenId][msg.sender] = true;
    }

    function totalNftMinted(uint256 _tokenId) public view returns (uint256) {
        return minted[_tokenId];
    }

    function withDrawFunds() external onlyOwner {
        require(address(this).balance > 0);
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}
}
