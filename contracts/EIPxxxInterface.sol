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
    function mint(uint256 nonce) external;

    /// @dev This emits when new mask add to current pool by whoever has privilege
    event MaskAdded(uint256 mask);

    /// @dev This emits when a mask has been removed from pool by whoever has privilege
    event MaskRemoved(uint256 mask);

    /// @dev This emits when new challenge number has been generated
    event ChallengeNumberChanged(bytes32 challengeNumber);

    /// @dev This emits when a new nft has been assigned to worker
    event Mint(address indexed from, uint256 nft, bytes32 challengeNumber);
}
