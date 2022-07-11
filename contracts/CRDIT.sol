// SPDX-License-Identifier: MIT
// ATSUSHI MANDAI CRDIT Contracts

pragma solidity ^0.8.0;

import "./token/ERC20/extensions/ERC20Burnable.sol";
import "./access/Ownable.sol";

/// @title CRDIT
/// @author Atsushi Mandai
/// @notice Basic functions of the ERC20 Token CRDIT.
contract CRDIT is ERC20Burnable, Ownable {

    /**
    *
    *
    * @dev variables
    *
    *
    */

    /** 
    * @dev ERC20 Token "Credit" (ticker "CRDIT") has max supply of 100,000,000.
    * Founder takes 10% of the max supply as an incentive for him and early collaborators.
    * All the remaining tokens will be minted through a non-arbitrary algorithm.
    */
    constructor () ERC20 ("Credit", "CRDIT") ERC20Capped(100000000 * (10**uint256(18)))
    {
        ERC20._mint(_msgSender(),20000000 * (10**uint256(18)));
    }

    /**
    * @dev When a non-contract address sends this token, the sender will have to pay tax.
    * The amount of tax is _tax / 10000, and it will be burned from sender's balance.
    */
    uint8 private _tax = 5;

    /**
    * @dev Mint limit for an address must be under {totalSupply * _mintAddLimit / 100}.
    */
    uint8 private _mintAddLimit = 5;
    
    /**
    * @dev Keeps the mint limit approved for each address.
    */
    mapping(address => uint256) private _addressToMintLimit;


    /**
    *
    *
    * @dev public view functions
    *
    *
    */

    /**
    * @dev Returns _salesTax.
    */
    function tax() public view returns(uint8) {
        return _tax;
    }

    /**
    * @dev Returns _mintAddLimit.
    */
    function mintAddLimit() public view returns(uint8) {
        return _mintAddLimit;
    }

    /**
    * @dev Returns mint limit of an address.
    */
    function mintLimitOf(address _address) public view returns(uint) {
        return _addressToMintLimit[_address];
    }

    /**
    * @dev Returns the amount of tax required.
    */
    function checkTax(uint _amount) public view returns(uint) {
        return _amount * _tax / 10000;
    }


    /**
    *
    *
    * @dev public governance functions
    *
    *
    */

    /**
    * @dev Sets new value for _tax.
    */
    function changeTax(uint8 _newTax) public onlyOwner returns(bool) {
        _tax = _newTax;
        return true;
    }

    /**
    * @dev Sets new value for _mintAddLimit.
    */
    function changeMintAddLimit(uint8 _newLimit) public onlyOwner returns(bool) {
        _mintAddLimit = _newLimit;
        return true;
    }

    /**
    * @dev Sets new mint limit to an address.
    */
    function changeMintLimit(address _address, uint _amount) public onlyOwner returns(bool) {
        require(_amount < totalSupply() * _mintAddLimit / 100);
        require(_amount <= cap() - totalSupply());
        _addressToMintLimit[_address] = _amount;
        return true;
    }


    /**
    *
    *
    * @dev public utility functions
    *
    *
    */

    /**
    * @dev override transfer() with tax.
    */
    function transfer(address _to, uint256 _amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _payTax(owner, _amount);
        _transfer(owner, _to, _amount);
        return true;
    }

    /**
    * @dev override transferFrom() with tax.
    */
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(_from, spender, _amount + (_amount * _tax / 10000));
        _payTax(_from, _amount);
        _transfer(_from, _to, _amount);
        return true;
    }

    /**
    * @dev Lets an address mint CRDIT within its limit.
    */
    function publicMint(address _to, uint256 _amount) public returns(bool) {
        require(_amount <= _addressToMintLimit[_msgSender()], "This contract has reached its mint limit.");
        _addressToMintLimit[_msgSender()] = _addressToMintLimit[_msgSender()] - _amount;
        _mint(_to, _amount);
        return true;
    }


    /**
    *
    *
    * @dev private functions
    *
    *
    */

    /**
    * @dev Checks if the sender's address is a contract or not.
    * If it isn't, then the tax will be payed from the sender's balance.
    */
    function _payTax(address _from, uint _amount) private {
        if(_isContract(_from) == false) {
            uint taxAmount = _amount * _tax / 10000;
            require(balanceOf(_from) >= taxAmount + _amount, "Not enough balance for tax.");
            _burn(_from, taxAmount);
        }
    }

    function _isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.
        return account.code.length > 0;
    }

}