# Swift Universal Turing Machine Playground
A Swift playground containing code for translating Turing a standard description string or Turing machine number into an actual working Turing machine.

In other words this is code for a Universal Turing Machine.

This is based on the paper, ["ON COMPUTABLE NUMBERS, WITH AN APPLICATION TO THE ENTSCHEIDUNGSPROBLEM," by Alan Turing, May 28, 1936](https://www.cs.virginia.edu/~robins/Turing_Paper_1936.pdf) (click link for PDF).

Specifically I used his concept of a "standard description" exactly as Turing originally devised on pp. 240-241, including a faithful handling of the example he gave on p. 241 (see below Usage).

## Usage

```swift
do {
    // Given a Turing standard description
    let sd = "DADDCRDAA;DAADDRDAAA;DAAADDCCRDAAAA;DAAAADDRDA;"
    
    // Convert it to actual functions
    let mFs = try sd.mFunctions()
    
    // Starting with some tape:
    let tape = "________________________________________"
    
    // Run the functions on the tape starting at the beginning of the tape.
    let result = mFs[1]!(tape, tape.startIndex).0
    
    // Print the result.
    print(result)
} catch {
    print(error)
}
```

Prints: `0_1_0_1_0_1_0_1_0_1_0_1_0_1_0_1_0_1_0_1_`

You may also begin from the Turing machine number:

```
let sd = "31332531173113353111731113322531111731111335317".mNumToSD()
```

For fun, I also added the ability to convert Turing machine numbers to Base 7 representations and back (-1 to each digit). This allows for interesting exploration of the numeric properties, should one be so inclined.

For example:

```
let base7 = "31332531173113353111731113322531111731111335317".
prints(base7)
```

Prints:
`20221420062002242000620002211420000620000224206`

To copy such a result out of the playground on iPad Playgrounds app:

```
import UIKit

UIPasteboard.general.string = base7
```
