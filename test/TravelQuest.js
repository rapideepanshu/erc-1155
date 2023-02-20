const { expect } = require("chai");

describe("TravelQuest", function () {
  let TravelQuest;
  let travelQuest;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async function () {
    TravelQuest = await ethers.getContractFactory("TravelQuest");
    [owner, addr1, addr2] = await ethers.getSigners();
    travelQuest = await TravelQuest.deploy();
    await travelQuest.deployed();
  });

  it("should deploy TravelQuest contract", async function () {
    expect(travelQuest.address).to.exist;
  });

  it("should have the correct name", async function () {
    expect(await travelQuest.name()).to.equal("TravelQuest");
  });

  it("should mint an NFT when the user pays the correct fee", async function () {
    const tokenId = 0;
    const fee = ethers.utils.parseEther("0.1");

    await travelQuest.connect(addr1).mint(tokenId, { value: fee });

    expect(await travelQuest.totalNftMinted(tokenId)).to.equal(1);
    expect(await travelQuest.member(tokenId, addr1.address)).to.equal(true);
  });

  it("should not mint an NFT if the user has already claimed it", async function () {
    const tokenId = 0;
    const fee = ethers.utils.parseEther("0.1");

    await travelQuest.connect(addr1).mint(tokenId, { value: fee });

    await expect(
      travelQuest.connect(addr1).mint(tokenId, { value: fee })
    ).to.be.revertedWith("You have already claimed this NFT.");
  });

  it("should not mint an NFT if the fee sent is not enough", async function () {
    const tokenId = 0;
    const fee = ethers.utils.parseEther("0.05");

    await expect(
      travelQuest.connect(addr1).mint(tokenId, { value: fee })
    ).to.be.revertedWith("Not enough fund sent ");
  });

  it("should not mint an NFT only one time", async function () {
    const tokenId = 0;
    const fee = ethers.utils.parseEther("0.1");

    await travelQuest.connect(addr1).mint(tokenId, { value: fee });

    await expect(
      travelQuest.connect(addr1).mint(tokenId, { value: fee })
    ).to.be.revertedWith("You have already claimed this NFT.");
  });

  it("should withdraw funds only by the contract owner", async function () {
    const tokenId = 0;
    const fee = ethers.utils.parseEther("0.1");

    await travelQuest.connect(addr1).mint(tokenId, { value: fee });

    await expect(travelQuest.connect(addr1).withDrawFunds()).to.be.revertedWith(
      "Ownable: caller is not the owner"
    );

    const ownerBalanceBefore = await ethers.provider.getBalance(owner.address);

    await travelQuest.connect(owner).withDrawFunds();

    const ownerBalanceAfter = await ethers.provider.getBalance(owner.address);

    console.log("before", ownerBalanceBefore);
    console.log("after", ownerBalanceAfter);
  });
});
