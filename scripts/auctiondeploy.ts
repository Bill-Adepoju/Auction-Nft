import { ethers } from "hardhat";

async function main() {
  const NFTBlindAuction = await ethers.getContractFactory("NFTBlindAuction");
  const nftBlindAuction = await NFTBlindAuction.deploy(
    "BillNFT",
    "BillFT",
    "0x3b3fbF9050e9C0753AD85Ac1344bC917338877B1",
    3600,
    3600
  );

  await nftBlindAuction.deployed();

  console.log("NFTBlindAuction deployed to:", nftBlindAuction.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
  