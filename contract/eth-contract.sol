pragma solidity ^0.5.8;

// ------------------------
// Teache Token Contract    
// Deploy addres:           0xe325ba712b216e9619439a5a0d08995237a5cf0e
// Symbol:                  ThC
// Name:                    Teache Coin
// Total suply:             100000000
// Decimals:                18
// ------------------------

// Safe Math - used to deal with overflows and divide_by_zero exceptions
contract SafeMath {
    function add(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mult(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Source: MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

// ----------------------------------------------------------------------------
// Owned token contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnerChanged(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerChanged(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// Teache Coin - Code
// Interfaces: ERC20Interface, Owner, SafeMath
// ----------------------------------------------------------------------------
contract TeacheCoin is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) userBalances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        symbol = "TES";
        name = "TestCoin";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;
        userBalances[0x26c46D907d0C8f5B604F7421521220b99c9237Df] = _totalSupply;
        emit Transfer(address(0), 0x26c46D907d0C8f5B604F7421521220b99c9237Df, _totalSupply);
    }

    // get totalSupply
    function totalSupply() public view returns (uint) {
        return _totalSupply - userBalances[address(0)];
    }

    // check balance for account tokenOwner
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return userBalances[tokenOwner];
    }

    // transfer the balance from token owner's account to the account
    // - Owner must have sufficient balance to transfer
    function transfer(address to, uint tokens) public returns (bool success) {
        userBalances[msg.sender] = sub(userBalances[msg.sender], tokens);
        userBalances[to] = add(userBalances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // Token owner can approve for spender to transferFrom(...) tokens from token owner's account
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // Transfer tokes from one account to the other
    // - Sender's account must have sufficient balance to transfer
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        userBalances[from] = sub(userBalances[from], tokens);
        allowed[from][msg.sender] = sub(allowed[from][msg.sender], tokens);
        userBalances[to] = add(userBalances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }    

    // Returns the amount of tokens approved by the owner that can be
    // transfered to the spender's account
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // Allows token owner to approve for spender to transferFrom(...) tokens
    // from the token owner's account
    // Utilizes receiveApproval function from ApproveAndCallFallBack contract
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

    // You can't buy token with Ether
    function () external payable {
        revert();
    }

    // Allows owner to transfer out accidentally sent ERC20 Tokens
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}