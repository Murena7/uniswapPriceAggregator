// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IERC20.sol";

import "./helpers/ABDKMathQuad.sol";

import "hardhat/console.sol";

contract PriceAggregator {
    address public factoryAddress = 0xBCfCcbde45cE874adCB698cC183deBcF17952812;
    IUniswapV2Factory factoryContract = IUniswapV2Factory(factoryAddress);

    function getCurrentPriceArr(address[] memory _sendTokens, address[] memory _receiveTokens) public view returns (uint256[] memory, string[] memory, uint8[] memory) {
        uint256[] memory amounts = new uint256[](_sendTokens.length);
        string[] memory symbols = new string[](_sendTokens.length);
        uint8[] memory decimals = new uint8[](_sendTokens.length);

        for (uint i=0; i < _sendTokens.length; i++) {
            (uint256 amount, string memory symbol, uint8 decimal) = getCurrentPrice(_sendTokens[i], _receiveTokens[i]);
            amounts[i] = amount;
            symbols[i] = symbol;
            decimals[i] = decimal;
        }

        return (amounts, symbols, decimals);
    }

    function getCurrentPrice(address _sendToken, address _receiveToken) public view returns (uint256, string memory, uint8) {
        address pairAddress = factoryContract.getPair(_sendToken, _receiveToken);

        IUniswapV2Pair pairContract = IUniswapV2Pair(pairAddress);
        (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) = pairContract.getReserves();

        address token0 = pairContract.token0();

        bytes16 _reserve0Bytes = ABDKMathQuad.fromUInt(_reserve0);
        bytes16 _reserve1Bytes = ABDKMathQuad.fromUInt(_reserve1);

        if (_sendToken == token0) {
            address token1 = pairContract.token1();
            IERC20 erc20Contract = IERC20(token1);

            uint8 token0decimals = erc20Contract.decimals();
            bytes16 divisor = ABDKMathQuad.fromUInt(10**token0decimals);

            return (ABDKMathQuad.toUInt(ABDKMathQuad.mul(ABDKMathQuad.div(_reserve1Bytes, _reserve0Bytes), divisor)) , erc20Contract.symbol(),  token0decimals);
        } else {
            IERC20 erc20Contract = IERC20(token0);

            uint8 token1decimals = erc20Contract.decimals();
            bytes16 divisor = ABDKMathQuad.fromUInt(10**token1decimals);

            return (ABDKMathQuad.toUInt(ABDKMathQuad.mul(ABDKMathQuad.div(_reserve0Bytes, _reserve1Bytes), divisor)), erc20Contract.symbol(), token1decimals);
        }
    }
}
