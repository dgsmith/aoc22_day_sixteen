import Darwin
import Foundation
import Algorithms

var valves = Set<Valve>()
var startValve: Valve?

let filePath = "/Users/graysonsmith/code/advent_of_code/2022/aoc22_day_sixteen/input.txt"
guard let filePointer = fopen(filePath, "r") else {
    preconditionFailure("Could not open file at \(filePath)")
}
var lineByteArrayPointer: UnsafeMutablePointer<CChar>?
defer {
    fclose(filePointer)
    lineByteArrayPointer?.deallocate()
}
var lineCap: Int = 0
while getline(&lineByteArrayPointer, &lineCap, filePointer) > 0 {
    let line = String(cString:lineByteArrayPointer!)
    
    let valveMatches = line.matches(of: #/[[:upper:]]{2}/#)
    let flowRateMatch = line.firstMatch(of: #/=(\d+)/#)
    
    let flowRate = Int(flowRateMatch!.output.1)!
//    print(flowRate)
    
    var main: Valve?
    for match in valveMatches {
        let valveName = String(match.output)
//        print(valveName)
        
        if let main {
            if let foundValve = valves.first(where: { $0.name == valveName }) {
                main.connections.insert(foundValve)
                foundValve.connections.insert(main)
                
            } else {
                let newValve = Valve(name: valveName, connection: main)
                main.connections.insert(newValve)
                valves.insert(newValve)
            }
            
        } else {
            if let foundMain = valves.first(where: { $0.name == valveName }) {
                foundMain.flowRate = flowRate
                main = foundMain
                
            } else {
                main = Valve(name: valveName, flowRate: flowRate)
                valves.insert(main!)
                
                if main!.name == "AA" {
                    startValve = main!
                }
            }
        }
    }
}

class Valve: Hashable, CustomStringConvertible {
    let name: String
    var flowRate: Int = 0
    
    var connections = Set<Valve>()
    
    init(name: String, flowRate: Int, connections: [Valve]) {
        self.name = name
        self.flowRate = flowRate
        self.connections = Set<Valve>(connections)
    }
    
    convenience init(name: String, flowRate: Int) {
        self.init(name: name, flowRate: flowRate, connections: [Valve]())
    }
                
    convenience init(name: String, connection: Valve) {
        self.init(name: name, flowRate: 0, connections: [connection])
    }
    
    var description: String {
        return "(\(name), \(flowRate))"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func == (lhs: Valve, rhs: Valve) -> Bool {
        return lhs.name == rhs.name
    }
}

print(valves.sorted { $0.flowRate > $1.flowRate})

func calculateBenefit(for valve: Valve, from fromValve: Valve, currentTime: Int, log: Bool = false) -> (benefit: Int, timeTaken: Int) {
    if log {
        print("Calculating from=\(fromValve) to=\(valve)")
    }
    var unvisitedValves = Set<Valve>(valves)
    var distances = [Valve: Int]()
    for unvisitedValve in unvisitedValves {
        distances[unvisitedValve] = .max
    }
    distances[fromValve] = 0

    var currentValve = fromValve
    while !unvisitedValves.isEmpty {
        if log {
            print("  currentValve=\(currentValve)")
        }
        for connection in currentValve.connections {
            if !unvisitedValves.contains(connection) {
                continue
            }
            if log {
                print("    visiting connection=\(connection)")
            }

            let newDistance = distances[currentValve]! + 1
            let currentDistance = distances[connection]!
            distances[connection] = min(newDistance, currentDistance)
            if log {
                print("    new distance=\(distances[connection]!)")
            }
        }

        unvisitedValves.remove(currentValve)
        if currentValve == valve {
            if log {
                print("    * found destination")
            }
            break
        }

        var nextValve: Valve?
        for unvisitedValve in unvisitedValves {
            if nextValve == nil {
                nextValve = unvisitedValve
                continue
            }

            nextValve = distances[nextValve!]! < distances[unvisitedValve]! ? nextValve! : unvisitedValve
        }
        currentValve = nextValve!

        if log {
            print("    next valve=\(currentValve), distance=\(distances[currentValve]!)")
        }
    }

    let timeTaken = distances[currentValve]! + 1 // initial move + turning crank
    let benefit = (currentTime - timeTaken) * currentValve.flowRate

    return (benefit: benefit, timeTaken: timeTaken)
}

var openableValves = valves.compactMap { $0.flowRate > 0 ? $0 : nil }

let MAX_TIME = 26
var calculations = Array<Dictionary<Dictionary<Valve, Bool>,Int>>(repeating: Dictionary<Dictionary<Valve, Bool>, Int>(), count: MAX_TIME)

func getMaxPressure(currentTime: Int, currentValve: Valve, openedValves: [Valve: Bool]) {

    for nextValve in openableValves {
        // skip if opened
        if openedValves[nextValve] == true {
            continue
        }

        // check if we can open within time
        let newTime = currentTime + distances[currentValve]![nextValve]! //+ 1
        if newTime >= MAX_TIME {
            // going to be same pressure at end, so let's record
            if calculations[MAX_TIME - 1].index(forKey: openedValves) == nil {
                calculations[MAX_TIME - 1][openedValves] = 0
            }
            let currentPressure = calculations[currentTime][openedValves]!
            calculations[MAX_TIME - 1][openedValves] = max(calculations[MAX_TIME - 1][openedValves]!, currentPressure)

            continue
        }

        let nextPressure = (MAX_TIME - newTime) * nextValve.flowRate

        var nextOpenedValves = openedValves
        nextOpenedValves[nextValve] = true

        if calculations[newTime].index(forKey: nextOpenedValves) == nil {
            calculations[newTime][nextOpenedValves] = 0
        }
        let nextTotalPressure = nextPressure + calculations[currentTime][openedValves]!
        calculations[newTime][nextOpenedValves] = max(calculations[newTime][nextOpenedValves]!, nextTotalPressure)

        getMaxPressure(currentTime: newTime, currentValve: nextValve, openedValves: nextOpenedValves)
//        maxPressure = max(maxPressure, nextPressure + getMaxPressure(currentTime: newTime, currentValve: nextValve, openedValves: nextOpenedValves))
    }
}

var openedValves: [Valve: Bool] = {
    var dict = [Valve: Bool]()
    for valve in openableValves {
        dict[valve] = false
    }
    return dict
}()

var distances = [Valve: [Valve: Int]]()
for fromValve in openableValves + [startValve!] {
    for toValve in openableValves + [startValve!] {
        if fromValve == toValve {
            continue
        }

        let outcome = calculateBenefit(for: toValve, from: fromValve, currentTime: 30)
        if distances[fromValve] == nil {
            distances[fromValve] = [toValve: outcome.timeTaken]
        } else {
            distances[fromValve]![toValve] = outcome.timeTaken
        }
    }
}

calculations[0][openedValves] = 0

getMaxPressure(currentTime: 0, currentValve: startValve!, openedValves: openedValves)


func doNotIntersect(lhs: [Valve: Bool], rhs: [Valve: Bool]) -> Bool {
    if lhs.count != rhs.count {
        fatalError()
    }

    for elem in lhs {
        if rhs[elem.key]! && elem.value {
            return false
        }
    }

    return true
}

let subCalcs = calculations[MAX_TIME - 1].sorted(by: { $0.value > $1.value })//.prefix(100)

var maxBlah = 0
var i = 0
var total = subCalcs.count
for calc in subCalcs {
    print((Double(i) / Double(total))*100.0)
    i += 1
    let opened = calc.key
    for otherCalc in subCalcs {
        if calc == otherCalc {
            continue
        }

        if doNotIntersect(lhs: calc.key, rhs: otherCalc.key) {
            maxBlah = max(maxBlah, calc.value + otherCalc.value)
        }
    }
}
print(maxBlah)

//var currentValve = startValve!
//var currentTime = 30
//var totalBenefit = 0
//while !openableValves.isEmpty {
//    var highestBenefit: (benefit: Int, timeTaken: Int, valve: Valve)?
//    for valve in openableValves {
//        print("Testing from=\(currentValve) to=\(valve), timeLeft=\(currentTime)")
//        let outcome = calculateBenefit(for: valve, from: currentValve, currentTime: currentTime)
//        print("  outcome=\(outcome)")
//        let potentialBenefit = (benefit: outcome.benefit, timeTaken: outcome.timeTaken, valve: valve)
//        if highestBenefit == nil {
//            highestBenefit = potentialBenefit
//            continue
//        }
//
//        if potentialBenefit.benefit >= Int(0.5 * Double(highestBenefit!.benefit)) {
//            if potentialBenefit.timeTaken < highestBenefit!.timeTaken {
//                highestBenefit = potentialBenefit
//            }
//        }
////        highestBenefit = highestBenefit!.benefit > potentialBenefit.benefit ? highestBenefit : potentialBenefit
//    }
//
//    print("Found highestBenefit=\(highestBenefit!)")
//
//    // travel to highestBenefit
//    let indexToRemove = openableValves.firstIndex(of: highestBenefit!.valve)!
//    openableValves.remove(at: indexToRemove)
//    currentValve = highestBenefit!.valve
//    currentTime -= highestBenefit!.timeTaken
//    totalBenefit += highestBenefit!.benefit
//}
//
//print(totalBenefit)

//var culledOrders = [[Valve]]()
//
//func heapPermutation(array: inout [Valve], size: Int, n: Int) {
//    if size == 1 {
//        var totalTime = 0
//        for i in 1..<array.count {
//            totalTime += distances[array[i-1]]![array[i]]!
//            if totalTime >= 30 {
//                return
//            }
//        }
//
//        culledOrders.append(array)
//    }
//
//    for i in 0..<size {
//        heapPermutation(array: &array, size: size - 1, n: n)
//
//        let secondIndex = array.index(array.startIndex, offsetBy: size - 1)
//        if (size % 2) == 1 {
//            array.swapAt(array.startIndex, secondIndex)
//
//        } else {
//            let firstIndex = array.index(array.startIndex, offsetBy: i)
//            array.swapAt(firstIndex, secondIndex)
//        }
//    }
//}

//var heapOrders = Array(openableValves)
//heapPermutation(array: &heapOrders, size: heapOrders.count, n: heapOrders.count)
//print(culledOrders.count)

//let orders = openableValves.permutations(ofCount: openableValves.count)
//print(orders.count)
//var highestBenefit = 0
//
//for order in orders {
//    if order[0].flowRate < 20 || order[1].flowRate < 20 {
//        continue
//    }
//    print(order)
//
//    var currentValve = startValve!
//    var currentTime = 30
//    var totalBenefit = 0
//    for nextValve in order {
////        print("  calculating from=\(currentValve), to=\(nextValve), currentTime=\(currentTime)")
//        let outcome = calculateBenefit(for: nextValve, from: currentValve, currentTime: currentTime)
//
////        print("    outcome=\(outcome)")
//
//        totalBenefit += outcome.benefit
//        currentTime -= outcome.timeTaken
//        currentValve = nextValve
//    }
////    print("  found benefit: \(totalBenefit)")
//
//    highestBenefit = max(highestBenefit, totalBenefit)
//}
//
//print(highestBenefit)
