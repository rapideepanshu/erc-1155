const hre = require("hardhat");

async function main() {
  const Contract = await hre.ethers.getContractFactory("TravelQuest");

  const contract = await Contract.deploy();

  await contract.deployed();

  console.log("Contract deployed at :", contract.address);
}

main();

// Contract deployed at : 0xA7C9fF6263e4184B79608Dc8efD65c87A2e1B116
