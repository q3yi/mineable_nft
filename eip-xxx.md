| eip | title | author                                                           | discussions-to | status | type            | category | created   |
|     |       | Jeff Huang<jeffishjeff@gmail.com>, Qing Yi<qingyi.tss@gmail.com> |                | Draft  | Standards Track | ERC      | 2021-7-16 |

# 目前还剩下的问题

- [ ] 是否支持批量的更改masks

  目前的方案是不支持，现在修改mask的接口addMask，removeMask都是一个一
  个的增删，这样可以确保每次操作产生的event比较少，当然如果支持批量操
  作的话也可以在一个修改产生event中包含多个mask，`event
  MasksChanged(uint256[] memory masks)`, 但目前不确定memory类型的event
  参数有什么印象。

- [ ] challengeNumber是否应该规定一个自动修改的规则

  为了保证不会有人提前算好符合某种格式的hash，每次在计算hash的时候要包
  含用户提供的nonce，和合约自身维护的challengeNumber，这个
  challengeNumber需要定期的更换，但现在没有定义更换的逻辑，我倾向于这
  段逻辑个合约的实现者决定

- [ ] 没有问题的话需要翻译成英文

# Simple Summary

在合约所有者控制下，以PoW的方式挖掘NFT的接口。

# Abstract

此接口是EIP-721的拓展，我们认为EIP-721用来表示某种NFT的tokenID本身就是
一种NFT，表示用户在当前智能合约中对某个特定ID的所有权。在此基础上我们
提出一种由合约所有者可控的基于PoW的挖矿接口，用以向所有合约的参与者公
平的提供NFT。

# Motivation

EIP-721中对NFT的概念和流通交换过程进行的定义和规范，在讨论NFT的应用时，
我们认为NFT在数字财产的应用方面有天生的优势，EIP-721中所用来表示NFT的
tokenID本身就是一种数字财产，表示特定用户在合约中对某个特定ID的所有权。
当然这种数字资产显然需要某种方式来产生，而EIP-721中并没有对NFT如何产生
进行讨论，这里我们参考了EIP-918的思想，提出了一种可以被合约所有者控制，
对所有的参与者公平分配NFT的接口。

# Sepcification

本接口是EIP-721接口的拓展接口，只负责解决NFT如何产生的问题，在实际的合
约中应该需要包含NFT的交换相关功能，也就是说实际合约应当同时实现EIP-721
中的相关接口。

## Interface

```sodility
pragma solidity >=0.7.0;

/// @title ERC-xxx Mineable Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-xxx
interface ERCxxx /* is ERC721 */ {

    /// @notice Add new mask to current pool
    /// @param mask owner defined mask
    function addMask(uint256 mask) external;

    /// @notice Remove a mask from current pool
    /// @param index of mask that will be removed
    function removeMask(uint32 index) external;

    /// @notice Get all masks currently available for mining
    /// @return list of available mask
    function getMasks() external view returns (uint256[] memory);

    /// @notice Get current challenge number
    /// @return current challenge number
    function getChallengeNumber() external view returns (bytes32);

    /// @notice The mint operation
    /// @param nonce
    /// @return flag indicating a successful hash digest verification
    function mint(uint256 nonce) external returns (bool);

    /// @dev This emits when new mask add to current pool by whoever has privilege
    event MaskAdded(uint256 mask);

    /// @dev This emits when a mask has been removed from pool by whoever has privilege
    event MaskRemoved(uint256 mask);

    /// @dev This emits when new challenge number has been generated
    event ChallengeNumberChanged(bytes32 challengeNumber);

    /// @dev This emits when a new nft has been assigned to worker
    event Mint(address indexed from, uint256 nft, bytes32 challengeNumber);
}
```

## Abstract Contract(optional)

所有实现ERCxxx接口的合约都建议维护一下两个内部变量，以保证合约的正常运
行。

### challengeNumber

为了确保矿工无法提前计算符合某种特定模式的NFT，在计算hash值是需要用户
提供的nonce+当前合约中的challengeNumber一起之后计算。challengeNumber应
该以一种特定的规则更新，本接口没有做特定的规约，实际的合约创建者应当自
行规定，可以根据规则自动更新，也可以由合约所有者手动更新。这里的例子
（TODO：添加例子连接）提供了一种在增加或删除mask时自动更新的机制。

```solidity
bytes32 internal challengeNumber;
```

另外需要注意的是，challengeNumber在合约部署或者在正式挖矿启动时，应当
确保challengeNumber被正确的赋值，不应该为空值。

### nftOwners

确保每个NFT只有一个并且只能被挖掘一次。

```solidity
mapping(uint256 => address) public nftOwners;
```

### masks

所有目前可供挖掘的NFT的模式的集合，用户提供的nonce和合约的
challengeNumber结合在一起计算出的hash为一个可以分配给矿工的NFT，如果
hash满足masks中某一个mask所规定的模式，并且在之前没有被任何人挖到过，
则挖矿成功，否者挖矿失败。

```solidity
uint256[] internal masks;
```

和challengeNumber相同，masks在正式挖矿开始时，应当确保被正确的赋值，否
者挖矿的验证机制应该永远失败。

## Mint operation

```solidity
function hash(uint256 nonce) internal returns (uint256) {
    return uint256(keccak256(abi.encodePacked(challengeNumber, msg.sender, nonce)));
}

function matchMasks(uint256 nft) internal returns (bool) {
    for (uint i=0; i < masks.length; i++) {
        if(masks[i] | digest == masks[i]) {
            return true;
        }
    }
    return false;
}

function mint(uint256 nonce) external override {
    // Calculate NTF
    uint256 digest = hash(nonce);

    // Ensure NFT is not mint already
    require(notMintByOther(digest), "already mint by other");

    // Match NFT in mask pool
    require(matchMasks(digest), "not match any masks");

    // Issue NFT to worker
    reward(digest);

    // Emit event
    emit Mint(msg.sender, digest, challengeNumber);
}
```

## Example mining function

```python3
def mine():

    while True:
        nonce = random.getrandbits(256)
        raw = challenge_number + nonce.to_bytes(32, 'big')

        hash_value = sha3.keccak_256(raw)
        digest_number = int.from_bytes(hash_value.digest(), 'big')

        for m in masks:
            if m | digest_number == m:
                return nonce, hash_value.hexdigest()
```

# Rationable

# Backwards Compatibility

# Test Cases

# Implementation

Simple Example: [https://github.com/tsingyi/mineable_nft/blob/main/contracts/SimpleERCxxx.sol](https://github.com/tsingyi/mineable_nft/blob/main/contracts/SimpleERCxxx.sol)

# References

1. [ERC-721](https://eips.ethereum.org/EIPS/eip-721) Non-Fungible Token Standard
2. [ERC-918](https://eips.ethereum.org/EIPS/eip-918) Mineable Token Standard

# Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
