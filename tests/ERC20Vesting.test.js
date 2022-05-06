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

describe('ERC20Vesting Tests', function () {
  before(async function () {
    const signers = await ethers.getSigners()
    const token = await deploy('ERC20Mock', 'Test', 'TEST', ethers.utils.parseEther('1000000000'))
    await bindContract('withToken', 'ERC20Mock', token, signers)
    const vesting = await deploy('ERC20Vesting', token.address, signers[0].address)
    await bindContract('withVesting', 'ERC20Vesting', vesting, signers)

    const [ owner, investor1, investor2 ] = signers

    //no roles in mock
    //await owner.withToken.grantRole(getRole('MINTER_ROLE'), vesting.address)
    await owner.withVesting.grantRole(getRole('VESTER_ROLE'), owner.address)

    this.signers = { owner, investor1, investor2 }
    this.now = Math.floor(Date.now() / 1000)
  })

  it('Should vest', async function () {
    const { owner, investor1, investor2 } = this.signers

    await owner.withVesting.vest(
      investor1.address, 
      ethers.utils.parseEther('100'),
      this.now,
      this.now + (3600 * 24 * 30)
    )

    const info1 = await owner.withVesting.vesting(investor1.address)

    expect(info1.startDate).to.equal(this.now)
    expect(info1.endDate).to.equal(this.now + (3600 * 24 * 30))
    expect(info1.total).to.equal(ethers.utils.parseEther('100'))

    expect(
      await owner.withVesting.totalVestedAmount(
        investor1.address,
        this.now + (3600 * 24 * 30)
      )
    ).to.equal(ethers.utils.parseEther('100'))

    //------

    await owner.withVesting.vest(
      investor2.address, 
      ethers.utils.parseEther('200'),
      this.now,
      this.now + (3600 * 24 * 15)
    )
  
    const info2 = await owner.withVesting.vesting(investor2.address)

    expect(info2.startDate).to.equal(this.now)
    expect(info2.endDate).to.equal(this.now + (3600 * 24 * 15))
    expect(info2.total).to.equal(ethers.utils.parseEther('200'))
    
    expect(
      await owner.withVesting.totalVestedAmount(
        investor2.address,
        this.now + (3600 * 24 * 15)
      )
    ).to.equal(ethers.utils.parseEther('200'))
  })

  it('Should time travel 15 days', async function () {  
    await ethers.provider.send('evm_mine');
    await ethers.provider.send('evm_setNextBlockTimestamp', [this.now + (3600 * 24 * 15)]); 
    await ethers.provider.send('evm_mine');
  })

  it('Should release', async function () {
    const { owner, investor1, investor2 } = this.signers

    await owner.withVesting.release(investor1.address)
    expect(await owner.withToken.balanceOf(investor1.address)).to.be.above(
      ethers.utils.parseEther('50')
    )

    //-------

    await owner.withVesting.release(investor2.address)
    expect(await owner.withToken.balanceOf(investor2.address)).to.equal(
      ethers.utils.parseEther('200')
    )
  })
})