pragma solidity >=0.7.0;

import "./EIPxxxInterface.sol";

library MaskMap {
    struct Pool {
        Mask[] _values;
        mapping(uint32 => uint256) _positions;
    }
    
    function get(Pool storage map, uint32 id) internal view returns (Mask memory) {
        uint256 idx = map._positions[id];
        if (idx == 0) {
            return Mask(0, 0, 0);
        } else {
            return map._values[idx-1];
        }
    }
    
    function set(Pool storage map, uint32 id, Mask memory mask) internal {
        uint256 idx = map._positions[id];
        if (idx == 0) {
            map._values.push(mask);
            map._positions[id] = map._values.length;
        } else {
            map._values[idx - 1] = mask;
        }
    }
    
    function del(Pool storage map, uint32 id) internal {
        uint256 idx = map._positions[id];
        if (idx != 0) {
            idx = idx - 1;
            map._values[idx] = map._values[map._values.length-1];
            map._values.pop();
            map._positions[id] = 0;
            
            if (map._values.length != 0) {
                map._positions[map._values[idx].id] = idx + 1;
            }
        }
    }
    
    function values(Pool storage map) internal view returns (Mask[] memory) {
        return map._values;
    }
    
    function keys(Pool storage map) internal view returns (uint32[] memory) {
        uint32[] memory ids = new uint32[](map._values.length);
        for (uint32 i = 0; i < map._values.length; i++) {
            ids[i] = map._values[i].id;
        }
        return ids;
    }
    
    function size(Pool storage map) internal view returns (uint256) {
        return map._values.length;
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

    function setMask(uint32 id, uint256 pattern) onlyOwner external {
        Mask memory m = Mask(id, pattern, keccak256(abi.encodePacked(pattern, blockhash(block.number))));
        masks.set(id, m);
    }

    function removeMask(uint32 id) onlyOwner external {
        masks.del(id);
    }

    function getMaskIDs() external override view returns (uint32[] memory) {
        return masks.keys();
    }

    function getMaskByID(uint32 id) external override view returns (Mask memory) {
        Mask memory m = masks.get(id);
        require(m.id != 0, "not found");
        return m;
    }

    function getMasks() external override view returns (Mask[] memory) {
        return masks.values();
    }

    function getNFTsBySender() external view returns (uint256[] memory) {
        return nfts.getNFTsByOwner(msg.sender);
    }

    function hash(bytes32 challengeNumber, uint256 nonce) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(challengeNumber, nonce)));
    }

    function mint(uint32 maskID, uint256 nonce) external override {

        Mask memory m = masks.get(maskID);
        require(m.id != 0, "mask not found");
        
        // Calculate NTF
        uint256 digest = hash(m.challengeNumber, nonce);

        // Ensure NFT is not mint already
        require(!nfts.isExists(digest), "already mint by other");

        // Match NFT in mask pool
        require(m.pattern | digest == m.pattern, "not match");

        // Issue NFT to worker
        nfts.issue(msg.sender, digest);

        // Emit event
        emit Mint(msg.sender, digest, m.pattern, m.challengeNumber);
    }
}
