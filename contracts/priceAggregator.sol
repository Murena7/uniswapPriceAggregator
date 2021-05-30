// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IERC20.sol";

import "./helpers/ABDKMathQuad.sol";

import "hardhat/console.sol";

contract PriceAggregator {
    address public owner;
    bool public paused;
    address public factoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    constructor() {
        owner = msg.sender;
    }

    struct checkToken {
        address sendToken;
        address getToken;
    }

    struct TokenHelper {
        bytes16 reserve;
        address tokenAddress;
        IERC20 contractInstance;
        uint8 decimals;
    }

    struct PriceResult {
        address send;
        address get;
        uint256 getPrice;
        string getSymbol;
        uint8 getDecimal;
        bool status;
    }

    function setFactoryAddress(address value) public onlyOwner {
        factoryAddress = value;
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function destroySmartContract(address payable _to) public onlyOwner {
        selfdestruct(_to);
    }

    function getCurrentPriceArr(checkToken[] memory _inputDataArr) public view isPaused returns (PriceResult[] memory) {
        PriceResult[] memory results = new PriceResult[](_inputDataArr.length);

        for (uint i=0; i < _inputDataArr.length; i++) {
            results[i] = getCurrentPrice(_inputDataArr[i]);
        }

        return results;
    }

    function getCurrentPrice(checkToken memory _inputData) public view isPaused returns (PriceResult memory) {
        IUniswapV2Factory factoryContract = IUniswapV2Factory(factoryAddress);
        address pairAddress = factoryContract.getPair(_inputData.sendToken, _inputData.getToken);

        if(pairAddress == 0x0000000000000000000000000000000000000000) {
            PriceResult memory errorResult;
            errorResult.send = _inputData.sendToken;
            errorResult.get = _inputData.getToken;
            return errorResult;
        }

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

        if (_inputData.sendToken == token0.tokenAddress) {
            return PriceResult(_inputData.sendToken, _inputData.getToken, valueCalculations(token1, token0), token1.contractInstance.symbol(), token1.decimals, true);
        } else {
            return PriceResult(_inputData.sendToken, _inputData.getToken, valueCalculations(token0, token1) , token0.contractInstance.symbol(),  token0.decimals, true);
        }
    }

    function valueCalculations(TokenHelper memory token0, TokenHelper memory token1) internal pure returns(uint256) {
        bytes16 divisor = ABDKMathQuad.fromUInt(10**token0.decimals);
        return ABDKMathQuad.toUInt(
                ABDKMathQuad.mul(ABDKMathQuad.div(
                    token0.reserve, decimalNumberShifter(token1.reserve, token1.decimals, token0.decimals))
                , divisor)
               );
    }

    function decimalNumberShifter(bytes16 number0, uint8 decimal0, uint8 decimal1) internal pure returns(bytes16) {
        if(decimal0 < decimal1) {
            uint8 shiftDecimal = decimal1 - decimal0;
            return ABDKMathQuad.mul(number0, ABDKMathQuad.fromUInt(10**shiftDecimal));
        } else if(decimal0 > decimal1)  {
            uint8 shiftDecimal = decimal0 - decimal1;
            return ABDKMathQuad.div(number0, ABDKMathQuad.fromUInt(10**shiftDecimal));
        } else {
            return number0;
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not allowed");
        _;
    }

    modifier isPaused() {
        require(paused == false, "Contract Paused");
        _;
    }
}
