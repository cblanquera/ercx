# ERCX

A library for Ethereum based smart contract experiments.

Everyone relies on [OpenZeppelin](https://www.npmjs.com/package/@openzeppelin/contracts) 
to be secure and stable, which is also a double edged sword because it 
can take a very long time to update and add new contracts.

The contracts found in this library are simply theoretical experiments 
applied. This means while standard versioning will be applied, all 
contracts are subject to change.

### Install

```bash
$ npm i ercx
```

You will need to provide a private key to deploy to a testnet and a 
Coin Market Cap Key to see gas price conversions when testing.

### Contributing

Make sure in `.env` to set the `BLOCKCHAIN_NETWORK` to `hardhat`.

```bash
$ npm test
```