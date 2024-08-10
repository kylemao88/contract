// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;


/// @title 远程购买合约 
/// 1. 双方都要把物品价值的两倍作为担保费放入合约。只要发生状况，钱就会一直锁在合约里面，直到买方确认收到物品。 
/// 2. 确认收货之后，买方可以退回物品价值（他担保费的一半），卖方得到三倍的价值（他们的押金加上价值）
/// 3. 背后的想法是，双方都有动力去解决这个问题，否则他们的钱就永远被锁定了。
/// 4. 这个合约不能解决所有问题，但它概述了如何在合约中使用类似状态机的结构。
contract Purchase {

    // 状态：创建， 锁定， 释放， 未激活
    enum State { Created, Locked, Release, Inactive }
    State public state;


    //
    address payable public seller;
    address payable public buyer;
    //
    uint public value;

    
    /// Only the seller can call this function.
    //error onlySeller();
    /// Only the buyer can call this function.
    //error onlyBuyer();
    /// The function cannot be called at the current state.
    error InvalidState();    
    /// The provided value has to be even.
    error ValueNotEven();

    ///
    event Aborted();
    event PurchaseConfirmed();
    event ItemReceived();
    event SellerRefunded();

    modifier onlyBuyer(){
        require(
            msg.sender == buyer,
            "Only buyer can call this."
        );
        _;
    }

    modifier onlySeller(){
        require(
            msg.sender ==  seller,
            "Only seller can call this."
        );
        _;
    }

    modifier inState(State st){
        require(
            state == st,
            "Invalid State."
        );
        _;
    }

    modifier condition(bool condition_){
        require(condition_);
        _;
    }


    /// 需要确认mgs.value是一个偶数
    constructor() payable{
        seller = payable(msg.sender);
        value = msg.value / 2;

        if ((2*value) != msg.value){
            revert ValueNotEven();
        }
    }


    /// 中止购买并回收以太币
    /// 只能在合约被锁定之前由卖家发起
    function abort()
        external
        onlySeller
        inState(State.Created)
    {
        emit Aborted();
        state = State.Inactive;
        seller.transfer(address(this).balance);
    }

    /// 买家确认购买
    /// 交易必须包含`2 * value` 个以太币。
    /// 以太币会被锁定，直到 confirmReceived 被调用
    function confirmPurchase() 
        external
        inState(State.Created)
        condition(msg.value == (2*value))
        payable
    {
        emit PurchaseConfirmed();
        buyer  = payable(msg.sender);
        state = State.Locked;
    }


    /// 确认你（买家）已经收到商品。
    /// 这会释放被锁定的以太币。
    function confirmReceived()
        external
        onlyBuyer()
        inState(State.Locked)
    {
        emit ItemReceived();
        // It is important to change the state first because
        // otherwise, the contracts called using `send` below
        // can call in again here.
        state =State.Release;

        buyer.transfer(value);

    }

    
    function refundSeller()
        external
        onlySeller()
        inState(State.Release)
    {
        emit SellerRefunded();
        // It is important to change the state first because
        // otherwise, the contracts called using `send` below
        // can call in again here.
        state = State.Inactive;

        seller.transfer(3*value);
    }

}