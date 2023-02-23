// SPDX-License-Identifier: NONE
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract AuctionMarket {
    struct Auction {
        uint32 i_interval;
        uint256 minPrice;
        uint256 s_lastTimeStamp;
        address payable[] s_bidders;
        mapping(address => uint256) s_adressesToBid;
        mapping(address => uint256) s_addressToAmountFunded;
        uint256 temporaryHighestBid;
        address payable currentWinner;
        address nftSeller;
        bool auctionStarted;
    }

    mapping(address => mapping(uint256 => Auction)) public nftContractAuctions;

    /// Modifier to check if spender is owner of nft
    modifier isOwner(
        address nftAddress,
        uint tokenId,
        address spender
    ) {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        require(spender == owner, "Spender is not owner");
        _;
    }

    /// Modifier to check if bid is valid
    modifier isBidValid(
        address nftAddress,
        uint tokenId,
        uint bidAmount
    ) {
        require(
            bidAmount <=
                nftContractAuctions[nftAddress][tokenId].temporaryHighestBid,
            "Invalid bid send more bid amount"
        );
        _;
    }

    /// Modifier to check if auction is ended
    modifier isAuctionEnded(address nftAddress, uint tokenId) {
        require(
            block.timestamp >
                nftContractAuctions[nftAddress][tokenId].s_lastTimeStamp +
                    nftContractAuctions[nftAddress][tokenId].i_interval,
            "Auction not ended"
        );
        _;
    }

    /// Modifier to check if auction is not ended

    modifier isAuctionNotEnded(address nftAddress, uint256 tokenId) {
        require(
            block.timestamp -
                nftContractAuctions[nftAddress][tokenId].s_lastTimeStamp <
                nftContractAuctions[nftAddress][tokenId].i_interval,
            "Auction not ended"
        );

        _;
    }

    //This modifier will check whether the caller of the function is the auction winner

    modifier isAuctionWinner(
        address nftAddress,
        uint256 tokenId,
        address sender
    ) {
        require(
            sender == nftContractAuctions[nftAddress][tokenId].currentWinner,
            "Not the current winner"
        );

        _;
    }

    /// Modifier to check if sender is the nft seller
    modifier isAuctionNftSeller(
        address nftAddress,
        uint256 tokenId,
        address sender
    ) {
        require(
            sender == nftContractAuctions[nftAddress][tokenId].nftSeller,
            "Sender is not the nft seller"
        );

        _;
    }

    function InitializeAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _minPrice,
        uint32 interval
    ) public isOwner(_nftContractAddress, _tokenId, msg.sender) {
        nftContractAuctions[_nftContractAddress][_tokenId]
            .i_interval = interval;
        nftContractAuctions[_nftContractAddress][_tokenId].minPrice = _minPrice;
        nftContractAuctions[_nftContractAddress][_tokenId]
            .temporaryHighestBid = _minPrice;
        nftContractAuctions[_nftContractAddress][_tokenId].nftSeller = msg
            .sender;
        nftContractAuctions[_nftContractAddress][_tokenId]
            .s_lastTimeStamp = block.timestamp;

        IERC721(_nftContractAddress).transferFrom(
            msg.sender,
            address(this),
            _tokenId
        );
        require(
            IERC721(_nftContractAddress).ownerOf(_tokenId) == address(this),
            "failed to tranfer nft"
        );
    }

    function bid(
        address _nftContractAddress,
        uint _tokenId
    )
        external
        payable
        isBidValid(_nftContractAddress, _tokenId, msg.value)
        isAuctionEnded(_nftContractAddress, _tokenId)
    {
        if (nftContractAuctions[_nftContractAddress][_tokenId].auctionStarted) {
            nftContractAuctions[_nftContractAddress][_tokenId]
                .s_addressToAmountFunded[
                    nftContractAuctions[_nftContractAddress][_tokenId]
                        .currentWinner
                ] -= nftContractAuctions[_nftContractAddress][_tokenId]
                .temporaryHighestBid;

            (bool success, ) = nftContractAuctions[_nftContractAddress][
                _tokenId
            ].currentWinner.call{
                value: nftContractAuctions[_nftContractAddress][_tokenId]
                    .temporaryHighestBid
            }("");
            require(success, "Transfer failed");
        }
        nftContractAuctions[_nftContractAddress][_tokenId]
            .auctionStarted = true;
        nftContractAuctions[_nftContractAddress][_tokenId]
            .temporaryHighestBid = msg.value;
        nftContractAuctions[_nftContractAddress][_tokenId].s_bidders.push(
            payable(msg.sender)
        );
        nftContractAuctions[_nftContractAddress][_tokenId]
            .currentWinner = payable(msg.sender);
        nftContractAuctions[_nftContractAddress][_tokenId].s_adressesToBid[
                msg.sender
            ] = msg.value;
        nftContractAuctions[_nftContractAddress][_tokenId]
            .s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function receiveNft(
        address _nftContractAddress,
        uint256 _tokenId
    )
        public
        isAuctionNotEnded(_nftContractAddress, _tokenId)
        isAuctionWinner(_nftContractAddress, _tokenId, msg.sender)
    {
        IERC721(_nftContractAddress).transferFrom(
            address(this),
            msg.sender,
            _tokenId
        );
    }

    function withdrawNft(
        address _nftContractAddress,
        uint256 _tokenId
    )
        public
        isAuctionNotEnded(_nftContractAddress, _tokenId)
        isAuctionNftSeller(_nftContractAddress, _tokenId, msg.sender)
        isAuctionBidded(_nftContractAddress, _tokenId)
    {
        IERC721(_nftContractAddress).transferFrom(
            address(this),
            nftContractAuctions[_nftContractAddress][_tokenId].nftSeller,
            _tokenId
        );
    }
}
