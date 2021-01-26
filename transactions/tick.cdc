
import Versus from 0x01cf0e2f2f715450

/*
Simulate that the clock is running
 */
transaction(dropID: UInt64) {
    prepare(account: AuthAccount) {    
      let block=getCurrentBlock()
      if let versus = account.getCapability(/public/Versus).borrow<&{Versus.PublicDrop}>() {
          let versusStatus=versus.getStatus(dropId: dropID)
          log("currentBlock=".concat(block.height.toString()).concat( " currentTime=").concat(block.timestamp.toString()).concat( " endTime=").concat(versusStatus.endTime.toString()).concat(" timeRemaining=").concat(versusStatus.timeRemaining.toString()))
      }
  }
}