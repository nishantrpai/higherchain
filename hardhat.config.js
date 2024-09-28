require('@nomicfoundation/hardhat-toolbox');
require('dotenv').config();

const config = {
  solidity: {
    version: '0.8.24',
  },
  networks: {
    // for mainnet
    'base-mainnet': {
      url: 'https://mainnet.base.org',
      accounts: [process.env.WALLET_KEY],
      gasPrice: 1000000000,
    },
    // for testnet
    'base-sepolia': {
      url: 'https://sepolia.base.org',
      accounts: [process.env.WALLET_KEY],
      gasPrice: 1000000000,
    },
    // for local dev environment
    'base-local': {
      url: 'http://localhost:8545',
      accounts: [process.env.WALLET_KEY],
      gasPrice: 1000000000,
    },
    // for hardhat network
    'hardhat': {
      chainId: 31337,
    },
  },
  defaultNetwork: 'hardhat',
  etherscan: {
    apiKey: {
     "base-sepolia": 'PLACEHOLDER_STRING'
    },
    customChains: [
      {
        network: "base-sepolia",
        chainId: 84532,
        urls: {
         apiURL: "https://base-sepolia.blockscout.com/api",
         browserURL: "https://base-sepolia.blockscout.com"
        }
      }
    ]
  },
  sourcify: {
    enabled: false,
  }
};

module.exports = config;