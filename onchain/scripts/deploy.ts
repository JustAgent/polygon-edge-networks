import { ethers } from "hardhat";

async function main() {
  const Main = await ethers.getContractFactory("Main");
  const main = await Main.deploy();
  await main.deployed();

  // const B1 = await ethers.getContractFactory("BaseToken");
  // const b1 = await B1.deploy(main.address);
  // await b1.deployed();

  // const B2 = await ethers.getContractFactory("BaseToken");
  // const b2 = await B2.deploy(main.address);
  // await b2.deployed();

  // console.log(`Main deployed to ${main.address}`);
  // console.log(`Token 1 deployed to ${b1.address}`);
  // console.log(`Token 2 deployed to ${b2.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
