import "@stdlib/deploy";

/*
  TASK 4 - NFT locker
  Implement a smart contract that will lock NFT for a period of time specified by the owner.
  Smart conrtact should contain logic to process following messages and getters: 

  Messages: 
  * OwnershipAssigned
   - Recives nft + time (in a forwardPayload message as uint32) for which this nft will be locked + address of the sender of the nft (prevOwner).
   - If the smart contract already holds an nft then return the incoming nft back to the sender
  * NftWithdrawal
   - Request withdrawal of the locked nft
   - If sender is not the owner (that came from OwnershipAssigned as prevOwner address) then throw "Invalid sender" 
   - If time has not passed then send message back to the sender with the comment "NFT is still locked" according to the TON's "message with text comment" standard 
   - Otherwise (all good) send the locked nft back to the owner with all the remaining TON balance
   Note that the order of checks is important
   (in case: "sender is not the owner" and "time has not passed" at the same time, "Invalid sender" error takes priority)

  Getters:
  * time
   - get how much lock time is left
  * nft
   - get the address of the locked nft 
  * owner
   - get the owner of the locked nft (that came from OwnershipAssigned as prevOwner)
*/

message(0x05138d91) OwnershipAssigned {
    queryId: Int as uint64;
    prevOwner: Address;
    forwardPayload: Slice as remaining; 
}

message(0x5fcc3d14) Transfer { 
    queryId: Int as uint64;            
    newOwner: Address; 
    responseDestination: Address; 
    customPayload: Cell?; 
    forwardAmount: Int as coins; 
    forwardPayload: Slice as remaining; 
}

message NftWithdrawal {
  queryId: Int as uint64;
  nftAddress: Address;
}

contract Task4 with Deployable {
 
  seed: Int as uint128;

  prevowner: Address?;
  lockedNftAddress: Address?;
  timeOfLock: Int? as int128;
  lockingTime: Int? as int128;

  init(seed: Int) {
    self.seed = seed;
  }

  //locking nft message here...
  receive(msg: OwnershipAssigned) { 
    
    if(self.prevowner !=null){
     send(SendParameters{
                to: sender(),
                value: 0,
                mode: SendIgnoreErrors+SendRemainingValue,
                body: Transfer{     queryId: msg.queryId, 
                                    newOwner: msg.prevOwner,
                                    responseDestination: msg.prevOwner, 
                                    customPayload: null, 
                                    forwardAmount: 0,
                                    forwardPayload: emptySlice()}.toCell()
            });
            return;
    }
    self.prevowner=msg.prevOwner;
    self.lockedNftAddress=sender();
    self.timeOfLock=now();
    self.lockingTime=msg.forwardPayload.loadUint(32);
   // return;
  }

  //try to withdrawal the nft if conditions r met...
  receive(msg: NftWithdrawal) {
   
    require(sender()==self.prevowner,"Invalid sender");
    require(self.lockedNftAddress==msg.nftAddress,"Invalid nft");
    if(self.nftUnlocked()){
           send(SendParameters{
                to: msg.nftAddress,
                value: 0,
                mode: SendRemainingBalance+SendIgnoreErrors,
                body: Transfer{     queryId: msg.queryId, 
                                    newOwner: sender(),
                                    responseDestination: sender(), 
                                    customPayload: null, 
                                    forwardAmount:0, 
                                    forwardPayload: emptySlice()}.toCell()
            });
            self.lockedNftAddress=null;
            self.prevowner=null;
            self.lockingTime=null;
            self.timeOfLock=null;
           // return;
    }else{
      
      self.reply("NFT is still locked".asComment());
      return;
    }
  }
  //unlock logic -> equal 0 ??
  fun nftUnlocked(): Bool{
    let time_remaining:Int=now()-(self.lockingTime!!+self.timeOfLock!!);
    if(time_remaining >= 0){
      return true;
    }
    return false;
  }
  // absolute real values ??? use !! for setting it??
  get fun time(): Int {
    if(self.timeOfLock==null){
      return 0;
    }
    let time_remaining:Int=now()-(self.lockingTime!!+self.timeOfLock!!);
    if(time_remaining > 0){
      return 0;
    }
    return (time_remaining)*(-1);
  }

  get fun nft(): Address? {
    return self.lockedNftAddress;
  }

  get fun owner(): Address? {
    return self.prevowner;
  }
}
