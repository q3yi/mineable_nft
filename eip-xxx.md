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

- [ ] 只提供一个`getMasks`的接口还是提供`getMaskByID`+`getMaskIDs`两个
      接口
	  
  只用一个接口`getMasks`返回所有的mask，好处是一步到位，坏处是每次都更
  新全部，如果大部分mask比较稳定就比较浪费。
  
  用`getMaskByID`+`getMaskIDs`两个接口的话比较利于用户更小范围的控制，
  比如他只想挖特定mask下的NFT就只需要更新相应mask就好了。

- [ ] maskID暂时设置的type为uint32，或许可以改成uint64或uint256？

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

// @notice defination of mask object
struct Mask {
    uint32 id;
    uint256 pattern;
    bytes32 challengeNumber;
}
    
    
/// @title ERC-xxx Mineable Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-xxx
interface ERCxxx /* is ERC721 */ {

    /// @notice Get all masks' id as a list
    /// @return list of mask id
    function getMaskIDs() external view returns (uint32[] memory);
    
    /// @notice Get mask object by given id
    /// @return mask object
    function getMaskByID(uint32 id) external view returns (Mask memory);

    /// @notice Get all masks currently available for mining
    /// @return list of available mask
    function getMasks() external view returns (Mask[] memory);

    /// @notice The mint operation
    function mint(uint32 maskID, uint256 nonce) external;

    /// @dev This emits when a new nft has been assigned to worker
    event Mint(address indexed from, uint256 nft, uint256 mask, bytes32 challengeNumber);
}
```

### Mask

```solidity
struct Mask {
    uint32 id;
    uint256 pattern;
    bytes32 challengeNumber;
}

Mask[] internal masks
```

`Mask`代表了一个可供挖掘的NFT模式，包含三个字段：

- `uint32 id`

	mask的唯一id，用来表示相应的一组可供挖掘的NFT模式。
	
- `uint256 pattern`

	表示用户提供的nonce经过计算的hash应当符合的模式。
	
- `bytes32 challengenumber`

	为了确保矿工无法提前计算符合某种特定模式的NFT，在计算hash值是需要
	用户提供的nonce+和mask中对应的challengeNumber一起之后计算。
	challengeNumber应该以一种特定的规则更新，本接口没有做特定的规约，
	实际的合约创建者应当自行规定，可以根据规则自动更新，也可以由合约所
	有者手动更新。

### getMaskIDs

返回目前所有的mask的id。没有任何mask时返回空数组。

```solidity
function getMaskIDs() external view returns (uint32[] memory);
```

### getMaskByID

根据mask id获取对应的mask对象。不存在时抛出异常。

```solidity
function getMaskByID(uint32 id) external view returns (Mask memory);
```

### getMasks

返回所有的mask对象数组，不存在时返回空数组。

```solidity
function getMasks() external view returns (Mask[] memory);
```

### mint

挖矿的接口，提供mask id和用户计算出的nonce，合约验证成功则发放nft，否
则函数抛出异常。
	
```solidity
mint(uint32 maskID, uint256 nonce) external;
```

### Mint

产生一个新NFT时触发的事件。

- mask为产生nft时使用的mask pattern

- challengeNumber时使用的mask challengeNumber

```solidity
event Mint(address indexed from, uint256 nft, uint256 mask, bytes32 challengeNumber);
```

## Mint operation

```solidity
function mint(uint32 maskID, uint256 nonce) external override {

	Mask memory m = masks.get(maskID);
	require(m.id != 0, "mask not found");
        
	// Calculate NTF
	uint256 digest = uint256(keccak256(abi.encodePacked(m.challengeNumber, nonce)));

	// Ensure NFT is not mint already
	require(!nfts.isExists(digest), "already mint by other");

	// Test if digest match target mask pattern
	require(m.pattern | digest == m.pattern, "not match");

	// Issue NFT to worker
	nfts.issue(msg.sender, digest);

	// Emit event
	emit Mint(msg.sender, digest, m.pattern, m.challengeNumber);
}
```

## Example mining function

```python3
Mask = namedtuple("Mask", "id pattern challenge_number")

masks = [
    Mask(1, 2**240-1, "5687febf410591227276fb47b859d185cc30cbfd06811a2cd9cfd17d041af1af")
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
                return m.id, nonce, hash_value.hexdigest()
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
