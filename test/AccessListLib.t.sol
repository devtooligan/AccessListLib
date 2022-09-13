// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import {SLOT_ZERO, AccessListLib as al} from "../src/AccessListLib.sol";
import "forge-std/console.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external;
}

library AccessListTestingUtils {
    using al for uint256;


    function warm(bytes32 slot) internal {
        assembly {
            sstore(slot, 0x1)
        }
    }

    function warm(bytes32[] memory slots) internal {
        uint256 slotsLength = slots.length;
        for (uint i; i < slotsLength;) {
            warm(slots[i]);
            unchecked {
                ++i;
            }
        }
    }

}

contract AccessListLibTest is Test {
    using al for bytes32;
    using al for uint256;
    using AccessListTestingUtils for uint256;
    using AccessListTestingUtils for bytes32;
    using AccessListTestingUtils for bytes32[];

    bytes32[] public scratch;


    function toSlots(uint256 n, uint256 start, uint256 finish) internal returns (bytes32[] memory) {
        // This is a helper used to convert a uint into a list of slots that should be made warm in to for testing
        // NOTE: this leaves scratch dirty
        uint length = finish - start;
        uint idx;
        while (n > 0) {
            uint a = n % 2;
            if (a > 0) {
                scratch.push((length - idx - 1 + start).slot());
            }
            n = (n - a) >> 1;
            idx ++;
        }
        return scratch;
    }


    function testWarm() public {
        assertFalse(SLOT_ZERO.isWarm());
        SLOT_ZERO.warm();
        assertTrue(SLOT_ZERO.isWarm());
    }

    function testWarmSlots() public {
        bytes32[] memory slots = new bytes32[](10);
        for (uint i; i < 10; i++) {
            slots[i] = i.slot();
        }


        for (uint i; i < 10; i++) {
            assertFalse(slots[i].isWarm());
        }

        // slots are all warm now because of the isWarm check

        for (uint i; i < 10; i++) {
            assert(slots[i].isWarm());
        }

    }
    function testWarmSlots2() public {
        bytes32[] memory slots = new bytes32[](10);
        for (uint i; i < 10; i++) {
            slots[i] = (i + 100).slot();
        }

        slots.warm();

        for (uint i; i < 10; i++) {
            assert(slots[i].isWarm());
        }
    }

    function testAddSlots7() public {
        bytes32[] memory slots = new bytes32[](7);
        slots[0] = uint256(0).slot();
        slots[1] = uint256(4).slot();
        slots[2] = uint256(6).slot();
        slots.warm();
        // binary 1000101 == 69
        assertEq(al.addSlots(0, 7), 69);
    }

    function testAddSlots10() public {
        bytes32[] memory slots = new bytes32[](10);
        for (uint i; i < 10; i++) {
            slots[i] = i.slot();
        }
        slots.warm();
        // binary 1111111111 == 1023
        assertEq(al.addSlots(0, 10), 1023);
    }



    function testAddSlots256() public {
        bytes32[] memory slots = new bytes32[](256);
        for (uint i; i < 256; i++) {
            slots[i] = i.slot();
        }
        slots.warm();
        // 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        assertEq(al.addSlots(0, 256), type(uint256).max);
    }


    function testToSlots() public {
        // uint number = 2;
        uint number = type(uint256).max;
        toSlots(number, 0, 256).warm();
        // 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        assertEq(al.addSlots(0, 256), type(uint256).max);
    }

    function testMsgSig1() public {
        bytes32[] memory slots = new bytes32[](32);
        for (uint i; i < 32; i++) {
            slots[i] = i.slot();
        }
        slots.warm();
        // binary 111111111111111111111111111111 == 0xffffffff
        assertEq(al.addSlots(0, 32), type(uint32).max);
    }

    function testMsgSig2() public {
        bytes4 sig = IERC20.transfer.selector;
        toSlots(uint32(sig), 0, 32).warm();
        assertEq(al.addSlots(0, 32), uint32(sig));
    }

    function testArgUint1() public {
        bytes32[] memory slots = new bytes32[](256);
        for (uint i; i < 256; i++) {
            slots[i] = (i + 32).slot();
        }
        slots.warm();
        // 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        assertEq(al.argUint(0), type(uint256).max);

    }

    function testArgUint2() public {
        // 0x0000000000000000000000000000000000000000000000000000000000000000
        assertEq(al.argUint(0), 0);

    }

    function testArgUint3() public {
        bytes32[] memory slots = new bytes32[](1);
        slots[0] = uint256(32 + 255).slot();
        slots.warm();
        // 0x0000000000000000000000000000000000000000000000000000000000000001
        assertEq(al.argUint(0), 1);

    }

    function testArgUint4() public {
        toSlots(0x69, 32, 256 + 32).warm();
        // 0x0000000000000000000000000000000000000000000000000000000000000069
        assertEq(al.argUint(0), 0x69);

    }

    function testArgAddress1() public {
        address target = address(0xbadbabe);
        toSlots(uint256(uint160(target)), 32 + 256, 256 + 256 + 32).warm();
        // 0x000000000000000000000000000000000000000000000000000000000badbabe
        assertEq(al.argAddress(1), target);

    }
    function testArgAddress2() public {
        address target = address(this);
        toSlots(uint256(uint160(target)), 32 + 256 * 2, 256 * 2 + 256 + 32).warm();
        // 0x000000000000000000000000000000000000000000000000000000000badbabe
        assertEq(al.argAddress(2), address(this));
    }

    function transfer(address to, uint amount) public {
        console.log("Transferring amount:", amount);
        console.log("Transferring to:", to);
    }


    function setupTransfer() public {
        // msgSig
        bytes4 sig = IERC20.transfer.selector;
        toSlots(uint32(sig), 0, 32).warm();

        // arg0 address == 0xbadbabe
        address targetAddress = address(0xbadbabe);
        toSlots(uint256(uint160(targetAddress)), 32, 256 + 32).warm();

        // arg1 uint == 1000 eth
        uint targetAmount = 1000 * 1e18;
        toSlots(targetAmount, 32 + 256, 256 + 256 + 32).warm();

    }

    function testTransfer() public {
        setupTransfer();
        bytes4 msgSig = al.msgSig();
        address to = al.argAddress(0);
        uint amount = al.argUint(1);
        if (uint32(msgSig) == uint32(IERC20.transfer.selector)) {
            assertEq(to, address(0xbadbabe));
            assertEq(amount, 1000 * 1e18);
            transfer(to, amount);
        }
    }

}
