// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import {ERC20AccessListTest} from "../src/ERC20AccessList.sol";
import "forge-std/console.sol";

library AccessListTestingUtils {
    using al for uint256;

    function warm(bytes32 slot) internal {
        assembly {
            sstore(slot, 0x1)
        }
    }

    function warm(bytes32[] memory slots) internal {
        uint256 slotsLength = slots.length;
        for (uint256 i; i < slotsLength; ) {
            warm(slots[i]);
            unchecked {
                ++i;
            }
        }
    }
}

contract ERC20AccessListTest is Test {
    using al for bytes32;
    using al for uint256;
    using AccessListTestingUtils for uint256;
    using AccessListTestingUtils for bytes32;
    using AccessListTestingUtils for bytes32[];

    ERC20AccessList public token;
    bytes32[] public scratch;

    function setUp() public {
        token = new ERC20AccessList("ERC20 Access List", "CURSED", 18);
    }

    function toSlots(
        uint256 n,
        uint256 start,
        uint256 finish
    ) internal returns (bytes32[] memory) {
        // NOTE: this leaves scratch dirty
        uint256 length = finish - start;
        uint256 idx;
        while (n > 0) {
            uint256 a = n % 2;
            if (a > 0) {
                scratch.push((length - idx - 1 + start).slot());
            }
            n = (n - a) >> 1;
            idx++;
        }
        return scratch;
    }

    function setupTransfer() public {
        // msgSig
        bytes4 sig = IERC20.transfer.selector;
        toSlots(uint32(sig), 0, 32).warm();

        // arg0 address == 0xbadbabe
        address targetAddress = address(0xbadbabe);
        toSlots(uint256(uint160(targetAddress)), 32, 256 + 32).warm();

        // arg1 uint == 1000 eth
        uint256 targetAmount = 1000 * 1e18;
        toSlots(targetAmount, 32 + 256, 256 + 256 + 32).warm();
    }

    function testTransfer() public {
        setupTransfer();
        bytes4 msgSig = al.msgSig();
        address to = al.argAddress(0);
        uint256 amount = al.argUint(1);
        if (uint32(msgSig) == uint32(IERC20.transfer.selector)) {
            assertEq(to, address(0xbadbabe));
            assertEq(amount, 1000 * 1e18);
            transfer(to, amount);
        }
    }
}
