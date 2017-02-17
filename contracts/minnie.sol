pragma solidity ^0.4.2;

/* Browser solidity addresses
   0xca35b7d915458ef540ade6068dfe2f44e8fa733c
   0x14723a09acff6d2a60dcdf7aa4aff308fddc160c
   0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db
   0x583031d1113ad414f02576bd6afabfb302140225
   0xdd870fa1b7c4700f2bd7f44238821c26f7392148
*/

//Abstract contracts for inheritence
contract Owned {
    address public owner;
	// Contract owner. It can be an ethereum account (a real people) or a
	// contract setting governance rules

    event OwnerChanged(
        address newOwner,
        address previousOwner
    );

    //functions using onlyOwner can only be used from the owner address
    modifier onlyOwner {
        if (msg.sender != owner){throw;} //Consumes all gas
        _;
    }

    // Allow to change owner to allow change in governance
    function changeOwner(address newOwner) onlyOwner {
        OwnerChanged(newOwner,owner); //Trigger event OwnerChanged
        owner=newOwner;
    }

    function Owned() {
        owner=msg.sender;
    }
}

contract BankTrusted is Owned {
     MinnieBank public tokenBank;

     function BankTrusted(MinnieBank bankAddress) {
        tokenBank=bankAddress;
     }

    //// Modifier functions
    modifier onlyContributor {
        if (!tokenBank.isKnownContributor(msg.sender)){throw;} //Consumes all gas
        _;
    }

    event BankChanged(
        address newBank,
        address previousBank
    );

    // Allow to change owner to allow change in governance
    function changeBank(MinnieBank newBank) onlyOwner {
        BankChanged(newBank,tokenBank); //Trigger event OwnerChanged
        tokenBank = newBank;
    }

    function isTrusted() constant returns(bool) {
        for(uint i = 0; i < tokenBank.trustedAddressesCount(); i++) {
            if(tokenBank.trustedAddresses(i) == address(this)){return true;}
        }
        return false;
    }
}

