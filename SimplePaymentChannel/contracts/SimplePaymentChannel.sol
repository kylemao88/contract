// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


/// @title 简易支付通道
contract SimplePaymentChannel {

    address payable public sender;      // The account sending payments.
    address payable public recipient;   // The account receiving the payments.
    uint256 public expiration;  // Timeout in case the recipient never closes.    

    ///
    constructor (address payable recipientAddress, uint256 duration)
        public
        payable        
    {
        sender = payable(msg.sender);
        recipient = recipientAddress;
        expiration = block.timestamp + duration;
    }

    /// the sender can extend the expiration at any time
    function extend(uint256 newExpiration)  external {
        require(msg.sender ==  sender);
        require(newExpiration > expiration);

        expiration = newExpiration;
    }

    /// builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }    

    /// All functions below this are just taken from the chapter
    /// 'creating and verifying signatures' chapter.
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    ///
    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }


    ///
    function isValidSignature( uint256 amount, bytes memory signature ) 
        internal
        view
        returns (bool)
    {
        bytes32 message = prefixed( keccak256(abi.encodePacked((this, amount)))) ;

        //check that the signature is from the payment sender
        return recoverSigner(message, signature) == sender;
    }

    /// 关闭通道，凭签名收款金额， 并将余额返回发送者
    function close( uint256 amount, bytes memory signature ) external {
        require(msg.sender == recipient);
        require(
            isValidSignature(amount, signature)
        );

        recipient.transfer(amount);
        selfdestruct(sender);

    }

    /// 如果过期过期时间已到，而收款人没有关闭通道，可执行此函数，销毁合约并返还余额
    function claimTimeout() external {
        require(
            block.timestamp >= expiration
        );

        selfdestruct(sender);
    }
    
 
}