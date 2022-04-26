const { expect } = require('chai');
require('dotenv').config()

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

async function getSigners(name, ...params) {
  //deploy the contract
  const contract = await deploy(name, ...params)
  
  //get the signers
  const signers = await ethers.getSigners()
  //attach contracts
  for (let i = 0; i < signers.length; i++) {
    const Contract = await ethers.getContractFactory(name, signers[i])
    signers[i].withContract = await Contract.attach(contract.address)
  }

  return signers
}

describe('ERC20 Tests', function () {
  before(async function() {
    const [ 
      owner, 
      holder1, 
      holder2, 
      holder3, 
      holder4
    ] = await getSigners('ERC20Mock')

    this.signers = {
      owner, 
      holder1, 
      holder2, 
      holder3, 
      holder4
    }
  })
  
  it('Should mint', async function () {
    const { owner, holder1 } = this.signers

    await owner.withContract.unpause()
    await owner.withContract.mint(holder1.address, ethers.utils.parseEther('10'))
    expect(await owner.withContract.balanceOf(holder1.address)).to.equal(
      ethers.utils.parseEther('10')
    )
  })
  
  it('Should transfer', async function () {
    const { owner, holder1, holder2 } = this.signers

    await holder1.withContract.transfer(holder2.address, ethers.utils.parseEther('5'))
    expect(await owner.withContract.balanceOf(holder1.address)).to.equal(
      ethers.utils.parseEther('5')
    )

    expect(await owner.withContract.balanceOf(holder2.address)).to.equal(
      ethers.utils.parseEther('5')
    )
  })
  
  it('Should burn', async function () {
    const { owner, holder1 } = this.signers

    await owner.withContract.burn()
    await owner.withContract.mint(holder1.address, ethers.utils.parseEther('10'))
    expect(await owner.withContract.balanceOf(holder1.address)).to.equal(
      ethers.utils.parseEther('10')
    )
  })

  it('Should not transfer when paused', async function () {
    const { owner, holder1, holder2 } = this.signers
    await owner.withContract.pause()
    await expect(
      holder1.withContract.transfer(holder2.address, ethers.utils.parseEther('5'))
    ).to.revertedWith('Token transfer while paused')
  })
})