contract MinnieBank is Owned {
    /* -
    This contract registers known contributors and their balances

    ToDo :
     - Add Givable Token
    */

    //////// VARIABLES AND CONSTANT FUNCTIONS

    address[] public contributors;
	// contributors is the list of contributor's ethereum account's address

    mapping(address => uint) public balanceOf;
	// Store the balance of each contributors
	// Token CAN NOT be split in less than 1 token

    address[] public trustedAddresses;
	// List of trusted contracts allowed to change contributors balances
	// Can only be change by the owner

    //Convenience functions to lookup public arrays
    //Constant functions : does not change state, doesn't need a transaction
    function contributorsCount() constant returns(uint){
        return contributors.length;
    }
    function trustedAddressesCount() constant returns(uint){
        return trustedAddresses.length;
    }

    //Check if the given address is a registered contributor
    //Constant function : does not change state, doesn't need a transaction
    function isKnownContributor(address contributor) constant returns(bool){
        for(uint i = 0; i < contributors.length; i++) {
            if (contributors[i] == contributor) {return true;}
        }
        return false;
    }

    //Get total token of all contributors
    //Constant function : does not change state, doesn't need a transaction
    //Note : Other functions MUST ensure that all Token holders are registered
    //contributors
    function totalSupply() constant returns(uint){
        uint supply=0;
        for(uint i = 0; i < contributors.length; i++) {
            supply = supply + balanceOf[contributors[i]];
        }
        return supply;
    }

    /////// Deployment function

    //Set initial state
    function MinnieBank(){
        trustedAddresses.push(owner); //Owner is a trusted address


        // DEV BLOCK
        // Uncomment this block in development to quickly initialise the state

        address contrib1 = 0x14723a09acff6d2a60dcdf7aa4aff308fddc160c;
        address contrib2 = 0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db;

        registerContributor(contrib1);
        registerContributor(contrib2);

        addTokenTo(contrib1,1500);
        addTokenTo(contrib2,400);
        // END DEV BLOCK



    }

    //////// MODIFIERS



    //functions using onlyTrusted can only be used from an address from trustedAddresses
    //Note : Owner address is ALWAYS a trusted address
    modifier onlyTrusted {
        bool present=false;
        for(uint i = 0; i < trustedAddresses.length; i++) {
            if(trustedAddresses[i] == msg.sender){present=true;}
        }
        if (!present){throw;} //Consumes all gas
        _;
    }

    //functions using onlyContributor can only be used from a registered contributor
    modifier onlyContributor {
        if (!isKnownContributor(msg.sender)){throw;} //Consumes all gas
        _;
    }

    //////// Events
    // Event can be watch by ethereum clients to trigger actions outside of the Ethereum VM

    event TrustedAddressAdded(
        address trustedAddress,
        uint index
    );

    event TrustedAddressRemoved(
        address trustedAddress
    );

    event ContributorAdded(
        address contributor,
        uint index
    );

    event ContributorRemoved(
        address contributor
    );

    event BalanceChanged(
        address contributor,
        uint newBalance
    );

    event TokenSupplyChanged(); //Do not indicate new supply since it will increase transaction gas cost

    //////// FUNCTIONS

    //// Admin Functions

    function addTrustedAddress(address newTrusted) onlyOwner returns(uint index) {
        trustedAddresses.push(newTrusted);
        TrustedAddressAdded(newTrusted,trustedAddresses.length-1);
        return trustedAddresses.length-1; //Return new address index
    }

    function removeTrustedAddress(address trustedAddress) onlyOwner {
        if(trustedAddress==owner){throw;} // you can't remove remove owner from trusted addresses

        uint index;
        bool found = false;
        for (uint j =0 ; j<trustedAddresses.length; j++){
            if(trustedAddress==trustedAddresses[j]){
                found=true;
                index=j;
                break;
            }
        }

        TrustedAddressRemoved(trustedAddress);
        delete trustedAddresses[index];
        //WARNING : trustedAddresses length is not changed, trustedAddresses[index] is
        //set to "0x0"
    }

    function changeOwner(address newOwner) onlyOwner {
        address oldOwner=owner; // Have to store it since we can't remove owner from trusted addresses
        addTrustedAddress(newOwner);
        Owned.changeOwner(newOwner);
        removeTrustedAddress(oldOwner);
    }

    //Register a new contributors. Onwer only. Change in registration process can
    //be made in owner contract
    function registerContributor(address contributor) onlyOwner returns(uint index) {
        if(isKnownContributor(contributor)){return;}
        contributors.push(contributor);
        ContributorAdded(contributor,contributors.length-1);
        return contributors.length-1; //Return new address index
    }

    function removeContributor(address contributor) onlyOwner  {
        uint index;
        bool found = false;
        for (uint j =0 ; j<contributors.length; j++){
            if(contributor==contributors[j]){
                found=true;
                index=j;
                break;
            }
        }
        if(found){
            // Contributor MUST have an empty balance to be removed
            if (balanceOf[contributor]>0) {throw;}
            ContributorRemoved(contributor);
            for (uint i = index; i<contributors.length-1; i++){
                contributors[i] = contributors[i+1];
            }
            delete contributors[contributors.length-1];
            contributors.length--;
        } else {
            //unknown contributor
            return;
        }

    }

    //// Trusted Functions

    // Add Token to a registered contributor (increase TotalSupply)
    function addTokenTo(address contributor, uint amount) onlyTrusted returns(uint newBalance) {
        // You can only add token to registered contributors
        if (!isKnownContributor(contributor)){throw;} //Consumes all gas
        balanceOf[contributor]+=amount;
        BalanceChanged(contributor,balanceOf[contributor]);
        TokenSupplyChanged();
        return balanceOf[contributor];
    }

    // Remove Token from registered contributor (decrease TotalSupply)
    function removeTokenFrom(address contributor, uint amount) onlyTrusted returns(uint newBalance) {
        // You can only add token to registered contributors
        if (!isKnownContributor(contributor)){throw;} //Consumes all gas
        if(balanceOf[contributor]>amount){
            balanceOf[contributor]-=amount;
        } else {
            balanceOf[contributor]=0;
        }
        BalanceChanged(contributor,balanceOf[contributor]);
        TokenSupplyChanged();
        return balanceOf[contributor];
    }

    //// Contributor functions

    // Transfer token to an other contributor
    function transferTo(address contributor, uint amount) {
        if (!isKnownContributor(contributor)){throw;} //Consumes all gas
        if (balanceOf[msg.sender]<amount){throw;} //Ensure sender have enougth tokens

        balanceOf[msg.sender]-=amount;
        balanceOf[contributor]+=amount;
        BalanceChanged(msg.sender,balanceOf[msg.sender]);
        BalanceChanged(contributor,balanceOf[contributor]);
    }

}

