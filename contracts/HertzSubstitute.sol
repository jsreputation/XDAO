//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "./Open-Zeppelin.sol";

contract HertzSubstitute is ERC20PresetFixedSupplyUpgradeable {
    // constructor( 
    //     string memory name,
    //     string memory symbol,
    //     uint256 initialSupply,
    //     address owner
    // ) public {
    //     __ERC20PresetFixedSupply_init(name, symbol, initialSupply, owner);
    // }

    constructor( 
    ) public {
        __ERC20PresetFixedSupply_init("Hertz Substitute Token", "HTZ", 1e33, msg.sender);
    }

}

