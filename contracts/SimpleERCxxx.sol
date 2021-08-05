pragma solidity >=0.7.0;

import "./EIPxxxInterface.sol";

contract SimpleERCxxx is ERCxxx {

    uint256[] masks;
    bytes32 challengeNumber;

    address contractOwner;

    mapping(uint256 => address) public nftOwners;
    mapping(address => uint256[]) public owned;

    constructor(address owner) {
        contractOwner = owner;
        _updateChallengeNumber();
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner allowed");
        _;
    }

    function _updateChallengeNumber() internal {
        challengeNumber = keccak256(abi.encodePacked(challengeNumber, blockhash(block.number)));
        emit ChallengeNumberChanged(challengeNumber);
    }

    function addMask(uint256 mask) onlyOwner external override {
        masks.push(mask);

        emit MaskAdded(mask);

        _updateChallengeNumber();
    }

    function removeMask(uint32 index) onlyOwner external override {
        require(index >= 0, "index must greater than 0");
        require(index < masks.length, "index must lower than max-length");

        uint256 removed = masks[index];
        masks[index] = masks[masks.length-1];
        masks.pop();

        emit MaskRemoved(removed);

        _updateChallengeNumber();
    }

    function getMasks() external override view returns (uint256[] memory) {
        return masks;
    }

    function getUserAllNFT() external view returns (uint256[] memory) {
        return owned[msg.sender];
    }

    function getChallengeNumber() external override view returns (bytes32) {
        return challengeNumber;
    }

    function hash(uint256 nonce) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(challengeNumber, nonce)));
    }

    function reward(uint256 nft) internal {
        nftOwners[nft] = msg.sender;
        owned[msg.sender].push(nft);
    }

    function notMintByOther(uint256 nft) internal view returns (bool) {
        return nftOwners[nft] == address(0);
    }

    function matchMasks(uint256 nft) internal view returns (bool) {
        for (uint i=0; i < masks.length; i++) {
            if(masks[i] | nft == masks[i]) {
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
}
