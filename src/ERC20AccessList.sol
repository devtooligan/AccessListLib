// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {AccessListLib as al} from "./AccessListLib.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external;
    // ...
}

contract ERC20AccessList is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_, decimals_) {}

    fallback() external {
        bytes4 msgSig = al.msgSig();
        if (uint32(msgSig) == uint32(IERC20.transfer.selector)) {
            address to = al.argAddress(0);
            uint256 amount = al.argUint(1);
            transfer(to, amount);
        } else if (uint32(msgSig) == uint32(IERC20.transferFrom.selector)) {
            address from = al.argAddress(0);
            address to = al.argAddress(1);
            uint256 amount = al.argUint(2);
            transferFrom(from, to, amount);
        } // .. etc
    }
}






