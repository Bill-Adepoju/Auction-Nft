import { expect } from "chai";
import { ethers } from "hardhat";

describe("NFTBlindAuction", function () {
  let NFTBlindAuction;
  let nftBlindAuction;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  beforeEach(async function () {
    NFTBlindAuction = await ethers.getContractFactory("NFTBlindAuction");
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    nftBlindAuction = await NFTBlindAuction.deploy(
      "MyNFT",
      "NFT",
      owner.address,
      3600,
      3600
    );
    await nftBlindAuction.deployed();
  });

  it("Should allow users to place bids during the bidding period", async function () {
    const blindedBid = ethers.utils.solidityKeccak256(
      ["uint256", "bool", "bytes32"],
      [1000, false, "secret"]
    );
    await expect(nftBlindAuction.connect(addr1).bid(blindedBid))
      .to.emit(nftBlindAuction, "BidPlaced")
      .withArgs(addr1.address);
    await ethers.provider.send("evm_increaseTime", [3600]);
    await ethers.provider.send("evm_mine");

    await expect(
      nftBlindAuction.connect(addr1).reveal([1000], [false], ["secret"])
    )
      .to.emit(nftBlindAuction, "BidRevealed")
      .withArgs(addr1.address, 1000);

    await ethers.provider.send("evm_increaseTime", [3600]);
    await ethers.provider.send("evm_mine");

    await expect(nftBlindAuction.connect(owner).auctionEnd(1))
      .to.emit(nftBlindAuction, "AuctionEnded")
      .withArgs(addr1.address, 1000);
  });
});

//tried ts but i almost died, so use js like that.
