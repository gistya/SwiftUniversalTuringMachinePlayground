/// Universal Turing machine playground (c) 2020 Jonathan Gilbert
/// Version 0.1
/// Created entirely on iPad.
///
/// Scroll to the bottom for usage.
///
/// MIT Open source license:
/**
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import Foundation
import UIKit

enum SDErr: Error {
    case orphanA
    case orphanC
    case unhandled
}

extension String {
    /// Convert a Base 7 number string to a Turing machine-number string.
    /// Non-conforming chars are converted to zeroes.
    func base7ToMNum() -> String {
        self.map { (c) -> String.Element in
            switch c {
            case "0": return "1"
            case "1": return "2"
            case "2": return "3"
            case "3": return "4"
            case "4": return "5"
            case "5": return "6"
            case "6": return "7"
            default: return "0"
            }
        }.reduce("") { $0 + "\($1)" }
    }
    
    /// Convert a Turing machine-number string to a Base 7 number string. 
    /// Non-conforming chars are converted to zeroes.
    func mNumToBase7() -> String {
        self.map { (c) -> String.Element in
            switch c {
            case "1": return "0"
            case "2": return "1"
            case "3": return "2"
            case "4": return "3"
            case "5": return "4"
            case "6": return "5"
            case "7": return "6"
            default: return "0"
            }
        }.reduce("") { $0 + "\($1)" }
    }
    
    /// Convert a Turing machine-number string to a Turing standard description string.
    /// Non-conforming chars are converted to Ns.
    func mNumToSD() -> String {
        self.map { (c) -> String.Element in
            switch c {
            case "1": return "A"
            case "2": return "C"
            case "3": return "D"
            case "4": return "L"
            case "5": return "R"
            case "6": return "N"
            case "7": return ";"
            default: return "N"
            }
        }.reduce("") { $0 + "\($1)" }
    }
    
    /// Convert a Turing machine standard description string from letter-encoded format
    /// to a format of the type `q#S#S#Xq#` where # is an int and X is L, R, or N.
    /// Throws an error if somethin' ain't right.
    func sdToQ() throws -> String {
        var sBuff = -1 // C
        var qBuff = -1 // A
        var buff = ""
        for c in self {
            func process(_ c: Character) throws {
                switch (c, sBuff, qBuff) {
                // after a D we get A
                case let ("A", s, q) where s < 1 && q > -1:
                    qBuff += 1
                    sBuff = -1
                    
                // after a D we get C
                case let ("C", s, q) where s > -1 && q < 1:
                    sBuff += 1
                    qBuff = -1
                    
                // after a D we get non-A/C
                case let (c, 0, 0):
                    sBuff = -1
                    qBuff = -1
                    buff += "S0"
                    try process(c)
                    
                // Get an unexpected A
                case ("A", _, -1): throw SDErr.orphanA
                    
                // Get an unexpected C
                case ("C", -1, _): throw SDErr.orphanC
                    
                // Terminate q
                case let (c, s, q) where q > 0 && s == -1:
                    buff += "q\(q)"
                    qBuff = -1
                    try process(c)
                    
                // Terminate S
                case let (_, s, -1) where s > 0 && s < 3:
                    buff += "S\(s)"
                    sBuff = -1
                    try process(c)
                    
                // Handle a valid D, L, N, R, or ;
                case (_, -1, -1): 
                    switch c {
                    case "D": 
                        qBuff = 0
                        sBuff = 0
                        
                    default: buff += "\(c)"
                    }
                    
                default: throw SDErr.unhandled
                }
            }
            try process(c)
        }
        return buff
    }
    
    /// Converts a Turing standard description string into a dict of actual
    /// string manipulation functions (Turing machine functions).
    /// - Returns: a dict of `[Int: MacineFunction]` 
    /// - Throws: an error if the standard description is malformed
    func mFunctions() throws -> [Int: MachineFunction] {
        let qStr = try self.sdToQ()
        let qs = qStr.split(separator: ";")
        
        var qfs = [Int: MachineFunction]()
        for q in qs {
            var q = q.map { $0 }
            let qn = Int("\(q[1])")!
            func xlate(_ sNum: String) throws -> String {
                switch sNum {
                case "0": return "_"
                case "1": return "0"
                case "2": return "1"
                default: throw SDErr.unhandled
                }
            }
            
            /// Offset on the tape.
            enum Offset {
                /// Left of current index
                case before
                /// Same position
                case same
                /// Right of current index
                case after
            }
            
            /// Translate an offset (R, N, or L) to an offset enumeration case.
            /// - Parameter oChar: "R", "N", or "L"
            /// - Returns: `Offset` case
            /// - Throws: error if input char does not match
            func xlateOffset(_ oChar: String) throws -> Offset {
                switch oChar {
                case "R": return .after
                case "N": return .same
                case "L": return .before
                default: throw SDErr.unhandled
                }
            }
            
            let check = try xlate("\(q[3])") 
            let write = try xlate("\(q[5])")
            let offset = try xlateOffset("\(q[6])")
            
            var f: MachineFunction = { (str, idx) in 
                print(idx.utf16Offset(in: str))
                var str = str
                print(str)
                
                // Make sure we don't run out of tape...
                guard !(idx == str.endIndex) else {
                    return (str, idx)
                }
                
                let test = "\(str[idx])"
                
                let newIdx = { () -> String.Index in 
                    switch offset {
                    case .before: return str.index(idx, offsetBy: -1)
                    case .same: return idx
                    case .after: return str.index(idx, offsetBy: 1)
                    }
                }()
                
                guard test == check || check == "_" else {
                    return qfs[qn]!(str, newIdx)
                }
                
                str = str.replacingCharacters(in: idx ..< str.index(after: idx), with: write)
                
                let nextFunctionNumber = Int("\(q[8])")!
                
                return qfs[nextFunctionNumber]!(str, newIdx)
            }
            qfs[qn] = f
        }
        return qfs
    }
}

typealias MachineFunction = (String, String.Index) -> (String, String.Index)

do {
    // Given a Turing standard description
    let sd = "DADDCRDAA;DAADDRDAAA;DAAADDCCRDAAAA;DAAAADDRDA;"
    
    // Convert it to actual functions
    let mFs = try sd.mFunctions()
    
    // Starting with some tape:
    let tape = "________________________________________"
    print("Tape length: \(tape.count)")
    
    // Run the functions on the tape starting at the beginning of the tape.
    let result = mFs[1]!(tape, tape.startIndex).0
    
    // Print the result.
    print(result)
    print("Result length: \(result.count)")
    UIPasteboard.general.string = result
} catch {
    print(error)
}

// Fun with numbers: convert Turing machine number to base 7 string 
let base7 = "31332531173113353111731113322531111731111335317".mNumToBase7()
print(base7)
UIPasteboard.general.string = base7 
