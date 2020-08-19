
import Versus from 0x045a1763c93006ca

transaction(dropID: UInt64) {
    prepare(account: AuthAccount) {    
      log("CurrentBlock")
      log(getCurrentBlock().height)

      if let versusCap = account.getCapability(/public/Versus) {
        if let versus = versusCap.borrow<&{Versus.PublicDrop}>() {
            let versusStatus=versus.getStatus(dropId: dropID)
            log("Acution end block")
            log(versusStatus.endBlock)
        }
    } 
  }
}