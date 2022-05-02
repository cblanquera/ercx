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

function permit(from, to, id, nonce) {
  return Buffer.from(
    ethers.utils.solidityKeccak256(
      ['string', 'address', 'address', 'uint256', 'uint256'],
      ['transfer', from, to, id, nonce]
    ).slice(2),
    'hex'
  )
}

describe('ERC721 Tests', function () {
  before(async function() {
    const [ 
      owner, 
      holder1, 
      holder2, 
      holder3, 
      holder4
    ] = await getSigners('ERC721Mock', 'Test', 'TEST')

    this.signers = {
      owner, 
      holder1, 
      holder2, 
      holder3, 
      holder4
    }

    this.operator = await deploy('ERC721MockOperator', owner.withContract.address)
    //attach contracts
    for (const signer in this.signers) {
      const Contract = await ethers.getContractFactory('ERC721MockOperator', this.signers[signer])
      this.signers[signer].withOperator = await Contract.attach(this.operator.address)
    }
  })

  it('Should mint', async function () {
    const { owner, holder1 } = this.signers

    await owner.withContract.mint(holder1.address, 1)
    expect(await owner.withContract.balanceOf(holder1.address)).to.equal(1)
    expect(await owner.withContract.totalSupply()).to.equal(1)
    expect(await owner.withContract.ownerOf(1)).to.equal(holder1.address)
  })

  it('Should transfer', async function () {
    const { owner, holder1, holder2 } = this.signers

    await holder1.withContract.transferFrom(holder1.address, holder2.address, 1)
    expect(await owner.withContract.balanceOf(holder1.address)).to.equal(0)
    expect(await owner.withContract.balanceOf(holder2.address)).to.equal(1)
    expect(await owner.withContract.ownerOf(1)).to.equal(holder2.address)

    await holder2.withContract['safeTransferFrom(address,address,uint256)'](holder2.address, holder1.address, 1)
    expect(await owner.withContract.balanceOf(holder1.address)).to.equal(1)
    expect(await owner.withContract.balanceOf(holder2.address)).to.equal(0)
    expect(await owner.withContract.ownerOf(1)).to.equal(holder1.address)
  })

  it('Should approve', async function () {
    const { holder1, holder2 } = this.signers

    await holder1.withContract.approve(holder2.address, 1)

    expect(
      await holder1.withContract.getApproved(1)
    ).to.equal(holder2.address)
  })

  it('Should burn', async function () {
    const { owner, holder1 } = this.signers

    await holder1.withContract.burn(1)
    await holder1.withContract.mint(holder1.address, 2)
    expect(await owner.withContract.balanceOf(holder1.address)).to.equal(1)
  })

  it('Should not transfer when paused', async function () {
    const { owner, holder1, holder2 } = this.signers
    await owner.withContract.pause()
    await expect(
      holder1.withContract['safeTransferFrom(address,address,uint256)'](holder1.address, holder2.address, 2)
    ).to.revertedWith('InvalidCall()')
    await owner.withContract.unpause()
  })

  it('Should allow operator', async function () {
    const { owner, holder1, holder2 } = this.signers
    await owner.withContract.setOperator(this.operator.address, true)
    await owner.withOperator.transferFrom(
      holder1.address, 
      holder2.address, 
      2
    )

    expect(await owner.withContract.balanceOf(holder1.address)).to.equal(0)
    expect(await owner.withContract.balanceOf(holder2.address)).to.equal(1)
    expect(await owner.withContract.ownerOf(2)).to.equal(holder2.address)

    await owner.withOperator.burnFrom(2)

    expect(await owner.withContract.balanceOf(holder2.address)).to.equal(0)

    await holder1.withContract.mint(holder1.address, 3)
  })

  it('Should permit', async function () {
    const { owner, holder1, holder2 } = this.signers

    const message = permit(holder1.address, holder2.address, 3, 1)
    const signature = await holder1.signMessage(message)
    await owner.withContract['permit(address,address,uint256,uint256,bytes)'](holder1.address, holder2.address, 3, 1, signature)

    expect(await owner.withContract.balanceOf(holder1.address)).to.equal(0)
    expect(await owner.withContract.balanceOf(holder2.address)).to.equal(1)
    expect(await owner.withContract.ownerOf(3)).to.equal(holder2.address)
  })
})