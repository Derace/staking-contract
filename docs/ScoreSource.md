# ScoreSource



> External Score Source



*This interface describes a contract that provides an arbitrary score for a given address*

## Methods

### totalScore

```solidity
function totalScore(address staker) external view returns (uint256)
```

Get the total score of any address



#### Parameters

| Name | Type | Description |
|---|---|---|
| staker | address | Address to query the score of |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | score An arbitrary score of the address at current point in time |




