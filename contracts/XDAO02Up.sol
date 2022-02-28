//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./XDAO01Up.sol";

contract XDAO02Up is XDAO01Up {

	///////////// Initialization functions, following OpenZeppelin's stype. Not required /////////////

    function __XDAO02Up_init() public initializer {
		__Ownable_init();
	    __XDAO02Up_init_unchained();
	}

    function __XDAO02Up_init_unchained() public initializer {
    }

	////////////////////// Override/Modify base contract's functions ////////

    // function ___test___setLastTransferTime(address holder, uint256 daysAgo) external override virtual {
    //     lastTransferTime[holder] = block.timestamp - daysAgo * 24 * 3600 + 1;
    // }


	////////////////////// Add new variales /////////////////////////////////

	address public operator;


	///////////////////// Add new functions /////////////////////////////////
	
	function changeOperator(address newOperator) external virtual {
		require(newOperator != address(0), "Invalid address");
		operator = newOperator;
	}
}