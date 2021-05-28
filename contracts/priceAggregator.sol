// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";

import "./helpers/ABDKMathQuad.sol";

import "hardhat/console.sol";

contract PriceAggregator {
    address public factoryAddress = 0xBCfCcbde45cE874adCB698cC183deBcF17952812;
    IUniswapV2Factory factoryContract = IUniswapV2Factory(factoryAddress);

    function getCurrentPrice(address _sendToken, address _receiveToken) public view returns (uint256) {
        address pairAddress = factoryContract.getPair(_sendToken, _receiveToken);

        IUniswapV2Pair pairContract = IUniswapV2Pair(pairAddress);
        (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) = pairContract.getReserves();

        address token0 = pairContract.token0();

        bytes16 _reserve0Bytes = ABDKMathQuad.fromUInt(_reserve0);
        bytes16 _reserve1Bytes = ABDKMathQuad.fromUInt(_reserve1);

        bytes16 divisor = ABDKMathQuad.fromUInt(10**18);

        if (_sendToken == token0) {
            return ABDKMathQuad.toUInt(ABDKMathQuad.mul(ABDKMathQuad.div(_reserve0Bytes, _reserve1Bytes), divisor));
        } else {
            return ABDKMathQuad.toUInt(ABDKMathQuad.mul(ABDKMathQuad.div(_reserve1Bytes, _reserve0Bytes), divisor));
        }
    }
}
