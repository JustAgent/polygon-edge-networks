import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.17",
  networks: {
    local: {
      url: "http://localhost:10002/",
      accounts: ["0x12321321321..."], // Paste yout private key
    },
  },
};

export default config;
