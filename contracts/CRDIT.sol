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
    * Founder takes 20% of the max supply as an incentive for him and early collaborators.
    * All the remaining tokens will be minted through a non-arbitrary algorithm.
    */
    constructor () ERC20 ("Credit", "CRDIT") ERC20Capped(100000000 * (10**uint256(18)))
    {
        ERC20._mint(_msgSender(),20000000 * (10**uint256(18)));
    }

    /**
    * @dev When a non-contract address recieves this token, the reciever pays tax.
    * The amount of tax is _tax / 10000, and it will be burned during the transaction.
    */
    uint8 private _tax = 5;

    /**
    * @dev Mint limit for an address must be under {totalSupply * _mintAddLimit / 100}.
    */
    uint8 private _mintAddLimit = 5;

    /**
    * @dev Sum of all the mint limits.
    */
    uint256 private _mintLimitSum;

    /**
    * @dev Keeps the address of issuers.
    */
    mapping(address => bool) private _issuers;
    
    /**
    * @dev Keeps the mint limit approved for each address.
    */
    mapping(address => uint256) private _addressToMintLimit;

    /**
    * @dev Keeps the black listed addresses.
    */
    mapping(address => bool) private _blackList; 


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
    * @dev Returns _mintLimitSum.
    */
    function mintLimitSum() public view returns(uint256) {
        return _mintLimitSum;
    }

    /**
    * @dev Returns mint limit of an address.
    */
    function mintLimitOf(address _address) public view returns(uint256) {
        return _addressToMintLimit[_address];
    }

    /**
    * @dev Returns whether the address is an issuer or not.
    */
    function isIssuer(address _address) public view returns(bool) {
        return _issuers[_address];
    }

    /**
    * @dev Returns whether the address is in the _blackList or not.
    */
    function blackList(address _address) public view returns(bool) {
        return _blackList[_address];
    }

    /**
    * @dev Returns the amount of tax.
    */
    function checkTax(uint256 _amount) public view returns(uint256) {
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
    * @dev Sets new mint limit to an address. If the new mint limit is 0, sets false for _issuers[_address].
    */
    function changeMintLimit(address _address, uint256 _amount) public onlyOwner returns(bool) {
        require(_amount < totalSupply() * _mintAddLimit / 100, "mint limit trying to be set exceeds the allowed amount.");
        require(_amount + totalSupply() + _mintLimitSum <= cap(), "mint limit trying to be set exceeds the cap.");
        if (_amount == 0) {
            _issuers[_address] = false;
        } else {
            _issuers[_address] = true;
        }
        _mintLimitSum = _mintLimitSum + _amount - _addressToMintLimit[_address];
        _addressToMintLimit[_address] = _amount;
        return true;
    }

    /**
    * @dev Changes the bool of _blackList
    */
    function changeBlackList(address _address, bool _bool) public onlyOwner returns(bool) {
        _blackList[_address] = _bool;
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
    * @dev override transfer() with tax and blacklist.
    */
    function transfer(address _to, uint256 _amount) public virtual override returns (bool) {
        address owner = _msgSender();
        require(_balances[owner] >= _amount, "ERC20: amount exceeds balance");
        _transferWithTax(owner, _to, _amount);
        return true;
    }

    /**
    * @dev override transferFrom() with tax and blacklist.
    */
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(_from, spender, _amount);
        _transferWithTax(_from, _to, _amount);
        return true;
    }

    /**
    * @dev Lets an issuer mint CRDIT within its limit.
    */
    function issuerMint(address _to, uint256 _amount) public returns(bool) {
        if (_blackList[_to] == true) {
            return false;
        } else if(_amount <= _addressToMintLimit[_msgSender()]){
            _addressToMintLimit[_msgSender()] = _addressToMintLimit[_msgSender()] - _amount;
            _mint(_to, _amount);
            return true;
        } else {
            return false;
        }
    }

    /**
    * @dev Lets an issuer burn CRDIT to recover its limit.
    */
    function issuerBurn(uint256 _amount) public returns(bool) {
        _checkBlackList(_msgSender());
        require(_issuers[_msgSender()] = true, "This address is not an issuer.");
        _burn(_msgSender(), _amount);
        _mintLimitSum = _mintLimitSum + _amount;
        _addressToMintLimit[_msgSender()] = _addressToMintLimit[_msgSender()] + _amount;
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
    * @dev Checks if the reciever's address is a contract or not.
    * If it isn't, then the tax will be payed(burned) during the transaction.
    */
    function _transferWithTax(address _from, address _to, uint256 _amount) private {
        _checkBlackList(_from);
        _checkBlackList(_to);
        uint256 taxAmount = 0;
        if(_isContract(_to) == false) {
            taxAmount = _amount * _tax / 10000;
        }
        _burn(_from, taxAmount);
        _transfer(_from, _to, _amount - taxAmount);
    }

    /**
    * @dev Checks if the address is in the _blackList or not.
    */
    function _checkBlackList(address _address) private view {
        require(_blackList[_address] == false, "address is in the blacklist.");
    }

    function _isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.
        return account.code.length > 0;
    }

}