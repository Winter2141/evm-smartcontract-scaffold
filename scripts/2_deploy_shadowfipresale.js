/* eslint-disable no-console */
// eslint-disable-next-line import/no-extraneous-dependencies
const hre = require("hardhat");

async function main() {
  const ShadowFiPresale = await hre.ethers.getContractFactory("ShadowFiPresale");
  const contract = await ShadowFiPresale.deploy(
    "0xdCd8271a7C3Dd07866228d058Da2A50d7eCD2be3"
  );

  await contract.deployed();
  console.log("ShadowFiPresale deployed to:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
