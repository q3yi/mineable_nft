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
