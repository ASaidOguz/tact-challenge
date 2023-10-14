import "@stdlib/deploy";

/*
  TASK 2 - Proxy contract 
  Create a contract that forwards all messages sent and tokens received 
  to the admin contract (the address will be set in init_store).
  Transaction from proxy contract to admin contrac should contain
    - Address, of user who sended trx (should be stored in the body cell).
    - Original message that proxy smart contract recived from user (should be stored in the first ref in the outcoming body).
  Also, if admin contract will bounce message (Bounced / opcode 0x44), then you need to send all ton`s back to user.
  User address will be given in bounced msg body as "sender".
*/

message(0x44) Bounced {
  queryId: Int as uint64;
  sender: Address;
}

contract Task2 with Deployable {
  admin: Address;

  init(admin: Address) {
    self.admin = admin;
  }
  
  receive(msg: Bounced) {
    let ctx:Context=context();
    let msg_value:Int=ctx.value;
    let money_cell:Cell=beginCell().
                        storeCoins(msg_value).
                        endCell();
send(SendParameters{
    to: msg.sender,
    value: 0, 
    mode: SendIgnoreErrors+SendRemainingValue, 
    bounce: true, 
    body: money_cell
});

  }

  receive(msg: Slice) {
    let ctx:Context=context();
    let sender:Address=ctx.sender;
    let msg_value:Int=ctx.value;
    //constract cell from msg slice;
    let forwarded_msg:Cell=beginCell().
                           storeSlice(msg).
                           endCell();

    //constract msg_body for forwarding msg;
    let msg_body:Cell=beginCell().
                      storeAddress(sender).
                      storeCoins(msg_value).
                      storeRef(forwarded_msg).
                      endCell();

send(SendParameters{
    to: self.admin,
    value: 0, 
    mode: SendIgnoreErrors+SendRemainingValue, 
    bounce: true, 
    body: msg_body
});
  }
}
