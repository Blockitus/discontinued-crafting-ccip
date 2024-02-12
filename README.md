# CRAFTING-CCIP
## Masterclass #M1
## Author 

### Pedro Machado

<p align="center">
<img src="./me.jpg" width="400" alt="puppy-raffle">
<br/>


## Disclaimer

This summary is provided for learning and teaching purposes only. It is intended to offer insights into the Chainlink-Cross Contract Interoperability Protocol (CCIP) and its functionalities. The information presented here is not intended as financial or investment advice. Readers are encouraged to conduct their own research and seek professional advice before making any investment decisions. The content should not be construed as a recommendation or endorsement of any specific investment assets. We do not assume responsibility for any actions taken based on the information provided in this summary.

## Introduction

This is a report for a set of masterclasses with the objective of describing CCIP (Chainlink-Cross Contract Interoperability Protocol). We are following the [Chainlink CCIP](https://andrej-rakic.gitbook.io/chainlink-ccip/getting-started/chainlink-ccip) masterclass to learn and demonstrate how this protocol works.

## Motivation

The blockchain industry has evolved to a new level where there exists the necessity to connect isolated networks to share data between them. The future of Web3 and Blockchain aims to be more cooperative and less competitive for DApps that accept data for every blockchain, still being secure and efficient.

## Basic Architecture of CCIP

<p align="center">
<img src="./basic-architecture.png" width="400" alt="puppy-raffle">
<br/>


### What is Chainlink Cross Chain Interoperability Protocol?

The Chainlink Cross-Chain Interoperability Protocol (CCIP) provides a single simple interface through which dApps and Web3 entrepreneurs can securely meet all their cross-chain needs, including token transfers and arbitrary messaging.

How you can watch this?: Imagine an ocean with a lot of islands (blockchains), each one with its government, culture, society, and economy. However, they are isolated, meaning they lack direct communication channels to transport information.

Chainlink Cross Chain Interoperability Protocol unlocks the feature for isolated blockchains to share data (i.e: tokens (ERC20, ERC721), or any message) between them.

## Sending a message from Avalanche Fuji network to Sepolia network

Here is a basic example of sending data between two isolated blockchains.

### Requirements

1. Blockchain skills
2. Solidity skills
3. Basic Foundry Skills
4. Git skills
5. Your favorite IDE (VS Code)
6. The latest version of Foundry installed
7. The latest version of Nodejs installed
8. Metamask on your web browser

 
### Quickstart

```bash
git clone https://github.com/Blockitus/crafting-ccip.git
cd crafting-ccip
npm install
forge install
```

### Setup enviroment variables

Create a `.env` file into your project and paste the code above:

```bash
PRIVATE_KEY=
ETHEREUM_SEPOLIA_RPC_URL=""
AVALANCHE_FUJI_RPC_URL=""
```
Place your API_KEYS and your PRIVATE_KEY into the environment variables.

**Note: Ensure that you are not using a wallet with real funds and put the `.env` file into the `.gitignore`.**

Run 

```bash
source .env
```
**Note: You have configured your `foundry.toml` file, so you don't have to make any changes there.** 

### Land

- **Source Chain: Avalance Fuji**

- **Destination Chain: Ethereum Sepolia**

### Set of Smart Contracts

Source Chain side

**CCIPSender_Unsafe.sol**

This contract should be deployed on the source chain. The `CCIPSender_Unsafe::send(receiver, someText, destinationChainSelector)` function submits a message with text that you want to be sent to the destination blockchain. 

**Note: You have to previously install `@chainlink package`**

```bash
npm i @chainlink/contracts-ccip --save-dev
```


```javascript
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {LinkTokenInterface} from "./LinkTokenInterface.sol";

contract CCIPSender_Unsafe {
    address router;
    address link;

    constructor(address _router, address _link) {
        router = _router;
        link = _link;
        LinkTokenInterface(link).approve(router, type(uint256).max);
    }

    function send(address receiver, string memory someText, uint64 destinationChainSelector) external {
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encode(someText),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: link
        });

        IRouterClient(router).ccipSend(destinationChainSelector, message);
    }

}

```
Compile

Check  if the smart contract build fine. 

```bash
forge build
```

If it is not, correct bugs and try to compile again.

**CCIPReceiver_Unsafe.sol**

Destination Chain side

This smart contract should be deployed on the destination chain. This contract tracks the latest state variables like `latestSender` and `latestMessage`.

**Note: Please don't forget that you have previously installed the `@chainlink-ccip` package.**

```javascript
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

contract CCIPReceiver_Unsafe is CCIPReceiver {

    address public latestSender;
    string public latestMessage;

    constructor(address router) CCIPReceiver(router) {}

      function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        latestSender = abi.decode(message.sender, (address));
        latestMessage = abi.decode(message.data, (string));
      }
}

```

Compile

Check if the smart contract build fine. 

```bash
forge build
```

If it is not, correct bugs and try to compile again.


### Deploying Smart Contracts

To deploy the smart contracts, you need faucet tokens in your wallet

1. [Getting Sepolia ETH faucet native token](https://sepoliafaucet.com/) 
2. [Getting Avalanche Fuji AVAX faucet native token](https://faucets.chain.link/fuji) 

Deploy `CCIPSender_Unsafe.sol`

```bash
forge create --rpc-url avalancheFuji --private-key=$PRIVATE_KEY src/CCIPSender_Unsafe.sol:CCIPSender_Unsafe --constructor-args 0x554472a2720E5E7D5D3C817529aBA05EEd5F82D8 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846
```

Deploy `CCIPReceiver_Unsafe.sol`

```bash
forge create --rpc-url ethereumSepolia --private-key=$PRIVATE_KEY src/CCIPReceiver_Unsafe.sol:CCIPReceiver_Unsafe --constructor-args 0xD0daae2231E9CB96b94C8512223533293C3693Bf
```
Yeahh!!! We have deployed our smart contracts in the correspondent isolated blockchains. 
Now we can send a message from the source chain `Avalanche Fuji` to the destination chain `Ethereum Sepolia`.

### Sending the message

Let's got to send the message: `"THANK YOU BLOCKITUS"` from the Fuji to Sepolia. 

Prepare:

- The address of the address of the CCIPReceiver_Unsafe.sol smart contract you previously deployed to Ethereum Sepolia, as the receiver parameter;
- The Text Message you want to send, for example "THANK YOU BLOCKITUS", as the someText parameter;
- 16015286601757825753, which is the CCIP Chain Selector for the Ethereum Sepolia network, as the destinationChainSelector parameter.

Run

```bash 
cast send <CCIP_SENDER_UNSAFE_ADDRESS> --rpc-url avalancheFuji --private-key=$PRIVATE_KEY "send(address,string,uint64)" <CCIP_RECEIVER_UNSAFE_ADDRESS> "THANK YOU BLOCKITUS" 16015286601757825753
```

You can now monitor live the status of your CCIP Cross-Chain Message via [CCIP Explorer](https://ccip.chain.link/). Just paste the transaction hash into the search bar and open the message details.

## CONGRATULATIONS :) 

You have now the basic comprehension about CCIP.

## My own tech summary 

Certainly! Here is the corrected text:

If you don't want to walk through the process of building the system (NOT RECOMMENDED, BECAUSE YOU HAVE TO LIVE YOUR OWN EXPERIENCE) and the only thing you want is to test the process of sending a message through the Land, I'll provide you with the addresses of my smart contracts deployed in the corresponding blockchains. Please, if you feel good, share your scripts with me to communicate with my smart contracts :).


**ADDRESS_CCIPReceiver_Unsafe_INTO_SEPOLIA** 
```bash 
0x5a972422eBFE8ea65fb2Ac644B7af258b031BCbD
```

**TRX_HASH_CCIPReceiver_Unsafe_INTO_SEPOLIA**
 ```bash
 0xc7ed9ab8e90b13669412ccfca4569d8cd48cc71d8907b7f88b1989623aacd3b3
 ```

**ADDRESS_CCIPSender_Unsafe_INTO_FUJI**
```bash
0x5a972422eBFE8ea65fb2Ac644B7af258b031BCbD
```

**TRX_HASH_CCIPReceiver_Unsafe_INTO_FUJI** 
```bash
0xb42f83e1cfb055a4eaeab400ebd7f2f7a345e342afdca3a1a32428866f2473e7
```

**TRX_HASH_OF_MESSAGE_SENT**
```bash
0x2899f43ec998fb79992da287844108ea629746856f0b8a28e8e063a17efe8402
```
