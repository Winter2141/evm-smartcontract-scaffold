/* eslint-disable no-console */
// eslint-disable-next-line import/no-extraneous-dependencies
const hre = require("hardhat");

async function main() {
  const GoodKarmaToken = await hre.ethers.getContractFactory("GoodKarmaToken");
  const contract = await GoodKarmaToken.deploy();

  await contract.deployed();
  console.log("GoodKarmaToken deployed to:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