contract PeriodicContributionReporter is Owned, BankTrusted{
    /* -
    This contract registers contributions reports of known contributors
    It also rewards contributors once the period is closed

    ToDo :
     - Add events
     - Add givable tokens
     - Allow owner to registered a contribution for a closed period (and reward the targeted contributor)

    */

    // Describe a period
    struct Period {
        address[] contributors;
        mapping(address=>uint) reports;
        bool payedOut;
    }

    //Set price for each score
    // Initial values are set in initializer function
    mapping(uint => uint) public rewardForScore;
    mapping(uint => Period) public periods;

    // Period length in seconds
    uint constant PERIOD_LENGTH = 604800;
    // 1 week = 604800
    // 5 mins = 300 (test purpose)

    // When do we change period ?
    uint constant TIMESTAMP_OFFSET = 345600;
    /*
    0	    Thursday 00:00 GMT
    6400	Friday 00:00 GMT
    172800	Saturday 00:00 GMT
    259200	Sunday 00:00 GMT
    345600	Monday 00:00 GMT
    432000	Tuesday 00:00 GMT
    518400	Wednesday 00:00 GMT
    */
    // Return current period number (number of periods since Epoch+Offset)
    function currentPeriodNumber() constant returns(uint) {
        return (now-TIMESTAMP_OFFSET)/604800;
    }

    // Adds up all scores for a given period
    function totalScoreForPeriod(uint period) constant returns(uint){
        uint score=0;
        for(uint i = 0; i<periods[period].contributors.length; i++ ){
            score+=periods[period].reports[periods[period].contributors[i]];
        }
        return score;
    }

    event Report(
        uint period,
        address contributor,
        uint score
    );

    event Payout(
        uint period
    );

    event RewardScoreChanged (
      uint score,
      uint newReward,
      uint previousReward
    );

    //INITIALIZER
    function PeriodicContributionReporter(MinnieBank bank) BankTrusted(bank) {

        // Set reward for each score reported
        // We may choose to pay for it since the contributor
        // made the effort of reporting a non worked week
        rewardForScore[0]=0;
        rewardForScore[1]=100;
        rewardForScore[2]=250;
        rewardForScore[3]=500;

        //Scores above 3 do not exists and are therefore not rewarded
    }


    function reportContributionFor(address contributor,uint score) {

        if(!(contributor==msg.sender || owner==msg.sender )){throw;}

        // If contributor wasn't registered for this period, register it
        bool alreadyRegistered = false;
        for(uint i = 0; i<periods[currentPeriodNumber()].contributors.length; i++ ){
            if(periods[currentPeriodNumber()].contributors[i]==contributor){alreadyRegistered=true;}
        }
        if(!alreadyRegistered){
            periods[currentPeriodNumber()].contributors.push(contributor);
        }

        // Update report
        periods[currentPeriodNumber()].reports[contributor]=score;
        Report(currentPeriodNumber(),contributor,score);
    }

    // Report a contribution for the current period
    // If a report already existed, update it
    function reportContribution(uint score) onlyContributor {
        reportContributionFor(msg.sender,score);
    }

    //Anyone can trigger a payout since only contributors are rewarded
    function payOut(uint periodNumber) {
        // You can only pay out a closed period
        if(periodNumber >= currentPeriodNumber()){ throw; }

        // You can't pay out a period already payed out
        if(periods[periodNumber].payedOut) {throw;}
        periods[periodNumber].payedOut=true;

        Payout(periodNumber);

        // Pay each contributors
        for(uint i = 0; i<periods[periodNumber].contributors.length; i++ ){
            address contributor = periods[periodNumber].contributors[i] ;
            tokenBank.addTokenTo(contributor, rewardForScore[periods[periodNumber].reports[contributor]]);
        }
    }

    // Owner address can change rewards
    function changeRewardForScore(uint score, uint reward) onlyOwner {
        RewardScoreChanged(score,rewardForScore[score],reward);
        rewardForScore[score]=reward;
    }

}

contract MoneyPrinterContract is Owned, BankTrusted {
    /* -
    This contract has only test purposes and MUST NOT be trusted in production

    It allows to easily grant token to a registered contributor
    */

    function MoneyPrinterContract(MinnieBank bank) BankTrusted(bank) {}

    function grantTokenTo(address contributor, uint amount) onlyOwner {
        tokenBank.addTokenTo(contributor, amount);
    }
}