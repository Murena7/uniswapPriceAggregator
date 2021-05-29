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

    struct TokenHelper {
        bytes16 reserve;
        address tokenAddress;
        IERC20 contractInstance;
        uint8 decimals;
    }

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

        TokenHelper memory token0;
        token0.reserve = ABDKMathQuad.fromUInt(_reserve0);
        token0.tokenAddress = pairContract.token0();
        token0.contractInstance = IERC20(token0.tokenAddress);
        token0.decimals = token0.contractInstance.decimals();

        TokenHelper memory token1;
        token1.reserve = ABDKMathQuad.fromUInt(_reserve1);
        token1.tokenAddress = pairContract.token1();
        token1.contractInstance = IERC20(token1.tokenAddress);
        token1.decimals = token1.contractInstance.decimals();

        if (_sendToken == token0.tokenAddress) {
            return (valueCalculations(token1, token0), token1.contractInstance.symbol(), token1.decimals);
        } else {
            return (valueCalculations(token0, token1) , token0.contractInstance.symbol(),  token0.decimals);
        }
    }

    function valueCalculations(TokenHelper memory token0, TokenHelper memory token1) internal view returns(uint256) {
        bytes16 divisor = ABDKMathQuad.fromUInt(10**token0.decimals);
        return ABDKMathQuad.toUInt(
                ABDKMathQuad.mul(ABDKMathQuad.div(
                    decimalNumberShifter(token0.reserve, token0.decimals, token1.decimals), token1.reserve)
                , divisor)
               );
    }

    function decimalNumberShifter(bytes16 number, uint8 decimal1, uint8 decimal2) internal view returns(bytes16) {
        if(decimal1 > decimal2) {
            return ABDKMathQuad.mul(number, ABDKMathQuad.fromUInt(10**decimal1));
        } else if(decimal1 < decimal2)  {
            return ABDKMathQuad.div(number, ABDKMathQuad.fromUInt(10**decimal1));
        } else {
            return number;
        }
    }
}
