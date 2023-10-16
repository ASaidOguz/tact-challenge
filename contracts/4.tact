import "@stdlib/deploy";

/*
  TASK 4 - NFT locker contract 
  Implement smart contract that will lock NFT for a period of time to be set by the owner.
  Smart conrtact should contain logic to process following Transactions and getters: 

  Transactions: 
  * OwnershipAssigned
   - Recives nft + time (in a forwardPayload message as uint32) for which this nft will be locked + address of the sender of the nft (prevOwner).
   - If sc already hold an nft then return incoming nft back to sender
  * NftWithdrawal
   - Request to withdrawal stored nft
   - If sender not an owner (that came from OwnershipAssigned as prevOwner) address then throw "Invalid sender" 
   - If time is not passed then send tx back to sender with message "NFT is still locked" in the body 
   - If all good then send stored nft back to owner with all remaining TON balance

  Getters:
  * time
   - get how much lock time is left
  * nft
   - get address of locked nft 
  * owner
   - get owner of locked nft (that came from OwnershipAssigned as prevOwner)
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
  const forward_ton_amount: Int =ton("0.05");
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
                mode: SendIgnoreErrors,
                body: Transfer{     queryId: msg.queryId, 
                                    newOwner: msg.prevOwner,
                                    responseDestination: msg.prevOwner, 
                                    customPayload: null, 
                                    forwardAmount: self.forward_ton_amount, 
                                    forwardPayload: emptySlice()}.toCell()
            });
            return;
    }
    self.prevowner=msg.prevOwner;
    self.lockedNftAddress=sender();
    self.timeOfLock=now();
    self.lockingTime=msg.forwardPayload.loadUint(32);
    return;
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
                                    forwardAmount: self.forward_ton_amount, 
                                    forwardPayload: emptySlice()}.toCell()
            });
            self.lockedNftAddress=null;
            self.prevowner=null;
            self.lockingTime=null;
            self.timeOfLock=null;
            return;
    }else{
      
      self.reply("NFT is still locked".asComment());
      return;
    }
  }

  fun nftUnlocked(): Bool{
    let time_remaining:Int=now()-(self.lockingTime!!+self.timeOfLock!!);
    if(time_remaining > 0){
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
