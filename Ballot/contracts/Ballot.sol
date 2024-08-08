//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.0;


import "hardhat/console.sol";

/// @title 委托投票合约： 
///     1. 目标是为每个（投票）表决创建一份合约，一个合约含有多个选项，每个选项有对应的简称。 合约的创造者——即为主席，
///     2. 主席可给予每个独立的地址以投票权。
///     3. 拥有投票权地址的人可以选择自己投票，或者委托给他们信任的人来投票。
///     4. 在投票时间结束时，winningProposal() 将返回获得最多投票的提案。
contract Ballot {


    // 投票选民
    struct Voter {
        uint weight; // 计票权重
        bool voted; // true表示该人已投票
        address delegate; // 被委托人
        uint vote; // 投票提案的索引
    }
    // 状态变量， 记录每个选民状态
    mapping(address => Voter ) public voters;

    // 提案
    struct Proposal {
        bytes32 name;   // 简称（最长32个字节）
        uint voteCount; // 得票数
    }
    // 提案集
    Proposal[]  public proposals;


    // 合约创造者 -- 提案主席 
    address public chairperson;


    /// 为 `proposalNames` 中的每个提案，创建一个新的（投票）表决
    constructor(bytes32[]  memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
        
        for (uint i=0; i<proposalNames.length; i++ ) {
            proposals.push(Proposal({
                name : proposalNames[i],
                voteCount : 0
            }));
        }
    }

    /// 授权`voter`行使投票权
    /// 只有`chairperson` 可以调用该函数
    function giveRightToVote(address voter)  external{

        // 若 `require` 的第一个参数的计算结果为 `false`，
        // 则终止执行，撤销所有对状态和以太币余额的改动(类似回滚所有操作)。
        // 在旧版的 EVM 中这曾经会消耗所有 gas，但现在不会了。
        // 使用 require 来检查函数是否被正确地调用，是一个好习惯。
        // 我们可以在 require 的第二个参数中提供一个对错误情况的解释。
        require(
            msg.sender  == chairperson, 
            "Only chairperson can give right to vote"
        );
        require(
            !voters[voter].voted,
            "The voter already voted"
        );

        require(voters[voter].weight == 0 );
        console.log(
            "giveRightToVoteing : %s give %s",
            msg.sender,
            voter
        );
        voters[voter].weight = 1;
    }

    /// 把你的投票委托给投票者`to`
    function delegate(address to)  external {
        //传引用
        Voter storage sender = voters[msg.sender];

        // 投票者还有权重
        require(
            sender.weight != 0,
            "You have no right to vote"
        );
        // 投票者还未投票
        require(
            !sender.voted,
            "You already voted."
            );
        // 委托目标不是自己
        require(
            to != msg.sender,
            "Self-delegatetion isnot allowed."
        );

        // 如果被委托者 `to` 也设置了委托, 委托是可以传递的。
        // 一般来说，这种循环委托是危险的。因为，如果传递的链条太长，
        // 则可能需消耗的gas要多于区块中剩余的（大于区块设置的gasLimit），
        // 这种情况下，委托不会被执行。
        // 并且如果形成闭环，合约则完全卡住了。
        while( voters[to].delegate != address(0) )
        {
            to = voters[to].delegate;

            // 不允许闭环委托
            require(
                to != msg.sender,
                "Found loop in delegation."
            );
        }

        // 
        Voter storage delegate_ = voters[to];
        require(delegate_.weight >= 1);

        // `sender` 是一个引用, 相当于对 `voters[msg.sender].voted` 进行修改
        sender.voted = true;
        sender.delegate = to;

        if (delegate_.voted) {
            // 如果被委托者已投过票了，直接增加得票数
            proposals[delegate_.vote].voteCount += sender.weight;
        }else{
            // 如果委托者还没投票，则增加委托者的权重
            delegate_.weight += sender.weight;
        }
    }

    /// 把你的票(包括委托给你的票)，投给提案 `proposals[proposal].name`.
    function vote(uint proposal) external{
        //
        Voter storage sender = voters[msg.sender];
        require(
            !sender.voted,
            "Already voted."
        );
        sender.voted = true;
        sender.vote = proposal;

        // 如果 `proposal` 超过了数组的范围，则会自动抛出异常，并恢复所有的改动   //为啥？？？
        proposals[proposal].voteCount += sender.weight;
    }

    /// 结合之前所有的投票，计算出最终胜出的提案
    /// 待优化： 如果出现平局，将会按序号返回第一个
    function winningProposal() external view
        returns (uint winningProposal_)        
    {
        uint winningVoteCount = 0;
        for ( uint p=0; p<proposals.length; p++ ) {
            if ( proposals[p].voteCount > winningVoteCount ){
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ =  p;
            }
        }
    }

    /// 调用 winningProposal() 获取提案数组中获胜者的索引，并以此返回获胜者的名称
    function winnerName() public view 
        returns( bytes32 winnerName_)
    {
        // winningProposal申明是external,故需要加上this.
        winnerName_= proposals[this.winningProposal()].name;
    }

}

