// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "./TestERC20.sol";

contract SimpleSwap {
    // phase 1
    TestERC20 public token0;
    TestERC20 public token1;
    uint256 public reserve0; // 代币0的储备量
    uint256 public reserve1; // 代币1的储备量

    // phase 2
    uint256 public totalSupply = 0;
    mapping(address => uint256) public share;

    // phase 3 x + y + x*y = k exam
    uint256 public reserveX; // 代币X的储备量
    uint256 public reserveY; // 代币Y的储备量

    constructor(address _token0, address _token1) {
        token0 = TestERC20(_token0);
        token1 = TestERC20(_token1);
    }

    function swap(address _tokenIn, uint256 _amountIn) public {
        if (_tokenIn == address(token0)) {
            token0.transferFrom(msg.sender, address(this), _amountIn);
            token1.transfer(msg.sender, _amountIn);
        } else if (_tokenIn == address(token1)) {
            token1.transferFrom(msg.sender, address(this), _amountIn);
            token0.transfer(msg.sender, _amountIn);
        } else {
            revert("SimpleSwap: invalid token");
        }
    }

    // phase 1
    function addLiquidity1(uint256 _amount) public {
        token0.transferFrom(msg.sender, address(this), _amount);
        token1.transferFrom(msg.sender, address(this), _amount);
    }

    function removeLiquidity1() public {
        uint256 _amount = token0.balanceOf(address(this));
        token0.transfer(msg.sender, _amount);
        _amount = token1.balanceOf(address(this));
        token1.transfer(msg.sender, _amount);
    }

    // phase 2
    function addLiquidity2(uint256 _amount) public {
        token0.transferFrom(msg.sender, address(this), _amount);
        token1.transferFrom(msg.sender, address(this), _amount);
        share[msg.sender] += _amount;
        totalSupply += _amount;
    }

    function removeLiquidity2() public {
        uint256 _removeAmount0 = (share[msg.sender] *
            token0.balanceOf(address(this))) / totalSupply;
        uint256 _removeAmount1 = (share[msg.sender] *
            token1.balanceOf(address(this))) / totalSupply;
        token0.transfer(msg.sender, _removeAmount0);
        token1.transfer(msg.sender, _removeAmount1);
        totalSupply -= share[msg.sender];
        share[msg.sender] = 0;
    }

    // phase 3 x + y + x * y  = k exam
    function swap2(
        uint256 _tokenIn,
        uint256 _amountIn
    ) public returns (uint256 _amountOut) {
        require(_tokenIn == 0 || _tokenIn == 1, "Invalid token identifier");

        if (_tokenIn == 0) {
            // msg.sender用token0換token1
            _amountOut = getAmountOut(_amountIn, reserve0, reserve1);

            // msg.sender轉移token0給合約
            token0.transferFrom(msg.sender, address(this), _amountIn);

            // 合約轉移token1給msg.sender
            token1.transfer(msg.sender, _amountOut);

            // 更新儲備量
            reserve0 += _amountIn;
            reserve1 -= _amountOut;
        } else {
            // msg.sender用token1換token0
            _amountOut = getAmountOut(_amountIn, reserve1, reserve0);

            // msg.sender轉移token1給合約
            token1.transferFrom(msg.sender, address(this), _amountIn);

            // 合約轉移token0給msg.sender
            token0.transfer(msg.sender, _amountOut);

            // 更新儲備量
            reserve1 += _amountIn;
            reserve0 -= _amountOut;
        }

        return _amountOut;
    }

    // x + y + x * y = k
    function getAmountOut(
        uint256 _amountIn,
        uint256 _reserveIn,
        uint256 _reserveOut
    ) public pure returns (uint256 amountOut) {
        uint256 newReserveIn = _reserveIn + _amountIn;
        uint256 newReserveOut = 10000 - newReserveIn - _reserveIn * _reserveOut;

        amountOut = _reserveOut - newReserveOut;

        return amountOut;
    }
}
