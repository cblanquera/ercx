# ERX

Home of my ERC experiments

### Install

```bash
$ cp .env.sample to .env
$ npm install
```

You will need to provide a private key to deploy to a testnet and a 
Coin Market Cap Key to see gas price conversions when testing.

### Testing

Make sure in `.env` to set the `BLOCKCHAIN_NETWORK` to `hardhat`.

```bash
$ npm test
```