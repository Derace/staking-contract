//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface ScoreSource {
    function totalScore(address staker) external view returns (uint256);
}

library ERC721Fungible {
    function transferManyFrom(IERC721Enumerable token, address from, address to, uint256 amount) internal {
        uint256 balance = token.balanceOf(from);
        for (uint256 i = 0; i < amount; i++)
            token.transferFrom(from, to, token.tokenOfOwnerByIndex(from, --balance));
    }
}

contract StakeERC20ForERC721v2 is AccessControl, ERC721Holder, ScoreSource {
    using SafeERC20 for IERC20;
    using ERC721Fungible for IERC721Enumerable;

    // Errors

    error NotEnoughStaked();
    error NotEnoughScore();

    // Events

    event Stake(address indexed staker, uint256 amount);
    event Unstake(address indexed staker, uint256 amount);
    event Redeem(address indexed staker, uint256 amount);

    // Structs

    struct Staking {
        uint256 previousInternalScore;
        uint256 redeemedScore;
        uint256 timestamp;
        uint256 amount;
    }

    // Constants

    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");

    // Immutable config

    IERC20 public token;
    IERC721Enumerable public reward;
    ScoreSource public externalScores;

    // Mutable config

    uint256 public price;

    // State

    mapping(address => Staking) public stakes;
    address[] public stakers;

    // Constructor

    constructor(IERC20 _token, IERC721Enumerable _reward, uint256 _price, ScoreSource _externalScores) {
        token = _token;
        reward = _reward;
        price = _price;
        externalScores = _externalScores;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(TREASURY_ROLE, msg.sender);
    }

    // Private views

    function _totalInternalScore(address staker) private view returns (uint256) {
        uint256 duration = block.timestamp - stakes[staker].timestamp;
        uint256 currentScore = stakes[staker].amount * duration;
        return stakes[staker].previousInternalScore + currentScore;
    }

    // Public views

    function totalScore(address staker) public view returns (uint256) {
        return _totalInternalScore(staker) + externalScores.totalScore(staker) - stakes[staker].redeemedScore;
    }

    // Private functions

    function _restake() private {
        stakes[msg.sender].previousInternalScore = _totalInternalScore(msg.sender);
        stakes[msg.sender].timestamp = block.timestamp;
    }

    // Staking functions
    
    function stake(uint256 amount) public {
        token.safeTransferFrom(msg.sender, address(this), amount);
        if (stakes[msg.sender].timestamp == 0) stakers.push(msg.sender);
        _restake();
        stakes[msg.sender].amount += amount;
        emit Stake(msg.sender, amount);
    }

    function unstake(uint256 amount) public {
        if (amount > stakes[msg.sender].amount) revert NotEnoughStaked();
        _restake();
        stakes[msg.sender].amount -= amount;
        emit Unstake(msg.sender, amount);
        token.safeTransfer(msg.sender, amount);
    }

    function redeem(uint256 amount) public {
        uint256 score = amount * price;
        if (totalScore(msg.sender) < score) revert NotEnoughScore();
        stakes[msg.sender].redeemedScore += score;
        emit Redeem(msg.sender, amount);
        reward.transferManyFrom(address(this), msg.sender, amount);
    }

    // Administrative functions

    function withdraw(uint256 amount) public onlyRole(TREASURY_ROLE) {
        reward.transferManyFrom(address(this), msg.sender, amount);
    }

    function deposit(uint256 amount) public onlyRole(TREASURY_ROLE) {
        reward.transferManyFrom(msg.sender, address(this), amount);
    }

    function setPrice(uint256 newPrice) public onlyRole(TREASURY_ROLE) {
        price = newPrice;
    }
}
