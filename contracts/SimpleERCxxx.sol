pragma solidity >=0.7.0;

import "./EIPxxxInterface.sol";

library MaskMap {
    struct Pool {
        bytes32[] _challengeNumbers;
        mapping(bytes32 => uint256) _masks;
    }
    
    function get(Pool storage map, bytes32 challengeNumber) internal view returns (uint256) {
        return map._masks[challengeNumber];
    }
    
    function set(Pool storage map, bytes32 challengeNumber, uint256 mask) internal {
        if (map._masks[challengeNumber] == 0 ) {
            map._challengeNumbers.push(challengeNumber);
        }
        
        map._masks[challengeNumber] = mask;
    }
    
    function del(Pool storage map, bytes32 challengeNumber) internal {
        map._masks[challengeNumber] = 0;
        for (uint32 i = 0; i < map._challengeNumbers.length; i++ ) {
            if (map._challengeNumbers[i] == challengeNumber) {
                map._challengeNumbers[i] = map._challengeNumbers[map._challengeNumbers.length - 1];
                map._challengeNumbers.pop();
            }
        }
    }
    
    function challengeNumbers(Pool storage map) internal view returns (bytes32[] memory) {
        return map._challengeNumbers;
    }
    
    function masks(Pool storage map) internal view returns (uint256[] memory) {
        uint256[] memory mask = new uint256[](map._challengeNumbers.length);
        for (uint32 i = 0; i < map._challengeNumbers.length; i++) {
            mask[i] = map._masks[map._challengeNumbers[i]];
        }
        return mask;
    }
    
}

library NFTStorage {
    struct NFT {
        mapping(uint256 => address) _owners;
        mapping(address => uint256[]) _owned;
    }
    
    function getOwnerByNFT(NFT storage pool, uint256 nft) internal view returns (address) {
        return pool._owners[nft];
    }
    
    function getNFTsByOwner(NFT storage pool, address owner) internal view returns (uint256[] memory) {
        return pool._owned[owner];
    }
    
    function issue(NFT storage pool, address owner, uint256 nft) internal {
        pool._owners[nft] = owner;
        pool._owned[owner].push(nft);
    }
    
    function isExists(NFT storage pool, uint256 nft) internal view returns (bool) {
        return pool._owners[nft] != address(0);
    }
    
}

contract SimpleERCxxx is ERCxxx {
    
    using MaskMap for MaskMap.Pool;
    using NFTStorage for NFTStorage.NFT;
    
    MaskMap.Pool private masks;
    NFTStorage.NFT private nfts;

    address contractOwner;

    constructor() {
        contractOwner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner allowed");
        _;
    }

    function setMask(uint256 mask) onlyOwner external {
        bytes32 challengeNumber = keccak256(abi.encodePacked(mask, blockhash(block.number)));
        masks.set(challengeNumber, mask);
    }

    function removeMask(bytes32 challengeNumber) onlyOwner external {
        masks.del(challengeNumber);
    }


    function getMasks() external override view returns (uint256[] memory, bytes32[] memory) {
        return (masks.masks(), masks.challengeNumbers());
    }

    function getNFTsBySender() external view returns (uint256[] memory) {
        return nfts.getNFTsByOwner(msg.sender);
    }

    function hash(bytes32 challengeNumber, uint256 nonce) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(challengeNumber, nonce)));
    }

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
}
