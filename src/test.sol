// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.5.12;

import "ds-test/test.sol";
import "dss-interfaces/interfaces.sol";

contract Hevm {
    function warp(uint256) public;
    function store(address,bytes32,bytes32) public;
}

contract OverflowTest is DSTest {
    Hevm hevm;

    // MAINNET ADDRESSES
    VatAbstract            vat = VatAbstract(    0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    CatAbstract            cat = CatAbstract(    0x78F2c2AF65126834c51822F56Be0d7469D7A523E);
    DSTokenAbstract       weth = DSTokenAbstract(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    GemJoinAbstract   wethJoin = GemJoinAbstract(0x2F0b23f53734252Bda2277357e97e1517d6B042A);

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));
    }

    function _createAndLiquidate(uint256 daiAmount) internal {
        uint256 wethAmount = 500 ether;

        // Giving WETH balance
        hevm.store(
            address(weth),
            keccak256(abi.encode(address(this), uint256(3))),
            bytes32(wethAmount)
        );
        assertEq(weth.balanceOf(address(this)), wethAmount);
        //

        weth.approve(address(wethJoin), uint256(-1));
        wethJoin.join(address(this), wethAmount);

        (, uint256 rate,,,) = vat.ilks("ETH-A");

        vat.frob("ETH-A", address(this), address(this), address(this), int(wethAmount), int(daiAmount / rate));

        // Setting the spot value to the lowest to make all the vaults unsafe
        hevm.store(
            address(vat),
            bytes32(uint256(keccak256(abi.encode(bytes32("ETH-A"), uint256(2)))) + 2),
            bytes32(uint256(1)));
        //

        cat.bite("ETH-A", address(this));
    }

    function testOverflow() public {
        _createAndLiquidate(102470 * 10 ** 45);
    }

    function testFailOverflow() public {
        _createAndLiquidate(102471 * 10 ** 45);
    }
}
