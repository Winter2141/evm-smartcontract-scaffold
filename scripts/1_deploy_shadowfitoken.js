/* eslint-disable no-console */
// eslint-disable-next-line import/no-extraneous-dependencies
const hre = require("hardhat");

async function main() {
  const ShadowFi = await hre.ethers.getContractFactory("ShadowFi");
  const contract = await ShadowFi.deploy(1661147602);

  await contract.deployed();
  console.log("ShadowFi deployed to:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
