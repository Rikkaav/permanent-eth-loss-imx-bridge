// test/mocks/child/MockChildToken.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IChildERC20} from "src/interfaces/child/IChildERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MockChildToken is Initializable, ERC20Upgradeable, IChildERC20 {
    address public rootToken;
    address public bridge; 

    constructor() {
        _disableInitializers(); 
    }

    function initialize(
        address _rootToken, 
        string memory _name, 
        string memory _symbol, 
        uint8 _decimals
    ) public initializer {
        __ERC20_init(_name, _symbol);
        rootToken = _rootToken;
    }

    function mint(address account, uint256 amount) public virtual returns (bool) {
        _mint(account, amount);
        return true;
    }

    function burn(address account, uint256 amount) public virtual returns (bool) {
        _burn(account, amount);
        return true;
    }
}