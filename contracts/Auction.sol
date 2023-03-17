// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTBlindAuction is ERC721, Ownable {
    struct Bid {
        bytes32 blindedBid;
        uint deposit;
    }

    mapping(address => Bid[]) public bids;

    address public beneficiary;
    uint public biddingEnd;
    uint public revealEnd;
    bool public ended;

    mapping(address => uint) pendingReturns;

    event AuctionEnded(address winner, uint highestBid);

    address public highestBidder;
    uint public highestBid;

    constructor(
        string memory name,
        string memory symbol,
        address _beneficiary,
        uint _biddingTime,
        uint _revealTime
    ) ERC721(name, symbol) {
        beneficiary = _beneficiary;
        biddingEnd = block.timestamp + _biddingTime;
        revealEnd = biddingEnd + _revealTime;
    }

    function bid(bytes32 _blindedBid) public payable {
        require(block.timestamp <= biddingEnd, "Bidding period has ended.");

        bids[msg.sender].push(
            Bid({blindedBid: _blindedBid, deposit: msg.value})
        );
    }

    function reveal(
        uint[] memory _values,
        bool[] memory _fake,
        bytes32[] memory _secret
    ) public {
        require(
            block.timestamp > biddingEnd,
            "Bidding period has not ended yet."
        );
        require(block.timestamp < revealEnd, "Reveal period has ended.");

        uint length = bids[msg.sender].length;
        require(_values.length == length);
        require(_fake.length == length);
        require(_secret.length == length);

        uint refund;
        for (uint i = 0; i < length; i++) {
            Bid storage bidToCheck = bids[msg.sender][i];
            (uint value, bool fake, bytes32 secret) = (
                _values[i],
                _fake[i],
                _secret[i]
            );
            if (
                bidToCheck.blindedBid !=
                keccak256(abi.encodePacked(value, fake, secret))
            ) {
                continue;
            }
            refund += bidToCheck.deposit;
            if (!fake && bidToCheck.deposit >= value) {
                if (placeBid(msg.sender, value)) refund -= value;
            }
            bidToCheck.blindedBid = bytes32(0);
        }
        payable(msg.sender).transfer(refund);
    }

    function withdraw() public {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;

            payable(msg.sender).transfer(amount);
        }
    }

    function auctionEnd(uint256 tokenId) public {
        require(block.timestamp >= revealEnd, "Reveal period has not ended yet.");
        require(!ended, "Auction has already ended.");

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        _safeTransfer(owner(), highestBidder, tokenId, "");
    }

    function placeBid(
        address bidder,
        uint value
    ) internal returns (bool success) {
        if (value <= highestBid) {
            return false;
        }
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBid = value;
        highestBidder = bidder;
        return true;
    }
}
