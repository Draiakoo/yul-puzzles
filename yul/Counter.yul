/*
 *        __      __            __                                                __
 *       /  \    /  |          /  |                                              /  |
 *       $$  \  /$$/  __    __ $$ |        ______   __    __  ________  ________ $$ |  ______    _______
 *        $$  \/$$/  /  |  /  |$$ |       /      \ /  |  /  |/        |/        |$$ | /      \  /       |
 *         $$  $$/   $$ |  $$ |$$ |      /$$$$$$  |$$ |  $$ |$$$$$$$$/ $$$$$$$$/ $$ |/$$$$$$  |/$$$$$$$/
 *          $$$$/    $$ |  $$ |$$ |      $$ |  $$ |$$ |  $$ |  /  $$/    /  $$/  $$ |$$    $$ |$$      \
 *           $$ |    $$ \__$$ |$$ |      $$ |__$$ |$$ \__$$ | /$$$$/__  /$$$$/__ $$ |$$$$$$$$/  $$$$$$  |
 *           $$ |    $$    $$/ $$ |      $$    $$/ $$    $$/ /$$      |/$$      |$$ |$$       |/     $$/
 *           $$/      $$$$$$/  $$/       $$$$$$$/   $$$$$$/  $$$$$$$$/ $$$$$$$$/ $$/  $$$$$$$/ $$$$$$$/
 *                                       $$ |
 *                                       $$ |
 *                                       $$/
 *   
 *   
 *          *    Ho Ho Ho MFs! Santa Clause is comin' to town y'all crazy people! And he's lookin' for some
 *         ***    naughty folks to have a party with. Santa is bullish on crypto, so he decides to put party
 *        *****    counter on-chain. But, because he's a busy guy, you have to help him and write required smart
 *       *******    contract. Remember, all naughty people use Yul, so you should better use the same. GLHF!
 *      *********
 *     ***********
 *    *************
 *   ***************
 *         |||
 *         |||
 *   
 *   * The code has to conform to the following interface (and comments):
 *   ```
 *     interface ICounter {
 *         function increase() external;
 *         function decrease(uint64 amount) external; // only owner can invoke it. Check for underflow conditions
 *         function counter() external returns (uint96); // counter and owner have to occupy single storage slot
 *         function owner() external returns (address); // this contract owner's address
 *     }
 *   ```
 *   
 *   * Because Santa is a cheapskate, he wants you to put owner and counter in one storage slot:
 *         96 bits counter                   160 bits addres
 *   |------------------------|----------------------------------------|
 *   
 *   * If you want to check if your code works as expected, look at the test cases in test/Counter.
 *   
 *   * To run this beautiful guy, execute:
 *   forge test -vvv --match-test 'Counter'
 * */

object "Counter" {
  code {
    // YOUR CUSTOM CONSTRUCTOR LOGIC GOES HERE

    sstore(0, caller())   // store msg.sender at slot 0

    // copy all runtime code to memory
    datacopy(0, dataoffset("Runtime"), datasize("Runtime"))

    // return code to be deployed
    return(0, datasize("Runtime"))
  }
  object "Runtime" {
    code {
      // YOUR CODE GOES HERE

      if gt(callvalue(), 0) {
        revert(0, 0)
      }

      switch getSelector()          
      case 0xe8927fbc{            // increase() selector
        // cache the slot 0
        let slot0 := sload(0)
        let counter := add(getCounter(slot0), 1)
        sstore(0, or(shr(160, counter), getOwner(slot0)))
      }
      case 0x9732187d{            // decrease(uint64 amount) selector
        // check if the calldata size is correct. must contain 4 bytes (selector) + 32 bytes (argument, even though it is 8 bytes)
        if lt(calldatasize(), 36) {
          revert(0, 0)
        }

        let amountToDecrease := calldataload(0x04)

        // check if the argument is greater than uint64
        if gt(amountToDecrease, 0xffffffffffffffff) {
          revert(0, 0)
        }

        let slot0 := sload(0)
        // check if sender is the owner, if not revert
        if iszero(eq(getOwner(slot0), caller())) { revert(0, 0) }
        let counter := getCounter(slot0)

        // check for substraction underflow
        if gt(amountToDecrease, counter){
          revert(0, 0)
        }

        counter := sub(counter, amountToDecrease)

        sstore(0, or(shr(counter, 160), getOwner(slot0)))
      }
      case 0x61bc221a{            // counter() selector
        let counter := getCounter(sload(0))
        mstore(0x0, counter)
        return(0x0, 12)
      }
      case 0x8da5cb5b{            // owner() selector
        let owner := getOwner(sload(0))
        mstore(0, owner)
        return(0, 0x20)
      }
      default {
        revert(0, 0)
      }
      

      function getSelector() -> selector {
        selector := shr(224, calldataload(0))
      }

      function getOwner(content) -> owner {
        owner := shl(96, shr(96, content))
      }

      function getCounter(content) -> counter {
        counter := shl(160, content)
      }
    }
  }
}
