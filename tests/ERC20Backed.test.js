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

function getRole(name) {
  if (!name || name === 'DEFAULT_ADMIN_ROLE') {
    return '0x0000000000000000000000000000000000000000000000000000000000000000';
  }

  return '0x' + Buffer.from(
    ethers.utils.solidityKeccak256(['string'], [name]).slice(2), 
    'hex'
  ).toString('hex')
}

describe('ERC20Backed Tests', function () {
  before(async function() {
    const signers = await ethers.getSigners()
    const token = await deploy('ERC20Mock', 'Test', 'TEST', ethers.utils.parseEther('1000000000'))
    await bindContract('withToken', 'ERC20Mock', token, signers)
    const backed = await deploy('ERC20Backed', token.address, 5000, 5000, 20000, signers[0].address)
    await bindContract('withBacked', 'ERC20Backed', backed, signers)

    const [ 
      owner, 
      user1,
      user2,
      user3,
      user4,
      fund
    ] = signers;

    this.signers = {
      owner, 
      user1,
      user2,
      user3,
      user4,
      fund
    }

    //send some ether and tokens
    await fund.sendTransaction({
      to: backed.address,
      value: ethers.utils.parseEther('10')
    })

    await owner.withToken.mint(
      backed.address,
      ethers.utils.parseEther('100')
    )
  })
  
  it('Should have a balance', async function () {
    const { owner } = this.signers

    expect(await owner.withBacked.provider.getBalance(owner.withBacked.address)).to.equal(
      ethers.utils.parseEther('10')
    )

    expect(await owner.withToken.balanceOf(owner.withBacked.address)).to.equal(
      ethers.utils.parseEther('100')
    )

    expect(await owner.withBacked.balanceEther()).to.equal(
      ethers.utils.parseEther('10')
    )

    expect(await owner.withBacked.balanceToken()).to.equal(
      ethers.utils.parseEther('100')
    )
  })
  
  it('Should have a buy and sell price', async function () {
    const { owner } = this.signers

    //so backed has 10 eth and 100 tokens

    //buying = ((eth-interest)/cap) * percent * token amount 
    //buying = ((10 eth/1B tokens) * 0.50 * 100 tokens
    //buying = 0.00000001 * 0.5 * 100 = 0.0000005
    expect(await owner.withBacked.buyingFor(
      ethers.utils.parseEther('10')
    )).to.equal(
      ethers.utils.parseEther('0.0000005')
    )

    //buying = ((eth-interest)/cap) * percent * token amount 
    //buying = ((10 eth/1B tokens) * 2 * 100 tokens
    //buying = 0.00000001 * 0.5 * 100 = 0.000002
    expect(await owner.withBacked.sellingFor(
      ethers.utils.parseEther('10')
    )).to.equal(
      ethers.utils.parseEther('0.000002')
    )
  })
  
  it('Should buy', async function () {
    const { owner, user1 } = this.signers

    await owner.withBacked.buy(
      user1.address,
      ethers.utils.parseEther('10'),
      { value: ethers.utils.parseEther('0.000002') }
    )

    expect(await owner.withToken.balanceOf(user1.address)).to.equal(
      ethers.utils.parseEther('10')
    )

    expect(await owner.withBacked.balanceEther()).to.equal(
      ethers.utils.parseEther('10.000001')
    )

    expect(await owner.provider.getBalance(owner.withBacked.address)).to.equal(
      ethers.utils.parseEther('10.000002')
    )

    expect(await owner.withBacked.balanceToken()).to.equal(
      ethers.utils.parseEther('90')
    )
  })
  
  it('Should sell', async function () {
    const { owner, user1 } = this.signers

    await user1.withToken.approve(
      owner.withBacked.address,
      ethers.utils.parseEther('1')
    )

    await owner.withBacked.sell(
      user1.address,
      ethers.utils.parseEther('1')
    )

    expect(await owner.withToken.balanceOf(user1.address)).to.equal(
      ethers.utils.parseEther('9')
    )

    expect(await owner.withBacked.balanceEther()).to.equal(
      ethers.utils.parseEther('10.000000949999995')
    )

    expect(await owner.provider.getBalance(owner.withBacked.address)).to.equal(
      ethers.utils.parseEther('10.000001949999995')
    )

    expect(await owner.withBacked.balanceToken()).to.equal(
      ethers.utils.parseEther('91')
    )
  })
  
  it('Should withdraw', async function () {
    const { owner, user1 } = this.signers

    await owner.withBacked.grantRole(getRole('WITHDRAWER_ROLE'), owner.address)

    const balance = await owner.withBacked.provider.getBalance(owner.address)
    await owner.withBacked.withdraw(owner.address)
    expect(
      balance - await owner.provider.getBalance(owner.address)
    ).to.equal(
      ethers.utils.parseEther('0.000188119999578112')
    )
  })
})