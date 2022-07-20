// SPDX-License-Identifier: MIT
// ATSUSHI MANDAI CRDIT Contracts

pragma solidity ^0.8.0;

/**
 * @dev Interface of the CRDIT
 */
interface ICRDIT {

    /**
     * @dev Returns the current tax rate.
     */
    function tax() external view returns(uint8);

    /**
     * @dev Returns the mintAddLimit.
     */
    function mintAddLimit() external view returns(uint8);

    /**
     * @dev Returns the sum of mint limits.
     */
    function mintLimitSum() external view returns(uint);

    /**
     * @dev Returns the mint limit of an address.
     */
    function mintLimitOf(address _address) external view returns(uint);

    /**
     * @dev Returns whether an address is an issuer or not.
     */
    function isIssuer(address _address) external view returns(bool);

    /**
     * @dev Returns whether an address is in the blacklist or not.
     */
    function blackList(address _address) external view returns(bool);

    /**
     * @dev Returns the amount after deducting tax.
     */
    function checkTax(uint _amount) external view returns(uint);

    /**
     * @dev Changes the tax rate of CRDIT.
     */
    function changeTax(uint8 _newTax) external returns(bool);

    /**
     * @dev Changes the mintAddLimit.
     */
    function changeMintAddLimit(uint8 _newLimit) external returns(bool);

    /**
     * @dev Changes the mint limit of an address.
     */
    function changeMintLimit(address _address, uint _amount) external returns(bool);

    /**
     * @dev Changes the mint limit of an address.
     */
    function changeBlackList(address _address, bool _bool) external returns(bool);

    /**
     * @dev Lets an issuer mint new CRDIT within its limit.
     */
    function issuerMint(address _to, uint256 _amount) external returns(bool);

    /**
     * @dev Lets an issuer burn CRDIT to recover its limit.
     */
    function issuerBurn(uint256 _amount) external returns(bool);

    /**
     * @dev Burns CRDIT.
     */
    function burn(uint256 amount) external;

    /**
     * @dev Burns CRDIT from its owner.
     */
    function burnFrom(address account, uint256 amount) external;

    /**
     * @dev Returns the cap of the token.
     */
    function cap() external view returns (uint256);
}