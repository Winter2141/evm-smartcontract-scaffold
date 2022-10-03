/* eslint-disable no-console */
// eslint-disable-next-line import/no-extraneous-dependencies
const hre = require("hardhat");

async function main() {
  const ShadowFiLiquidityVault = await hre.ethers.getContractFactory(
    "ShadowFiLiquidityVault"
  );
  const contract = await ShadowFiLiquidityVault.deploy(
    "0x9ac64cc6e4415144c455bd8e4837fea55603e5c3",
    "0xa31111C45976d9D3dF22483af98bab8226e37c8C",
    1661147602
  );

  await contract.deployed();
  console.log("ShadowFiLiquidityVault deployed to:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
