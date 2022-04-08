//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.5.0 <0.9.0;

contract CrowdFunding{
    mapping(address=>uint) public contributors;
    address public admin;
    uint public noOfContributors;
    uint minimumContribution;
    uint public deadline;
    uint public goal;
    uint public raisedAmount;
    
    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address=>bool)voters;//true=voted,false=no vote
    }
    
    mapping(uint=>Request)public requests;//storing different requests as mapping, We cannot store it as a array
                                         //bcoz Struct has a member of type mapping 
    uint public numRequests;
    
    //declaring the events--Note event name must start with the uppe case
    event ContributeEvent(address _sender, uint _value);
    event CreateRequestEvent(string _description, address _recipient, uint _value);
    event MakePaymentEvent(address _recipient, uint _value);
    
    
    constructor(uint _goal,uint _deadline){
        goal=_goal;
        deadline=block.timestamp+ _deadline;// if _deadline=3600 then deadline isin 1 hr
        minimumContribution=100 wei;
        admin=msg.sender;
    }
    
    function contribute()public payable{
        require(block.timestamp<deadline,"Deadline has passed");
        require(msg.value>=minimumContribution,"Minimum contribution not met!");
        
        if(contributors[msg.sender]==0){ //contributor can contribute multiple times,but we add count of him only once
            noOfContributors++;
        }
        contributors[msg.sender]+=msg.value;
        raisedAmount+=msg.value;
        
        emit ContributeEvent(msg.sender, msg.value);//emitting the event-JS callback function hears this and updates the data in the UI 
    }
    receive() payable external{
        contribute();
    }
    
    function getBalance()public view returns(uint){
        return address(this).balance;
    }
    
    function getRefund()public{
        require(block.timestamp> deadline && raisedAmount<goal);
        require(contributors[msg.sender]>0); //only a contributor can ask for refund (so ofcourse balance of contributor>0)
        
        address payable recipient=payable(msg.sender);// converting recipient address to payable address
        uint value=contributors[msg.sender]; //getting contributors respective ETH balance
        recipient.transfer(value);
        
        contributors[msg.sender]=0;//setting ETH balance of contributor to 0 after transfer;
    }
    modifier onlyAdmin(){
        require(msg.sender==admin,"Only admin can call this function");
        _;
    }
    //creating function to instantiate struct
    function createRequest(string memory _description,address payable _recipient,uint _value) public onlyAdmin{
        Request storage newRequest=requests[numRequests];// struct contains a nested mapping hence needs to declared as storage
        numRequests++;
        newRequest.description=_description;
        newRequest.recipient=_recipient;
        newRequest.value=_value;
        newRequest.completed=false;
        newRequest.noOfVoters=0;
        
        emit CreateRequestEvent(_description, _recipient, _value);
    }
    
    
    function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender]>0,"you must be a contributor to vote!");
        Request storage thisRequest=requests[_requestNo];
        thisRequest.voters[msg.sender]=true;
        thisRequest.noOfVoters++;
    }
    
    function makePayment(uint _requestNo) public onlyAdmin{
        require(raisedAmount>=goal);
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.completed==false,"The request has been completed!");
        require(thisRequest.noOfVoters>noOfContributors/2);//50% voted for this request
        
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed=true;
        
        emit MakePaymentEvent(thisRequest.recipient, thisRequest.value);
    }
    
    
}