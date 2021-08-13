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
