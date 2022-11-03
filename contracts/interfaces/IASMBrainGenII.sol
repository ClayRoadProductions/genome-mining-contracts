// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "erc721a/contracts/extensions/IERC721AQueryable.sol";

interface IASMBrainGenII is IERC721AQueryable {
    event Minted(address indexed recipient, uint256 tokenId, bytes32 hash);
    event BaseURIUpdated(address indexed operator, string newbaseURI);

    error InvalidMultisig();
    error InvalidRecipient();
    error InvalidMinter();
    error InvalidAdmin();
    error TokenNotExist();

    /**
     * @notice Get the total minted count for `owner`
     * @param owner The wallet address
     * @return The total minted count
     */
    function numberMinted(address owner) external view returns (uint256);

    /**
     * @notice cidv0 is used to convert sha256 hash to cid(v0) used by IPFS.
     * @param sha256Hash_ sha256 hash generated by anything.
     * @return IPFS cid that meets the version0 specification.
     */
    function cidv0(bytes32 sha256Hash_) external pure returns (string memory);

    /**
     * @notice Mint Gen II Brains to `recipient` with the IPFS hashes
     * @dev This function can only be called from contracts or wallets with MINTER_ROLE
     * @param recipient The wallet address used for minting
     * @param hashes A list of IPFS Multihash digests. Each Gen II Brain should have an unique token hash
     */
    function mint(address recipient, bytes32[] calldata hashes) external;

    /**
     * @notice Update baseURI to `_newBaseURI`
     * @dev This function can only to called from contracts or wallets with ADMIN_ROLE
     * @param _newBaseURI The new baseURI to update
     */
    function updateBaseURI(string calldata _newBaseURI) external;

    /**
     * @notice Add a new minter address (contract or wallet)
     * @dev This function can only to called from contracts or wallets with ADMIN_ROLE
     * @param _newMinter The new minted address to be added
     */
    function addMinter(address _newMinter) external;

    /**
     * @notice Remove an existing minter
     * @dev This function can only to called from contracts or wallets with ADMIN_ROLE
     * @param _minter The minter address to be removed
     */
    function removeMinter(address _minter) external;

    /**
     * @notice Add admin address (contract or wallet)
     * @dev This function can only to called from contracts or wallets with ADMIN_ROLE
     * @param _newAdmin The new admin address to be granted
     */
    function addAdmin(address _newAdmin) external;

    /**
     * @notice Remove admin address
     * @dev This function can only to called from contracts or wallets with ADMIN_ROLE
     * @param _admin The new admin address to be removed
     */
    function removeAdmin(address _admin) external;
}