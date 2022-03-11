// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {console} from "../utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";

contract CorrectnessTest is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    function testBasic() public {
        console.log("test");
        string[] memory inputs = new string[](2);
        inputs[0] = "python3";
        inputs[1] = "src/test/correctness/compute.py";
        bytes memory res = vm.ffi(inputs);
        console.log("pybytes");
        console.logBytes(res);
        // uint256 num = abi.decode(res, (uint256));
        bytes memory enc = abi.encode(4000);
        console.log("solbytes");
        console.logBytes(enc);

        uint256 num = abi.decode(res, (uint256));
        console.log("SACRED NUMBER", num);
        // console.logBytes(res);
        // Data memory data = abi.decode(res, (Data));
        // assertEq(data.name, name);
        // for (uint256 i = 0; i < attributes.length; i++) {
        //     assertEq(data.attributes[i], attributes[i]);
        // }
    }
}
