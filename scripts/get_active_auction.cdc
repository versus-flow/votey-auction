// This script checks that the accounts are set up correctly for the marketplace tutorial.
//
// Account 0x01: DemoToken Vault Balance = 1050, No NFTs
// Account 0x02: DemoToken Vault Balance = 10, NFT.id = 1

import Auction, Versus from 0x01cf0e2f2f715450

/*
  Script used to get the first active drop in a versus 
 */
pub fun main(address:Address) : Versus.DropStatus?{
    // get the accounts' public address objects
    let account = getAccount(address)

    let versusCap=account.getCapability<&{Versus.PublicDrop}>(/public/Versus)
    if let versus = versusCap.borrow() {
      let versusStatuses=versus.getAllStatuses()
      for s in versusStatuses.keys {
          let status = versusStatuses[s]!
          if status.uniqueStatus.active != false {
            log(status)
            return nil
          }
      } 
    } 
  return nil

}
