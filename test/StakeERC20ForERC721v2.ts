import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import {
  ERC20PresetFixedSupply__factory,
  ERC721PresetMinterPauserAutoId__factory,
  IERC20,
  IERC721,
  StakeERC20ForERC721,
  StakeERC20ForERC721v2,
} from "../typechain";

const DECIMALS = 10n ** 18n;
const TOTAL_TOKEN_SUPPLY = 120_000_000n * DECIMALS;
const DAY = 24n * 60n * 60n;
const MONTH = 30n * DAY;
const YEAR = 12n * MONTH;

const increaseTime = async (seconds: bigint) => {
  await ethers.provider.send("evm_increaseTime", [Number(seconds)]);
  await ethers.provider.send("evm_mine", []);
};

const fundAndStake = async (
  token: IERC20,
  contract: StakeERC20ForERC721 | StakeERC20ForERC721v2,
  account: SignerWithAddress,
  amount: bigint
) => {
  await token.transfer(account.address, amount);
  await token.connect(account).approve(contract.address, amount);
  await contract.connect(account).stake(amount);
};

describe("StakeERC20ForERC721v2", function () {
  let deployer: SignerWithAddress;
  let empty: SignerWithAddress;
  let v1Only: SignerWithAddress;
  let v2Only: SignerWithAddress;
  let hybrid: SignerWithAddress;
  let token: IERC20;
  let reward: IERC721;

  beforeEach(async () => {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    empty = signers[1];
    v1Only = signers[2];
    v2Only = signers[3];
    hybrid = signers[4];
    token = await new ERC20PresetFixedSupply__factory(deployer).deploy(
      "SHRC",
      "SeaHorseToken",
      TOTAL_TOKEN_SUPPLY,
      deployer.address
    );
    const rewardContract = await new ERC721PresetMinterPauserAutoId__factory(
      deployer
    ).deploy("SHR", "SeaHorse", "");
    for (let tokenId = 0; tokenId < 100; tokenId++)
      await rewardContract.mint(deployer.address);
    reward = rewardContract as unknown as IERC721;
  });

  describe("with deployed contracts", () => {
    let v1Contract: StakeERC20ForERC721;
    let v2Contract: StakeERC20ForERC721v2;
    const SCORE = 300n * DECIMALS;
    const PRICE = SCORE * MONTH;

    beforeEach(async () => {
      v1Contract = await (
        await ethers.getContractFactory("StakeERC20ForERC721")
      ).deploy(token.address, reward.address, PRICE / 3n);
      v2Contract = await (
        await ethers.getContractFactory("StakeERC20ForERC721v2")
      ).deploy(token.address, reward.address, PRICE, v1Contract.address);
    });

    it("correctly calculates totalScore", async () => {
      await increaseTime(MONTH);
      expect(await v2Contract.totalScore(empty.address)).to.equal(0);
      await fundAndStake(token, v1Contract, v1Only, SCORE);
      await increaseTime(MONTH);
      expect(await v2Contract.totalScore(v1Only.address)).to.equal(PRICE);
      await fundAndStake(token, v2Contract, v2Only, 2n * SCORE);
      await increaseTime(MONTH);
      expect(await v2Contract.totalScore(v2Only.address)).to.equal(2n * PRICE);
      await token.transfer(hybrid.address, 4n * SCORE);
      await token.connect(hybrid).approve(v1Contract.address, 2n * SCORE);
      await token.connect(hybrid).approve(v2Contract.address, 2n * SCORE);
      await v1Contract.connect(hybrid).stake(2n * SCORE);
      await v2Contract.connect(hybrid).stake(2n * SCORE);
      await increaseTime(MONTH);
      expect(await v2Contract.totalScore(hybrid.address)).to.equal(
        // 2 second score + v1 score + v2 score
        2n * SCORE + 2n * PRICE + 2n * PRICE
      );
    });

    it("does not allow redeem on v1 if no reward tokens in contract", async () => {
      await fundAndStake(token, v1Contract, v1Only, 300n * DECIMALS);
      await increaseTime(MONTH);
      expect(await v1Contract.totalScore(v1Only.address)).to.equal(PRICE);
      expect(await v2Contract.totalScore(v1Only.address)).to.equal(PRICE);
      await expect(v1Contract.connect(v1Only).redeem(1)).to.be.reverted;
      expect(await v1Contract.totalScore(v1Only.address)).to.equal(
        PRICE + 300n * DECIMALS
      );
      expect(await v2Contract.totalScore(v1Only.address)).to.equal(
        PRICE + 300n * DECIMALS
      );
    });

    it("decreases score on redeem and unstake does not increase score", async () => {
      for (let tokenId = 0; tokenId < 10; tokenId++)
        await reward.transferFrom(
          deployer.address,
          v2Contract.address,
          tokenId
        );
      await fundAndStake(token, v1Contract, v1Only, 2n * SCORE);
      await increaseTime(MONTH - 1n);
      await v1Contract.connect(v1Only).unstake(2n * SCORE);
      expect(await v2Contract.totalScore(v1Only.address)).to.equal(2n * PRICE);
      expect(await reward.balanceOf(v1Only.address)).to.equal(0);
      await v2Contract.connect(v1Only).redeem(2);
      expect(await v2Contract.totalScore(v1Only.address)).to.equal(0);
      expect(await reward.balanceOf(v1Only.address)).to.equal(2);

      await fundAndStake(token, v2Contract, v2Only, 2n * SCORE);
      await increaseTime(MONTH - 1n);
      await v2Contract.connect(v2Only).unstake(2n * SCORE);
      expect(await v2Contract.totalScore(v2Only.address)).to.equal(2n * PRICE);
      expect(await reward.balanceOf(v2Only.address)).to.equal(0);
      await v2Contract.connect(v2Only).redeem(2);
      expect(await v2Contract.totalScore(v2Only.address)).to.equal(0);
      expect(await reward.balanceOf(v2Only.address)).to.equal(2);

      await token.transfer(hybrid.address, 4n * SCORE);
      await token.connect(hybrid).approve(v1Contract.address, 2n * SCORE);
      await token.connect(hybrid).approve(v2Contract.address, 2n * SCORE);
      await v1Contract.connect(hybrid).stake(2n * SCORE);
      await v2Contract.connect(hybrid).stake(2n * SCORE);
      await increaseTime(MONTH);
      expect(
        Number(await v2Contract.totalScore(hybrid.address))
      ).to.be.greaterThan(Number(4n * PRICE));
      expect(
        Number(await v2Contract.totalScore(hybrid.address))
      ).to.be.lessThan(Number(5n * PRICE));
      expect(await reward.balanceOf(hybrid.address)).to.equal(0);
      await v2Contract.connect(hybrid).redeem(4);
      expect(
        Number(await v2Contract.totalScore(hybrid.address))
      ).to.be.lessThan(Number(PRICE));
      expect(await reward.balanceOf(hybrid.address)).to.equal(4);

      await v1Contract.connect(hybrid).unstake(2n * SCORE);

      await increaseTime(MONTH);
      expect(await v2Contract.totalScore(v1Only.address)).to.equal(0);
      expect(await v2Contract.totalScore(v2Only.address)).to.equal(0);
      expect(
        Number(await v2Contract.totalScore(hybrid.address))
      ).to.be.greaterThan(Number(2n * PRICE));
      expect(
        Number(await v2Contract.totalScore(hybrid.address))
      ).to.be.lessThan(Number(3n * PRICE));
      await v2Contract.connect(hybrid).redeem(2);
      expect(await reward.balanceOf(hybrid.address)).to.equal(6);
      await v2Contract.connect(hybrid).unstake(2n * SCORE);
      await increaseTime(MONTH);
      expect(
        Number(await v2Contract.totalScore(hybrid.address))
      ).to.be.lessThan(Number(PRICE));
      await expect(v2Contract.connect(hybrid).redeem(1)).to.be.revertedWith(
        "NotEnoughScore"
      );
      await expect(v2Contract.connect(hybrid).unstake(1)).to.be.revertedWith(
        "NotEnoughStaked"
      );
    });
  });

  it("should be able to stake total supply for a 100 years in v1", async () => {
    const contract = await (
      await ethers.getContractFactory("StakeERC20ForERC721")
    ).deploy(token.address, reward.address, TOTAL_TOKEN_SUPPLY * 10n * YEAR);
    // 1 reward every 10 years for staking total token supply
    for (let tokenId = 0; tokenId < 10; tokenId++)
      await reward.transferFrom(deployer.address, contract.address, tokenId);
    await fundAndStake(token, contract, v1Only, TOTAL_TOKEN_SUPPLY);
    await increaseTime(100n * YEAR - 1n);
    await contract.connect(v1Only).unstake(TOTAL_TOKEN_SUPPLY);
    expect(await token.balanceOf(contract.address)).to.equal(0);
    expect(await token.balanceOf(v1Only.address)).to.equal(TOTAL_TOKEN_SUPPLY);
    expect((await contract.stakes(v1Only.address)).amount).to.equal(0);
    expect(await contract.totalScore(v1Only.address)).to.equal(
      await (await contract.price()).mul(10)
    );
    await contract.connect(v1Only).redeem(10);
    expect(await contract.totalScore(v1Only.address)).to.equal(0);
    expect(await reward.balanceOf(contract.address)).to.equal(0);
    expect(await reward.balanceOf(v1Only.address)).to.equal(10);
  });

  it("should be able to stake total supply for a 100 years in v2", async () => {
    const v1Contract = await (
      await ethers.getContractFactory("StakeERC20ForERC721")
    ).deploy(token.address, reward.address, TOTAL_TOKEN_SUPPLY * 10n * YEAR);
    const contract = await (
      await ethers.getContractFactory("StakeERC20ForERC721v2")
    ).deploy(
      token.address,
      reward.address,
      TOTAL_TOKEN_SUPPLY * 10n * YEAR,
      v1Contract.address
    );
    // 1 reward every 10 years for staking total token supply
    for (let tokenId = 0; tokenId < 10; tokenId++)
      await reward.transferFrom(deployer.address, contract.address, tokenId);
    await fundAndStake(token, contract, v2Only, TOTAL_TOKEN_SUPPLY);
    await increaseTime(100n * YEAR - 1n);
    await contract.connect(v2Only).unstake(TOTAL_TOKEN_SUPPLY);
    expect(await token.balanceOf(contract.address)).to.equal(0);
    expect(await token.balanceOf(v2Only.address)).to.equal(TOTAL_TOKEN_SUPPLY);
    expect((await contract.stakes(v2Only.address)).amount).to.equal(0);
    expect(await contract.totalScore(v2Only.address)).to.equal(
      await (await contract.price()).mul(10)
    );
    await contract.connect(v2Only).redeem(10);
    expect(await contract.totalScore(v2Only.address)).to.equal(0);
    expect(await reward.balanceOf(contract.address)).to.equal(0);
    expect(await reward.balanceOf(v2Only.address)).to.equal(10);
  });
});
