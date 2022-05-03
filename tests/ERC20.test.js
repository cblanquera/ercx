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

async function bindContract(key, name, contract, signers) {
  //attach contracts
  for (let i = 0; i < signers.length; i++) {
    const Contract = await ethers.getContractFactory(name, signers[i])
    signers[i][key] = await Contract.attach(contract.address)
  }

  return signers
}

function permit(from, to, amount, nonce) {
  return Buffer.from(
    ethers.utils.solidityKeccak256(
      ['string', 'address', 'address', 'uint256', 'uint256'],
      ['transfer', from, to, amount, nonce]
    ).slice(2),
    'hex'
  )
}

describe('ERC20 Tests', function () {
  before(async function() {
    const signers = await ethers.getSigners()
    const token = await deploy('ERC20Mock', 'Test', 'TEST', ethers.utils.parseEther('1000000000'))
    await bindContract('withContract', 'ERC20Mock', token, signers)
    this.operator = await deploy('ERC20MockOperator', token.address)
    await bindContract('withOperator', 'ERC20MockOperator', this.operator, signers)

    const [ 
      owner, 
      holder1, 
      holder2, 
      holder3, 
      holder4
    ] = signers;

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

    await owner.withContract.mint(holder1.address, ethers.utils.parseEther('10'))
    expect(await owner.withContract.balanceOf(holder1.address)).to.equal(
      ethers.utils.parseEther('10')
    )
    expect(await owner.withContract.totalSupply()).to.equal(
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

  it('Should approve', async function () {
    const { holder1, holder2 } = this.signers

    await holder2.withContract.approve(
      holder1.address, ethers.utils.parseEther('2')
    )

    expect(
      await holder2.withContract.allowance(holder2.address, holder1.address)
    ).to.equal(
      ethers.utils.parseEther('2')
    )

    await holder2.withContract.increaseAllowance(
      holder1.address, ethers.utils.parseEther('2')
    )

    expect(
      await holder2.withContract.allowance(holder2.address, holder1.address)
    ).to.equal(
      ethers.utils.parseEther('4')
    )

    await holder2.withContract.decreaseAllowance(
      holder1.address, ethers.utils.parseEther('1')
    )

    expect(
      await holder2.withContract.allowance(holder2.address, holder1.address)
    ).to.equal(
      ethers.utils.parseEther('3')
    )
  })

  it('Should transfer from', async function () {
    const { owner, holder1, holder2 } = this.signers

    await holder1.withContract.transferFrom(
      holder2.address, 
      holder1.address, 
      ethers.utils.parseEther('3')
    )
    expect(await owner.withContract.balanceOf(holder1.address)).to.equal(
      ethers.utils.parseEther('8')
    )

    expect(await owner.withContract.balanceOf(holder2.address)).to.equal(
      ethers.utils.parseEther('2')
    )
  })

  it('Should burn', async function () {
    const { owner, holder1 } = this.signers

    await holder1.withContract.burn(ethers.utils.parseEther('8'))
    await holder1.withContract.mint(holder1.address, ethers.utils.parseEther('10'))
    expect(await owner.withContract.balanceOf(holder1.address)).to.equal(
      ethers.utils.parseEther('10')
    )
  })

  it('Should not transfer when paused', async function () {
    const { owner, holder1, holder2 } = this.signers
    await owner.withContract.pause()
    await expect(
      holder1.withContract.transfer(holder2.address, ethers.utils.parseEther('2'))
    ).to.revertedWith('InvalidCall()')
    await owner.withContract.unpause()
  })

  it('Should allow operator', async function () {
    const { owner, holder1, holder2 } = this.signers
    await owner.withContract.setOperator(this.operator.address, true)
    await owner.withOperator.transferFrom(
      holder1.address, 
      holder2.address, 
      ethers.utils.parseEther('4')
    )

    expect(await owner.withContract.balanceOf(holder1.address)).to.equal(
      ethers.utils.parseEther('6')
    )

    expect(await owner.withContract.balanceOf(holder2.address)).to.equal(
      ethers.utils.parseEther('6')
    )

    await owner.withOperator.burnFrom(
      holder1.address, 
      ethers.utils.parseEther('1')
    )

    expect(await owner.withContract.balanceOf(holder1.address)).to.equal(
      ethers.utils.parseEther('5')
    )
  })

  it('Should permit', async function () {
    const { owner, holder1, holder2 } = this.signers

    const message = permit(
      holder2.address, 
      holder1.address, 
      ethers.utils.parseEther('1'),
      1
    )
    const signature = await holder2.signMessage(message)

    await owner.withContract.permit(
      holder2.address, 
      holder1.address, 
      ethers.utils.parseEther('1'),
      1,
      signature
    )

    expect(await owner.withContract.balanceOf(holder1.address)).to.equal(
      ethers.utils.parseEther('6')
    )

    expect(await owner.withContract.balanceOf(holder2.address)).to.equal(
      ethers.utils.parseEther('5')
    )
  })
})