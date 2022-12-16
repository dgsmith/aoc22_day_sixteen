import Darwin
import Foundation

var valves = [Valve]()
var startValve: Valve

let filePath = "/Users/grayson/code/advent_of_code/2022/day_sixteen/test.txt"
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
    print(flowRate)
    
    var parent: Valve?
    for match in valveMatches {
        let valveName = String(match.output)
        print(valveName)
        
        if let parent {
            if let foundValve = valves.first(where: { $0.name == valveName }) {
                parent.connections.append(foundValve)
                foundValve.parent = parent
                
            } else {
                let newValve = Valve(name: valveName, parent: parent)
                parent.connections.append(newValve)
                valves.append(newValve)
            }
            
        } else {
            if let foundParent = valves.first(where: { $0.name == valveName }) {
                foundParent.flowRate = flowRate
                parent = foundParent
                
            } else {
                parent = Valve(name: valveName, flowRate: flowRate)
                valves.append(parent!)
                
                if parent!.name == "AA" {
                    startValve = parent!
                }
            }
        }
    }
}

class Valve: Hashable, CustomStringConvertible {
    let name: String
    var flowRate: Int = 0
    
    var parent: Valve?
    var connections = [Valve]()
    
    init(name: String, flowRate: Int, parent: Valve?) {
        self.name = name
        self.flowRate = flowRate
        self.parent = parent
    }
    
    convenience init(name: String, flowRate: Int) {
        self.init(name: name, flowRate: flowRate, parent: nil)
    }
                
    convenience init(name: String, parent: Valve) {
        self.init(name: name, flowRate: 0, parent: parent)
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

// from any one point can recusively calculate the "benefit" of picking a path
// A
// B, C
// say B is 10 and C is 5 and there is 10 minutes left
// benefit of going to B is (B_flow * (min_left - travel_time - opening_time))

// for each option, calculate benefit of making any decision...then go there?
