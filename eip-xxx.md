---
eip:
title:
author: Jeff Huang<jeffishjeff@gmail.com>, Qing Yi<qingyi.tss@gmail.com>
discussions-to:
status: Draft
type: Standards Track
category: ERC
created: 2021-7-16
---

# 目前还剩下的问题

- [ ] 目前challengeNumber的类型为bytes32，如果需要支持类似
      `challengeNumber-0,challengeNumber-1`这样来区分的话，需要把类型
      定义为bytes64以留下足够的空间，并且需要额外的说明。

- [ ] mask是否有更贴切的名字？

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

本接口是EIP-721接口的拓展接口，只负责解决NFT如何产生的问题，所有NFT交
换功能应当遵循EIP-721接口的规范实现。

## Interface

```sodility
pragma solidity >=0.7.0;

/// @title ERC-xxx Mineable Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-xxx
interface ERCxxx /* is ERC721 */ {

    /// @notice Get all masks currently available for mining
    /// @return masks challengeNumbers pairs
    function getMasks() external view returns (uint256[] memory masks, bytes32[] memory challengeNumbers);

    /// @notice The mint operation
    function mint(bytes32 challengeNumber, uint256 nonce) external;

    /// @dev This emits when a new nft has been assigned to worker
    event Mint(address indexed from, uint256 nft, uint256 mask, bytes32 challengeNumber);
}
```

### getMasks

返回所有mask和对应challengeNumber的两个数组。两个数组的长度应该相同，
即一个mask对应一个challengeNumber，并且challengeNumber不能重复（在挖矿
时我们用challengeNumber来作为唯一表示来查找对应的mask）。不存在mask时，
应当返回两个空数组。

```solidity
function getMasks() external view returns (uint256[] memory masks, bytes32[] memory challengeNumbers);
```

### mint

挖矿的接口，提供challengeNumber和用户计算出的nonce，合约验证成功则发放nft，否
则函数抛出异常。
	
```solidity
mint(bytes32 challengeNumber, uint256 nonce) external;
```

### Mint

产生一个新NFT时触发的事件。

- mask为计算nft时使用的mask

- challengeNumber为计算nft时使用的challengeNumber

```solidity
event Mint(address indexed from, uint256 nft, uint256 mask, bytes32 challengeNumber);
```

## Mint operation

```solidity
function mint(bytes32 challengeNumber, uint256 nonce) external override {

	uint256 m = masks.get(challengeNumber);
	require(m != 0, "mask not found");
        
	// Calculate NTF
	uint256 digest = hash(challengeNumber, nonce);

	// Ensure NFT is not mint already
	require(!nfts.isExists(digest), "already mint by other");

	// Match NFT in mask pool
	require(m | digest == m, "not match");

	// Issue NFT to worker
	nfts.issue(msg.sender, digest);

	// Emit event
	emit Mint(msg.sender, digest, m, challengeNumber);
}
```

## Example mining function

```python3
Mask = namedtuple("Mask", "pattern challenge_number")

masks = [
    Mask(2**240-1, "5687febf410591227276fb47b859d185cc30cbfd06811a2cd9cfd17d041af1af")
]

def mine():

    while True:
        nonce = random.getrandbits(256)

        for m in masks:
            challenge_number = binascii.unhexlify(m.challenge_number)
            raw = challenge_number + nonce.to_bytes(32, 'big')

            hash_value = sha3.keccak_256(raw)
            digest_number = int.from_bytes(hash_value.digest(), 'big')

            if m.pattern | digest_number == m.pattern:
                return m.challenge_number, nonce, hash_value.hexdigest()

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
