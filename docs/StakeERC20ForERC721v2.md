# StakeERC20ForERC721v2

*Tadas Varanauskas &lt;tadas@varanauskas.lt&gt;*

> Staking of ERC20 tokens to receive ERC721 tokens

Allows staking of ERC20 tokens over time and receiving ERC721 reward tokens based on the amount of tokens staked and time the tokens were staked for + external score

*Has an arbitrary score score provided by an external score source*

## Methods

### DEFAULT_ADMIN_ROLE

```solidity
function DEFAULT_ADMIN_ROLE() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### TREASURY_ROLE

```solidity
function TREASURY_ROLE() external view returns (bytes32)
```

Role that allows withdrawing unnecessary ERC721 rewards, depositing more rewards for distribution and changing the score necessary to redeem 1 ERC721 token

*This role is only granted for multisigs (for example Gnosis Multisig) and is a global administrative role*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### deposit

```solidity
function deposit(uint256 amount) external nonpayable
```

Deposit ERC721 tokens to be distributed to stakers



#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | Number of tokens to be deposited |

### externalScores

```solidity
function externalScores() external view returns (contract ScoreSource)
```

External score source that provides an initial score for any address




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract ScoreSource | undefined |

### getRoleAdmin

```solidity
function getRoleAdmin(bytes32 role) external view returns (bytes32)
```



*Returns the admin role that controls `role`. See {grantRole} and {revokeRole}. To change a role&#39;s admin, use {_setRoleAdmin}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### grantRole

```solidity
function grantRole(bytes32 role, address account) external nonpayable
```



*Grants `role` to `account`. If `account` had not been already granted `role`, emits a {RoleGranted} event. Requirements: - the caller must have ``role``&#39;s admin role.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined |
| account | address | undefined |

### hasRole

```solidity
function hasRole(bytes32 role, address account) external view returns (bool)
```



*Returns `true` if `account` has been granted `role`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined |
| account | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### onERC721Received

```solidity
function onERC721Received(address, address, uint256, bytes) external nonpayable returns (bytes4)
```



*See {IERC721Receiver-onERC721Received}. Always returns `IERC721Receiver.onERC721Received.selector`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | address | undefined |
| _2 | uint256 | undefined |
| _3 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4 | undefined |

### price

```solidity
function price() external view returns (uint256)
```

Price of one ERC721 token expressed in number of ERC20 tokens staked * seconds staked




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### redeem

```solidity
function redeem(uint256 amount) external nonpayable
```

Redeem a number of ERC721 reward tokens for staking



#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | Number of tokens to be redeemed, must be smaller than totalScore / price |

### renounceRole

```solidity
function renounceRole(bytes32 role, address account) external nonpayable
```



*Revokes `role` from the calling account. Roles are often managed via {grantRole} and {revokeRole}: this function&#39;s purpose is to provide a mechanism for accounts to lose their privileges if they are compromised (such as when a trusted device is misplaced). If the calling account had been revoked `role`, emits a {RoleRevoked} event. Requirements: - the caller must be `account`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined |
| account | address | undefined |

### revokeRole

```solidity
function revokeRole(bytes32 role, address account) external nonpayable
```



*Revokes `role` from `account`. If `account` had been granted `role`, emits a {RoleRevoked} event. Requirements: - the caller must have ``role``&#39;s admin role.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined |
| account | address | undefined |

### reward

```solidity
function reward() external view returns (contract IERC721Enumerable)
```

ERC721 token that will be distributed as reward for staking ERC20 tokens




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IERC721Enumerable | undefined |

### setPrice

```solidity
function setPrice(uint256 newPrice) external nonpayable
```

Update the price (in score) of one ERC721 token to be redeemed



#### Parameters

| Name | Type | Description |
|---|---|---|
| newPrice | uint256 | Updated price expressed as number of ERC20 tokens staked * seconds staked for |

### stake

```solidity
function stake(uint256 amount) external nonpayable
```

Stake ERC20 tokens in the contract



#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | Number of tokens to be staked |

### stakers

```solidity
function stakers(uint256) external view returns (address)
```

List of stakers that have staked ERC20 tokens at any time



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### stakes

```solidity
function stakes(address) external view returns (uint256 previousInternalScore, uint256 redeemedScore, uint256 timestamp, uint256 amount)
```

Stake information for all addresses



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| previousInternalScore | uint256 | undefined |
| redeemedScore | uint256 | undefined |
| timestamp | uint256 | undefined |
| amount | uint256 | undefined |

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool)
```



*See {IERC165-supportsInterface}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| interfaceId | bytes4 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### token

```solidity
function token() external view returns (contract IERC20)
```

ERC20 token that will be staked in the contract




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IERC20 | undefined |

### totalScore

```solidity
function totalScore(address staker) external view returns (uint256)
```

Calculates the total score of an address

*Internal score is added to the external score to get the total score*

#### Parameters

| Name | Type | Description |
|---|---|---|
| staker | address | The address to calculate the score of |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | score total score of the address expressed as number of ERC20 tokens staked * seconds staked + external score |

### unstake

```solidity
function unstake(uint256 amount) external nonpayable
```

Unstake previously staked ERC20 tokens in the contract



#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | Number of tokens to be unstaked |

### withdraw

```solidity
function withdraw(uint256 amount) external nonpayable
```

Withdraw excess ERC721 reward tokens



#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | Number of tokens to be withdrawn |



## Events

### Redeem

```solidity
event Redeem(address indexed staker, uint256 amount)
```

ERC721 rewards were redeemed



#### Parameters

| Name | Type | Description |
|---|---|---|
| staker `indexed` | address | Recipient of ERC721 tokens |
| amount  | uint256 | Number of the ERC721 tokens |

### RoleAdminChanged

```solidity
event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| role `indexed` | bytes32 | undefined |
| previousAdminRole `indexed` | bytes32 | undefined |
| newAdminRole `indexed` | bytes32 | undefined |

### RoleGranted

```solidity
event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| role `indexed` | bytes32 | undefined |
| account `indexed` | address | undefined |
| sender `indexed` | address | undefined |

### RoleRevoked

```solidity
event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| role `indexed` | bytes32 | undefined |
| account `indexed` | address | undefined |
| sender `indexed` | address | undefined |

### Stake

```solidity
event Stake(address indexed staker, uint256 amount)
```

ERC20 tokens were staked



#### Parameters

| Name | Type | Description |
|---|---|---|
| staker `indexed` | address | Initial holder of the ERC20 tokens |
| amount  | uint256 | Number of the ERC20 tokens |

### Unstake

```solidity
event Unstake(address indexed staker, uint256 amount)
```

ERC20 tokens were unstaked



#### Parameters

| Name | Type | Description |
|---|---|---|
| staker `indexed` | address | Recipient of unstaked ERC20 tokens |
| amount  | uint256 | Number of the ERC20 tokens |



## Errors

### InvalidConstruction

```solidity
error InvalidConstruction()
```

Token and Reward addresses cannot be the same




### NotEnoughScore

```solidity
error NotEnoughScore()
```

Trying to redeem more ERC721 tokens than allowed based on current score




### NotEnoughStaked

```solidity
error NotEnoughStaked()
```

Trying to unstake more tokens than were staked for the address





