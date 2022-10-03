/* eslint-disable no-nested-ternary */
/* eslint-disable no-console */
/* eslint-disable import/no-extraneous-dependencies */
require("dotenv").config();

require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-web3");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  // eslint-disable-next-line no-restricted-syntax
  for (const account of accounts) {
    console.log(account.address);
  }
});

const network = process.env.HARDHAT_NETWORK
  ? process.env.HARDHAT_NETWORK
  : "goerli";
const API_KEY =
  network === "fujiavax"
    ? process.env.AVAXSCAN_API_KEY
    : network === "ropsten"
    ? process.env.ETHERSCAN_API_KEY
    : network === "bsctestnet" || network === "bscmainnet"
    ? process.env.BSCSCAN_API_KEY
    : network === "matic" || network === "mumbai"
    ? process.env.POLYGONSCAN_API_KEY
    : process.env.ETHERSCAN_API_KEY;

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.10",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  paths: {
    artifacts: "./artifacts",
  },
  networks: {
    hardhat: {
      chainId: 1337,
      initialBaseFeePerGas: 0, // workaround from https://github.com/sc-forks/solidity-coverage/issues/652#issuecomment-896330136 . Remove when that issue is closed.
    },
    ropsten: {
      chainId: 3,
      url: process.env.ROPSTEN_PROVIDER_URL || "https://ropsten.infura.io/v3/",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    rinkeby: {
      chainId: 4,
      url: process.env.RINKEBY_PROVIDER_URL || "https://rinkeby.infura.io/v3/",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    goerli: {
      chainId: 5,
      url: process.env.GOERLI_PROVIDER_URL || "https://goerli.infura.io/v3/",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    matic: {
      chainId: 137,
      url: process.env.MATIC_PROVIDER_URL || "https://polygon-rpc.com",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    mumbai: {
      chainId: 80001,
      url:
        process.env.MUMBAI_PROVIDER_URL || "https://rpc-mumbai.maticvigil.com",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    bscmainnet: {
      chainId: 56,
      url:
        process.env.BSCMAIN_PROVIDER_URL ||
        "https://bsc-dataseed4.binance.org/",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    bsctestnet: {
      chainId: 97,
      url:
        process.env.BSCTEST_PROVIDER_URL ||
        "https://data-seed-prebsc-1-s3.binance.org:8545/",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    avax: {
      chainId: 43114,
      url:
        process.env.AVAXSCAN_PROVIDER_URL ||
        "https://api.avax.network/ext/bc/C/rpc",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    fujiavax: {
      chainId: 43113,
      url:
        process.env.FUJIAVAXSCAN_PROVIDER_URL ||
        "https://api.avax-test.network/ext/bc/C/rpc",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: API_KEY,
  },
};
