//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title External Score Source
/// @dev This interface describes a contract that provides an arbitrary score for a given address
interface ScoreSource {
    /// @notice Get the total score of any address
    /// @param staker Address to query the score of
    /// @return score An arbitrary score of the address at current point in time
    function totalScore(address staker) external view returns (uint256);
}

/// @notice Allows transfering of multiple ERC721 tokens if they have the ERC721Enumerable extension
library ERC721Fungible {
    /// @notice Transfers a specific `amount` of ERC721Enumerable tokens regardless of their IDs
    /// @dev This loop can consume a lot of gas, it is used instead of providing the token IDs themselves
    /// @param token ERC721 token address
    /// @param from Holder of the tokens
    /// @param to Recipient of the tokens
    /// @param amount Amount of tokens to be transfered (not ID)
    function transferManyFrom(IERC721Enumerable token, address from, address to, uint256 amount) internal {
        uint256 balance = token.balanceOf(from);
        for (uint256 i = 0; i < amount; i++)
            token.transferFrom(from, to, token.tokenOfOwnerByIndex(from, --balance));
    }
}

/// @title Staking of ERC20 tokens to receive ERC721 tokens
/// @author Tadas Varanauskas <tadas@varanauskas.lt>
/// @notice Allows staking of ERC20 tokens over time and receiving ERC721 reward tokens based on the amount of tokens staked and time the tokens were staked for + external score
/// @dev Has an arbitrary score score provided by an external score source
contract StakeERC20ForERC721v2 is AccessControl, ERC721Holder, ScoreSource {
    using SafeERC20 for IERC20;
    using ERC721Fungible for IERC721Enumerable;

    // Errors

    /// @notice Token and Reward addresses cannot be the same
    error InvalidConstruction();
    /// @notice Trying to unstake more tokens than were staked for the address
    error NotEnoughStaked();
    /// @notice Trying to redeem more ERC721 tokens than allowed based on current score
    error NotEnoughScore();

    // Events
    /// @notice ERC20 tokens were staked
    /// @param staker Initial holder of the ERC20 tokens
    /// @param amount Number of the ERC20 tokens
    event Stake(address indexed staker, uint256 amount);
    /// @notice ERC20 tokens were unstaked
    /// @param staker Recipient of unstaked ERC20 tokens
    /// @param amount Number of the ERC20 tokens
    event Unstake(address indexed staker, uint256 amount);
    /// @notice ERC721 rewards were redeemed
    /// @param staker Recipient of ERC721 tokens
    /// @param amount Number of the ERC721 tokens
    event Redeem(address indexed staker, uint256 amount);

    // Structs

    struct Staking {
        uint256 previousInternalScore;
        uint256 redeemedScore;
        uint256 timestamp;
        uint256 amount;
    }

    // Constants

    /// @notice Role that allows withdrawing unnecessary ERC721 rewards, depositing more rewards for distribution and changing the score necessary to redeem 1 ERC721 token
    /// @dev This role is only granted for multisigs (for example Gnosis Multisig) and is a global administrative role
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");

    // Immutable config

    /// @notice ERC20 token that will be staked in the contract
    IERC20 public immutable token;
    /// @notice ERC721 token that will be distributed as reward for staking ERC20 tokens
    IERC721Enumerable public immutable reward;
    /// @notice External score source that provides an initial score for any address
    ScoreSource public immutable externalScores;

    // Mutable config

    /// @notice Price of one ERC721 token expressed in number of ERC20 tokens staked * seconds staked
    uint256 public price;

    // State

    /// @notice Stake information for all addresses
    mapping(address => Staking) public stakes;
    /// @notice List of stakers that have staked ERC20 tokens at any time
    address[] public stakers;

    // Constructor
    /// @param _token ERC20 token to be staked
    /// @param _reward ERC721 to be redeemed for staking _token
    /// @param _price Price of a single ERC721 token expressed in score
    /// @param _externalScores External score source for initial scores of each address
    constructor(IERC20 _token, IERC721Enumerable _reward, uint256 _price, ScoreSource _externalScores) {
        if (address(_token) == address(_reward)) revert InvalidConstruction();
        token = _token;
        reward = _reward;
        price = _price;
        externalScores = _externalScores;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(TREASURY_ROLE, msg.sender);
    }

    // Private views

    /// @dev Calculates curent internal score for any address that will be added to the external score
    function _totalInternalScore(address staker) private view returns (uint256) {
        uint256 duration = block.timestamp - stakes[staker].timestamp;
        uint256 currentScore = stakes[staker].amount * duration;
        return stakes[staker].previousInternalScore + currentScore;
    }

    // Public views

    /// @notice Calculates the total score of an address
    /// @dev Internal score is added to the external score to get the total score
    /// @param staker The address to calculate the score of
    /// @return score total score of the address expressed as number of ERC20 tokens staked * seconds staked + external score
    function totalScore(address staker) public view returns (uint256) {
        return _totalInternalScore(staker) + externalScores.totalScore(staker) - stakes[staker].redeemedScore;
    }

    // Private functions

    /// @dev Each time the amount the user has staked changes we need to keep track of the previous score and start calculating new score, to know the time each amount was staked for
    function _restake() private {
        stakes[msg.sender].previousInternalScore = _totalInternalScore(msg.sender);
        stakes[msg.sender].timestamp = block.timestamp;
    }

    // Staking functions
    
    /// @notice Stake ERC20 tokens in the contract
    /// @param amount Number of tokens to be staked
    function stake(uint256 amount) public {
        token.safeTransferFrom(msg.sender, address(this), amount);
        if (stakes[msg.sender].timestamp == 0) stakers.push(msg.sender);
        _restake();
        stakes[msg.sender].amount += amount;
        emit Stake(msg.sender, amount);
    }

    /// @notice Unstake previously staked ERC20 tokens in the contract
    /// @param amount Number of tokens to be unstaked
    function unstake(uint256 amount) public {
        if (amount > stakes[msg.sender].amount) revert NotEnoughStaked();
        _restake();
        stakes[msg.sender].amount -= amount;
        emit Unstake(msg.sender, amount);
        token.safeTransfer(msg.sender, amount);
    }

    /// @notice Redeem a number of ERC721 reward tokens for staking
    /// @param amount Number of tokens to be redeemed, must be smaller than totalScore / price
    function redeem(uint256 amount) public {
        uint256 score = amount * price;
        if (totalScore(msg.sender) < score) revert NotEnoughScore();
        stakes[msg.sender].redeemedScore += score;
        emit Redeem(msg.sender, amount);
        reward.transferManyFrom(address(this), msg.sender, amount);
    }

    // Administrative functions

    /// @notice Withdraw excess ERC721 reward tokens
    /// @param amount Number of tokens to be withdrawn
    function withdraw(uint256 amount) public onlyRole(TREASURY_ROLE) {
        reward.transferManyFrom(address(this), msg.sender, amount);
    }

    /// @notice Deposit ERC721 tokens to be distributed to stakers
    /// @param amount Number of tokens to be deposited
    function deposit(uint256 amount) public onlyRole(TREASURY_ROLE) {
        reward.transferManyFrom(msg.sender, address(this), amount);
    }

    /// @notice Update the price (in score) of one ERC721 token to be redeemed
    /// @param newPrice Updated price expressed as number of ERC20 tokens staked * seconds staked for
    function setPrice(uint256 newPrice) public onlyRole(TREASURY_ROLE) {
        price = newPrice;
    }
}
