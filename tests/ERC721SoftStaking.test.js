const { expect } = require('chai')

if (process.env.BLOCKCHAIN_NETWORK != 'hardhat') {
  console.error('Exited testing with network:', process.env.BLOCKCHAIN_NETWORK)
  process.exit(1);
}

async function deploy(name, ...params) {
  //deploy the contract
  const ContractFactory = await ethers.getContractFactory(name)
  const contract = await ContractFactory.deploy(...params)
  await contract.deployed()

  return contract
}

async function bindContract(key, name, contract, signers) {
  //attach contracts
  for (let i = 0; i < signers.length; i++) {
    const Contract = await ethers.getContractFactory(name, signers[i])
    signers[i][key] = await Contract.attach(contract.address)
  }

  return signers
}

function getRole(name) {
  if (!name || name === 'DEFAULT_ADMIN_ROLE') {
    return '0x0000000000000000000000000000000000000000000000000000000000000000';
  }

  return '0x' + Buffer.from(
    ethers.utils.solidityKeccak256(['string'], [name]).slice(2), 
    'hex'
  ).toString('hex')
}

describe('ERC721SoftStaking Tests', function () {
  before(async function() {
    const signers = await ethers.getSigners()
    const nft = await deploy('ERC721Mock', 'Test', 'TEST')
    const token = await deploy('ERC20Mock', 'Test', 'TEST', ethers.utils.parseEther('1000000000'))
    const staking = await deploy('ERC721SoftStaking', nft.address, token.address, ethers.utils.parseEther('0.00006'))

    await bindContract('withNFT', 'ERC721Mock', nft, signers)
    await bindContract('withToken', 'ERC20Mock', token, signers)
    await bindContract('withStaking', 'ERC721SoftStaking', staking, signers)

    const [ admin, staker ] = signers

    //mint an NFT to staker
    await admin.withNFT.mint(staker.address, 1)

    this.now = Math.floor(Date.now() / 1000)
    this.signers = { admin, staker }
  })

  it('Should stake NFT', async function() {
    const { admin, staker } = this.signers
    await staker.withStaking.stake([1])
    expect(await admin.withStaking.since(1)).to.be.above(0)
  })

  it('Should fastforward 30 days later', async function() {
    await ethers.provider.send('evm_mine');
    await ethers.provider.send('evm_increaseTime', [3600 * 24 * 30]); 
    await ethers.provider.send('evm_mine');
  })

  it('Should be releasable', async function() {
    const { admin } = this.signers
    const rate = await admin.withStaking.TOKEN_RATE()
    expect(await admin.withStaking.releaseable(1)).to.be.above(
      String(rate * 3600 * 24 * 30)
    )
  })

  it('Should release', async function() {
    const { admin, staker } = this.signers
    const rate = await admin.withStaking.TOKEN_RATE()
    expect(await admin.withToken.balanceOf(staker.address)).to.equal(0)
    await staker.withStaking.release([1])
    expect(await admin.withToken.balanceOf(staker.address)).to.be.above(
      String(rate * 3600 * 24 * 30)
    )
  })

  it('Should fastforward 30 days later', async function() {
    await ethers.provider.send('evm_mine');
    await ethers.provider.send('evm_increaseTime', [3600 * 24 * 60]); 
    await ethers.provider.send('evm_mine');
  })

  it('Should unstake', async function() {
    const { admin, staker } = this.signers
    const rate = await admin.withStaking.TOKEN_RATE()
    await staker.withStaking.unstake([1])
    expect(await admin.withToken.balanceOf(staker.address)).to.be.above(
      String(rate * 3600 * 24 * 60)
    )
    expect(await admin.withNFT.ownerOf(1)).to.equal(staker.address)
    expect(await admin.withStaking.since(1)).to.equal(0)
  })
})