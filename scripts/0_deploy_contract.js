/* eslint-disable no-console */
// eslint-disable-next-line import/no-extraneous-dependencies
const hre = require("hardhat");

async function main() {
  const Ambush = await hre.ethers.getContractFactory("Ambush");
  const contract = await Ambush.deploy(
    100000000000000,
    "https://a3.mypinata.cloud/ipfs/QmYV2LGeafHGsZSBHaibo5vHuq6maJ8JkvD9oh7CYmV27n/"
  );

  await contract.deployed();
  console.log("Ambush deployed to:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
