// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;
import "forge-std/console.sol";
// keccak256("access.list.library");
bytes32 constant SLOT_ZERO =
    0xf6b90c594052dd41030fa1082062d4d0952430a41949e8bea89c3f6ad3dc8a12;

// for maths
uint256 constant UINT_SLOT_ZERO = uint256(SLOT_ZERO);

library AccessListLib {

    function isWarm(bytes32 slot) internal returns (bool) {
        uint256 x;
        uint256 check1 = gasleft();
        assembly {
            x := sload(slot)
        }
        uint256 check2 = gasleft();
        assembly {
            x := sload(slot)
        }
        uint256 check3 = gasleft();
        return check1 - check2 == check2 - check3;
    }

    function addSlots(uint256 start, uint256 finish) internal returns (uint256 sum) {
        // TODO: Change to start and legnth
        uint length = finish - start;
        for (uint i = start; i < finish;) {
            if (isWarm(slot(i))) {
                // sum = sum + 0x1 << (finish - i - 1);
                sum = sum + 2 ** (finish - i - 1);
            }
            unchecked {
                ++i;
            }
        }
    }

    function slot(uint256 index) internal pure returns (bytes32) {
        return bytes32(UINT_SLOT_ZERO + index);
    }

    function msgSig() internal returns (bytes4) {
        return bytes4(uint32(addSlots(0, 32)));
    }

    function argUint(uint256 index) internal returns (uint256) {
        // argIndex starts at 0 so first argument is 0, 2nd is 1 etc
        return uint256(addSlots(32 + index * 256, 32 + index * 256 + 256));
    }

    function argAddress(uint256 index) internal returns (address) {
        // argIndex starts at 0 so first argument is 0, 2nd is 1 etc
        return address(uint160(uint256(addSlots(32 + index * 256, 32 + index * 256 + 256))));
    }

}
