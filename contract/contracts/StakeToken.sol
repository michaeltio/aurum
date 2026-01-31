//SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StakeToken is ERC20 {
    constructor() ERC20("StakeToken", "SKT") {
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }
}
