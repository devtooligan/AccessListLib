// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {ERC20} from "solmate/tokens/ERC20.sol";


contract ERC20AccessList is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_, decimals_) {}

    function mint(address to, uint256 value) public virtual {
        _mint(to, value);
    }

    function burn(address from, uint256 value) public virtual {
        _burn(from, value);
    }

    fallback() external {
        bytes4 msgSig = al.msgSig();
        if (uint32(msgSig) == uint32(IERC20.transfer.selector)) {
            address to = al.argAddress(0);
            uint256 amount = al.argUint(1);
            transfer(to, amount);
        }
    }
}
