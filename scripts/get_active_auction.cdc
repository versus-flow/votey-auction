// This script checks that the accounts are set up correctly for the marketplace tutorial.
//

import Auction, Versus from 0x1ff7e32d71183db0

/*
  Script used to get the first active drop in a versus 
 */
pub fun main(address:Address) : Versus.DropStatus?{

    return Versus.getActiveDrop(address)
}
