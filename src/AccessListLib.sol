// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;
import "forge-std/console.sol";

/*

                                                                                                                           :            :
                                                                                                                           :            :
                                                                                                                           :            :
                                              ______                                                                       :            :
                                             |______|                                                                      :            :
                            _                 |    |                                                                      .'            :
                           | `-._             |    |                                                                  _.-"              :
         __________________|_____`._______    /    /____________________________.-.____________                   _.-"                  '.
     __.`-------------------____----------`--/`._.`-----|                        o|            |  ..__...____...-"                       :
    ||                     (____)            |    LGB   | ======================  |____________| : \_\                                    :
    ||_______________________________________|__________| ======================  |              :    .--"                                 :
    '-._o                          o____(_)_____________| ============= ____..o---'              `.__/  .-" _                               :
        `.           __0-------''-`          `---..--._(|_o______.-----`      `.O.`                 /  /  ," ,-                            .'
          )     o  .' //       ||                                            __//__                (_)(`,(_,'L_,_____       ____....__   _
         /        (   \\       ||                                           `------`                "' "             """""""       .'cgmm
        /          \___________//
       /         __/-----------`
    _./         (
_.-`             )  ====================================================================================================================================
\\              (   =        ====    ======    ====        ===      ===  ====  ==  =======  ==========  =====  ========        ==       ===        ==  =
 \\     _ o      )  =  =========  ==  ====  ==  ======  =====   ==   ==  ====  ==   ======  =========    ====  ========  ========  ====  =====  =====  =
  \\_.-`        (   =  ========  ====  ==  ====  =====  =====  ====  ==  ====  ==    =====  ========  ==  ===  ========  ========  ====  =====  =====  =
   (_____________)  =  ========  ====  ==  ====  =====  =====  ========  ====  ==  ==  ===  =======  ====  ==  ========  ========  ===   =====  =====  =
                    =      ====  ====  ==  ====  =====  =====  ========  ====  ==  ===  ==  =======  ====  ==  ========      ====      =======  =====  =
                    =  ========  ====  ==  ====  =====  =====  ===   ==  ====  ==  ====  =  =======        ==  ========  ========  ====  =====  =====  =
                    =  ========  ====  ==  ====  =====  =====  ====  ==  ====  ==  =====    =======  ====  ==  ========  ========  ====  =====  ========
                    =  =========  ==  ====  ==  ======  =====   ==   ==   ==   ==  ======   =======  ====  ==  ========  ========  ====  =====  =====  =
                    =  ==========    ======    =======  ======      ====      ===  =======  =======  ====  ==        ==        ==  ====  =====  =====  =
                    ====================================================================================================================================

                    DO NOT USE THIS FOR ANYTHING REAL!  EVER.  SERIOUSLY DO NOT USE THIS.
 */

// keccak256("access.list.library");
bytes32 constant SLOT_ZERO = 0xf6b90c594052dd41030fa1082062d4d0952430a41949e8bea89c3f6ad3dc8a12;

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
        // if the slot is warm the gas used will be the same
        return check1 - check2 == check2 - check3;
    }

    function slot(uint256 index) internal pure returns (bytes32) {
        return bytes32(uint256(SLOT_ZERO) + index);
    }

    function addSlots(uint256 start, uint256 finish) internal returns (uint256 sum) {
        uint256 length = finish - start;
        for (uint256 i = start; i < finish; ++i) {
            if (isWarm(slot(i))) {
                sum = sum + 2**(finish - i - 1);
            }
        }
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
        uint start = 32 + index * 256; // skip 1st 4 bytes (func sig) read 1 word
        return
            address(
                uint160(
                    uint256(addSlots(start, start + 256))
                )
            );
    }
}
























