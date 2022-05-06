const { expect } = require('chai');
require('dotenv').config();

if (process.env.BLOCKCHAIN_NETWORK != 'hardhat') {
  console.error('Exited testing with network:', process.env.BLOCKCHAIN_NETWORK);
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

  return '0x' + Buffer.from(ethers.utils.solidityKeccak256(['string'], [name]).slice(2), 'hex').toString('hex');
}

describe('ERC20VestingSale Tests', function () {
  before(async function () {
    const signers = await ethers.getSigners()
    const token = await deploy('ERC20Mock', 'Test', 'TEST', ethers.utils.parseEther('1000000000'))
    await bindContract('withToken', 'ERC20Mock', token, signers)
    const vesting = await deploy('ERC20Vesting', token.address, signers[0].address)
    await bindContract('withVesting', 'ERC20Vesting', vesting, signers)
    const sale = await deploy('ERC20VestingSale', token.address, vesting.address, signers[0].address)
    await bindContract('withSale', 'ERC20VestingSale', sale, signers)

    const [ owner, investor1, investor2 ] = signers

    await owner.withVesting.grantRole(getRole('VESTER_ROLE'), sale.address)
    await owner.withSale.grantRole(getRole('FUNDER_ROLE'), owner.address)
    await owner.withSale.grantRole(getRole('CURATOR_ROLE'), owner.address)

    this.signers = { owner, investor1, investor2 }
    this.now = Math.floor(Date.now() / 1000)
  })

  it('Should not buy', async function () {
    const { owner, investor1 } = this.signers

    await expect(
      investor1.withSale.buy(
        investor1.address, 
        ethers.utils.parseEther('100'),
        { value: ethers.utils.parseEther('1') }
      )
    ).to.be.revertedWith('InvalidCall()')
  })

  it('Should set stage', async function () {
    const { owner, investor1 } = this.signers

    await owner.withSale.setStage(
      ethers.utils.parseEther('0.1'),
      ethers.utils.parseEther('100'),
      this.now + (3600 * 24 * 10)
    )

    expect(
      await owner.withSale.currentTokenPrice()
    ).to.equal(ethers.utils.parseEther('0.1'))

    expect(
      await owner.withSale.currentTokenLimit()
    ).to.equal(ethers.utils.parseEther('100'))

    expect(
      await owner.withSale.currentVestedDate()
    ).to.equal(this.now + (3600 * 24 * 10))

    expect(await owner.withSale.purchaseable(
      ethers.utils.parseEther('100')
    )).to.equal(true)

    expect(await owner.withSale.purchaseable(
      ethers.utils.parseEther('1000')
    )).to.equal(false)

    expect(
      await owner.withSale.purchaseable(ethers.utils.parseEther('50'))
    ).to.equal(true)
  })

  it('Should not buy', async function () {
    const { owner, investor1 } = this.signers

    await expect(//wrong amount
      investor1.withSale.buy(
        investor1.address, 
        ethers.utils.parseEther('100'),
        { value: ethers.utils.parseEther('1') }
      )
    ).to.be.revertedWith('InvalidCall()')
  })

  it('Should buy', async function () {
    const { owner, investor1, investor2 } = this.signers

    await investor1.withSale.buy(
      investor1.address, 
      ethers.utils.parseEther('50'),
      { value: ethers.utils.parseEther('5') }
    )

    const info1 = await owner.withVesting.vesting(investor1.address)
    expect(info1.endDate).to.equal(this.now + (3600 * 24 * 10))
    expect(info1.total).to.equal(ethers.utils.parseEther('50'))

    await owner.withSale.setStage(
      ethers.utils.parseEther('0.2'),
      ethers.utils.parseEther('200'),
      this.now + (3600 * 24 * 20)
    )

    await investor2.withSale.buy(
      investor2.address, 
      ethers.utils.parseEther('150'),
      { value: ethers.utils.parseEther('30') }
    )

    const info2 = await owner.withVesting.vesting(investor2.address)
    expect(info2.endDate).to.equal(this.now + (3600 * 24 * 20))
    expect(info2.total).to.equal(ethers.utils.parseEther('150'))
  })

  it('Should withdraw', async function () {
    const { owner } = this.signers

    const startingBalance = parseFloat(
      ethers.utils.formatEther(await owner.getBalance())
    )

    await owner.withSale.withdraw(owner.address)
    
    expect(parseFloat(
      ethers.utils.formatEther(await owner.getBalance())
      //also less gas
    ) - startingBalance).to.be.above(34.5)
  })
})