// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./SimpleNft.sol";

contract DeFiLending {
    struct Loan{
        uint256 amount; 
        uint256 collateralId;
        bool repaid;
    }
    mapping(address => uint256) public deposits;
    mapping(address => Loan) public loans;
    uint256 public totalDeposits;
    uint256 public totalLoans;
    uint256 public interestRate; // Annual interest rate in basis points (1% = 100 basis points)
    SimpleNFT private simpleNFT;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event LoanCreated(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);

    constructor(address _simpleNFT, uint256 _interestRate) {
        simpleNFT = SimpleNFT(_simpleNFT);
        interestRate = _interestRate;
    }

    // Custom errors
    error NoLoanToRepay();
    error InsufficientRepaymentAmount(uint256 requiredAmount);
    error InsufficientLiquidity();
    error InsufficientBalance();
    error DepositAmountMustBeGreaterThanZero();
    error NotTheOwnerOfTheNft();
    error LoanAlreadyPaid();

    modifier amountGreaterThanZero {
        if (msg.value <= 0) {
            revert DepositAmountMustBeGreaterThanZero();
        }
        _;
    }

    modifier insufficientBalance(uint256 _amount) {
        if (deposits[msg.sender] <= _amount) {
            revert InsufficientBalance();
        }
        _;
    }

    modifier insufficientLiquidity(uint256 _amount) {
        if (totalDeposits <= totalLoans + _amount) {
            revert InsufficientLiquidity();
        }
        _;
    }

    modifier nftOwner(address _borrower, uint256 _tokenId) {
        if (simpleNFT.ownerOf(_tokenId) == _borrower) {
            revert NotTheOwnerOfTheNft();
        }
         _;
    }

    modifier noLoanToRepay() {
        if (loans[msg.sender].amount <= 0) {
            revert NoLoanToRepay();
        }
        _;
    }
    
    modifier insufficientRepayment(uint256 repaymentAmount) {
        uint256 interest = (loans[msg.sender].amount * interestRate) / 10000;
        uint256 totalRepayment = loans[msg.sender].amount + interest;
        if (repaymentAmount < totalRepayment) {
            revert InsufficientRepaymentAmount(totalRepayment);
        }
        _;
    }
    modifier loanRepaid(){
        if (loans[msg.sender].repaid) {
            revert LoanAlreadyPaid();
        }
        _;
    }
    function deposit() external payable amountGreaterThanZero {
        deposits[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) external insufficientBalance(_amount) {
        deposits[msg.sender] -= _amount;
        totalDeposits -= _amount;
        payable(msg.sender).transfer(_amount);
        emit Withdraw(msg.sender, _amount);
    }

    function borrow(uint256 _amount, uint256 _tokenId) external  insufficientLiquidity(_amount) nftOwner(msg.sender, _tokenId) {
        simpleNFT.safeTransferFrom(msg.sender, address(this), _tokenId, "");
        loans[msg.sender] = Loan ({
            amount: _amount,
            collateralId: _tokenId,
            repaid: false
        });

        totalLoans += _amount;
        payable(msg.sender).transfer(_amount);
        emit LoanCreated(msg.sender, _amount);
    }

    function repay() external payable noLoanToRepay insufficientRepayment(msg.value) loanRepaid {
        uint256 interest = (loans[msg.sender].amount * interestRate) / 10000;
        loans[msg.sender].amount = 0;
        totalLoans -= msg.value - interest;
        uint256 _tokenId = loans[msg.sender].collateralId;
        simpleNFT.transferFrom(address(this), msg.sender, _tokenId);
        emit Repay(msg.sender, msg.value);
    }

    function calculateInterest(uint256 _amount) public view returns (uint256) {
        return (_amount * interestRate) / 10000;
    }
}