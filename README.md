# How to use:

`git clone`
`cd polygon-edge-networks`

## To start local blockchain write this 4 commands:

```
polygon-edge server --data-dir ./test-chain-1 --chain genesis.json --grpc-address :10000 --libp2p :10001 --jsonrpc :10002 --seal
polygon-edge server --data-dir ./test-chain-2 --chain genesis.json --grpc-address :20000 --libp2p :20001 --jsonrpc :20002 --seal
polygon-edge server --data-dir ./test-chain-3 --chain genesis.json --grpc-address :30000 --libp2p :30001 --jsonrpc :30002 --seal
polygon-edge server --data-dir ./test-chain-4 --chain genesis.json --grpc-address :40000 --libp2p :40001 --jsonrpc :40002 --seal
```

### You can check http://localhost:10002/ to make sure it works

### To work with contracts:

```
cd onchain
npm i
```

### After installing all dependencies paste your private key in hardhat.config.ts

```javascript
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
```

### If it done correctly you can now deploy contracts to our blockchain

`npx hh run --network local scripts/deploy.ts`

## Now setup is done and we can start working

First of all, we have to set a provider (third party who creates orders)
`addProvider(address _provider)`

## Working with smartcontract

Than provider can create an order
`createOrder( address _seller, address _buyer, uint _energyAmount, uint _pricePerUnit, uint _deliveryDate )`

To make order valid, seller and buyer must sign this order (side 0 for buyer, 1 for seller)
` signOrder( uint _orderId, uint8 side )`

Than buyer must prepay order. To do this he needs his token be verified by the contract owner
`verifyBaseToken(address _tokenAddress)`
This \_tokenAddress is "Token 1/2 deployed to ..."
Actually it's just a simulation of real system because now we don't have the tokenomic

Than buyer can set his token with which he will pay for order
` setBaseToken(address _tokenAddress)`
Keep in mind that now we doing all manipulations in this example within 1 EOA just to make it easier to understand

Now buyer can prepay
`payOrder(uint _orderId)`
First \_orderId = 1

Now our order is being executed in the real world

To verify if it's done seller and buyer have to sign it again. Buyer can set used amount of energy to get part of money back
` fulfillOrder( uint _orderId, uint energyUsed )`

Now order is fulfilled. Also any side can decline offer on some stages if it doesn't agree with conditions.
