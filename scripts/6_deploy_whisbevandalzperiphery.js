/* eslint-disable no-console */
// eslint-disable-next-line import/no-extraneous-dependencies
const hre = require("hardhat");

async function main() {
  const WhIsBeVandalzPeriphery = await hre.ethers.getContractFactory(
    "WhIsBeVandalzPeriphery"
  );
  const contract = await WhIsBeVandalzPeriphery.deploy(
    "0x620C8Af309b608367944A260D13bA60930Bd71A6",
    "0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D",
    "0x326C977E6efc84E512bB9C30f76E30c160eD06FB",
    10544,
    [
      {
        from: 1,
        to: 11,
        pieces: 11,
        tokenCount: {
          _value: 11,
        },
      },
      {
        from: 12,
        to: 222,
        pieces: 211,
        tokenCount: {
          _value: 83,
        },
      },
      {
        from: 223,
        to: 922,
        pieces: 700,
        tokenCount: {
          _value: 100,
        },
      },
      {
        from: 923,
        to: 1764,
        pieces: 842,
        tokenCount: {
          _value: 192,
        },
      },
      {
        from: 1756,
        to: 2763,
        pieces: 999,
        tokenCount: {
          _value: 737,
        },
      },
      {
        from: 2764,
        to: 4002,
        pieces: 1239,
        tokenCount: {
          _value: 719,
        },
      },
      {
        from: 4003,
        to: 6111,
        pieces: 2109,
        tokenCount: {
          _value: 738,
        },
      },
      {
        from: 6112,
        to: 11111,
        pieces: 5000,
        tokenCount: {
          _value: 753,
        },
      },
    ]
  );

  await contract.deployed();
  console.log("WhIsBeVandalzPeriphery deployed to:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
