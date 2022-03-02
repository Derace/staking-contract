//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract StakeERC20ForERC721 is AccessControl, ERC721Holder {
    using SafeERC20 for IERC20;

    error NotEnoughStaked();
    error NotEnoughScore();

    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");

    IERC20 public token;
    IERC721Enumerable public reward;
    uint256 public price;
    uint256 public time;

    struct Staking {
        uint256 previousScore;
        uint256 timestamp;
        uint256 amount;
    }

    event Stake(address indexed staker, uint256 amount);
    event Unstake(address indexed staker, uint256 amount);
    event Redeem(address indexed staker, uint256 amount);

    mapping(address => Staking) public stakes;

    constructor(IERC20 _token, IERC721Enumerable _reward, uint256 _price) {
        token = _token;
        reward = _reward;
        price = _price;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(TREASURY_ROLE, msg.sender);
    }

    function totalScore(address staker) public view returns (uint256) {
        uint256 duration = (block.timestamp - stakes[staker].timestamp);
        uint256 currentScore = stakes[staker].amount * duration;
        return stakes[staker].previousScore + currentScore;
    }

    function _restake(address staker) private {
        stakes[staker].previousScore = totalScore(msg.sender);
        stakes[staker].timestamp = block.timestamp;
    }
    
    function stake(uint256 amount) public {
        token.safeTransferFrom(msg.sender, address(this), amount);
        _restake(msg.sender);
        stakes[msg.sender].amount += amount;
        emit Stake(msg.sender, amount);
    }

    function unstake(uint256 amount) public {
        if (amount > stakes[msg.sender].amount) revert NotEnoughStaked();
        _restake(msg.sender);
        stakes[msg.sender].amount -= amount;
        emit Unstake(msg.sender, amount);
        token.safeTransfer(msg.sender, amount);
    }

    function _sendReward(address from, address to, uint256 amount) private {
        uint256 balance = reward.balanceOf(from);
        for (uint256 i = 0; i < amount; i++)
            reward.transferFrom(from, to, reward.tokenOfOwnerByIndex(from, --balance));
    }

    function redeem(uint256 amount) public {
        uint256 score = amount * price;
        _restake(msg.sender);
        if (stakes[msg.sender].previousScore < score) revert NotEnoughScore();
        stakes[msg.sender].previousScore -= score;
        emit Redeem(msg.sender, amount);
        _sendReward(address(this), msg.sender, amount);
    }

    function withdraw(uint256 amount) public onlyRole(TREASURY_ROLE) {
        _sendReward(address(this), msg.sender, amount);
    }

    function deposit(uint256 amount) public onlyRole(TREASURY_ROLE) {
        _sendReward(msg.sender, address(this), amount);
    }
}
