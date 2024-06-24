

import Foundation
import MIDIKit
import MIDIKitIO

public enum Velocity {
    case none
    case noteWhole
    case noteHalf
    case noteQuarter
    case note8th
    case note16th
    case note32nd
    case note64th
    case note128th
    case note256th
}


func velocityy(forTicks ticks: UInt32, using timeBase: MIDIFile.TimeBase) -> Velocity {
    let midiFileTicksPerQuarter: UInt32
    
    switch timeBase {
    case let .musical(ticksPerQuarterNote):
        midiFileTicksPerQuarter = UInt32(ticksPerQuarterNote)
        
    case .timecode(_, _):
        fatalError("Timecode timebase not implemented yet.")
    }
    
    let ticksPerWhole = midiFileTicksPerQuarter * 4
    let ticksPerHalf = midiFileTicksPerQuarter * 2
    let ticksPerQuarter = midiFileTicksPerQuarter
    let ticksPer8th = midiFileTicksPerQuarter / 2
    let ticksPer16th = midiFileTicksPerQuarter / 4
    let ticksPer32nd = midiFileTicksPerQuarter / 8
    let ticksPer64th = midiFileTicksPerQuarter / 16
    let ticksPer128th = midiFileTicksPerQuarter / 32
    _ = midiFileTicksPerQuarter / 64
    
    if ticks == 0 {
        return .none
    } else if ticks >= ticksPerWhole {
        return .noteWhole
    } else if ticks >= ticksPerHalf {
        return .noteHalf
    } else if ticks >= ticksPerQuarter {
        return .noteQuarter
    } else if ticks >= ticksPer8th {
        return .note8th
    } else if ticks >= ticksPer16th {
        return .note16th
    } else if ticks >= ticksPer32nd {
        return .note32nd
    } else if ticks >= ticksPer64th {
        return .note64th
    } else if ticks >= ticksPer128th {
        return .note128th
    } else {
        return .note256th
    }
}


func extractMIDINoteNumbers(from filePath: String) throws -> [(UInt8, Velocity)] {
    let midiFileURL = URL(fileURLWithPath: filePath)
    let midiFile = try MIDIFile(midiFile: midiFileURL)

    var noteInfo = [(noteNumber: UInt8, velocity: Velocity)]()


    for track in midiFile.tracks {
        var previousTicks: UInt32 = 0
        for (index, event) in track.events.enumerated() {
            if case let .noteOn(noteTicks, noteOnEvent) = event {
                let noteNumber = UInt8(noteOnEvent.note.number)
                let ticks = noteTicks.ticksValue(using: .musical(ticksPerQuarterNote: 960))
                let velocity: Velocity
                
                if index == 0 {
                    velocity = .none
                } else {
                   
                    let duration: UInt32
                    if ticks >= previousTicks {
                        duration = ticks - previousTicks
                    } else {
                        duration = 0
                        
                    }
                    
                    velocity = velocityy(forTicks: duration, using: .musical(ticksPerQuarterNote: 960))
                }
                
                noteInfo.append((noteNumber, velocity))
                previousTicks = ticks
            }
        }
    }

    return noteInfo
}
