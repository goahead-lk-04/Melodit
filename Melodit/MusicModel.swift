//
//  MusicModel.swift
//  Melodit
//
//  Created by Lisa Kuchyna on 2024-06-15.
//

import Foundation
import CoreML
import AVFoundation
import AudioKit
import SwiftPlot
import AudioToolbox

class MusicModel {
    
    var model = try! onsets_frames_pytorch_model()
    
    func processAudio(music_file audioURL: URL) {
        

         do {
             let audioData = try Data(contentsOf: audioURL)
           
             let sampleRate = Double(model.model.modelDescription.inputDescriptionsByName["input"]!.multiArrayConstraint!.shape[1] as! Int)
                 
             let audioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: 1, interleaved: false)
                 
             let audioBuffer = try AVAudioPCMBuffer(pcmFormat: audioFormat!, frameCapacity: UInt32(audioData.count))
                 
             audioBuffer!.frameLength = audioBuffer!.frameCapacity
            let audioBufferChannelData = audioBuffer!.floatChannelData![0]
            let dataPointer = audioData.withUnsafeBytes { $0.load(as: UnsafePointer<Float>.self) }
                 //audioBufferChannelData.assign(from: dataPointer, count: Int(audioBuffer!.frameLength))
                 
             let processedData = processAudioBuffer(audioBuffer!)
             
             let input = try MLMultiArray(shape: [1, 384, 228, 1] as [NSNumber], dataType: .float32)
             let inputPointer = UnsafeMutablePointer<Float>(OpaquePointer(input.dataPointer))
             
             for i in 0..<processedData.count {
                 inputPointer[i] = Float(processedData[i])
             }
             
             if let modelOutput = try? model.prediction(input: input) {
                 let onsetPred = modelOutput.onset

                 let batchSize = onsetPred.shape[0].intValue
                 let height = onsetPred.shape[1].intValue
                 let width = onsetPred.shape[2].intValue

                 for b in 0..<batchSize {
                     for h in 0..<height {
                         for w in 0..<width {
                             let index = [b, h, w] as [NSNumber]
                             let value = onsetPred[index].floatValue
                             print("Value at (\(b), \(h), \(w)): \(value)")
                         }
                     }
                 }
                 
                 
                 let onsetPredictions: [[Float]] = modelOutput.onset.to2DArray()
                 let offsetPredictions: [[Float]] = modelOutput.offset.to2DArray()
                 let framePredictions: [[Float]] = modelOutput.frame.to2DArray()
                 let velocityPredictions: [[Float]] = modelOutput.velocity.to2DArray()
                 
                 print("Onset Predictions: \(onsetPredictions.count) x \(onsetPredictions.first?.count ?? 0)")
                 print("Offset Predictions: \(offsetPredictions.count) x \(offsetPredictions.first?.count ?? 0)")
                 print("Frame Predictions: \(framePredictions.count) x \(framePredictions.first?.count ?? 0)")
                 print("Velocity Predictions: \(velocityPredictions.count) x \(velocityPredictions.first?.count ?? 0)")


                 var pitches: [UInt8] = []
                 var intervals: [[Double]] = []
                 var velocities: [UInt8] = []

                 let numFrames = onsetPredictions.count
                 guard let numPitches = onsetPredictions.first?.count else {
                     fatalError("Onset predictions array is empty")
                 }
                 print("Sample onset prediction values: \(onsetPredictions[0][0]), \(onsetPredictions[100][0]), \(onsetPredictions[200][0])")
                 print("Sample offset prediction values: \(offsetPredictions[0][0]), \(offsetPredictions[100][0]), \(offsetPredictions[200][0])")
                 print("Sample velocity prediction values: \(velocityPredictions[0][0]), \(velocityPredictions[100][0]), \(velocityPredictions[200][0])")

                 for pitch in 0..<numPitches {
                     var onsetFrame: Int? = nil
                     
                     for frame in 0..<numFrames {
                         let onsetValue = onsetPredictions[frame][pitch]
                         let offsetValue = offsetPredictions[frame][pitch]
                         
                         if onsetValue > 3.484526e-08{
                             if onsetFrame == nil {
                                 onsetFrame = frame
                                 print("Onset detected at frame \(frame) for pitch \(pitch) with value \(onsetValue)")
                             }
                         }
                         
                         if var onsetFrame = onsetFrame, offsetValue > 3.484526e-08 {
                                     print("Offset detected at frame \(frame) for pitch \(pitch) with value \(offsetValue)")
                                     let startTime = Double(onsetFrame) / sampleRate
                                     let duration = Double(frame - onsetFrame) / sampleRate
                                     
                                     let scaledVelocity = UInt8(max(0, min(127, velocityPredictions[onsetFrame][pitch] * 127.0)))
                                     
                                     pitches.append(UInt8(pitch))
                                     intervals.append([startTime, duration])
                                     velocities.append(scaledVelocity)
                                     onsetFrame = 0
                                 }
                     }
                 }

                 if pitches.isEmpty {
                     print("No pitches extracted.")
                 }
                 if intervals.isEmpty {
                     print("No intervals extracted.")
                 }
                 if velocities.isEmpty {
                     print("No velocities extracted.")
                 }

                 let midiFilePath = "/Users/lizzikuchyna/AppleProjects/Melodit/midi/file3.mid"
                 print("Saving MIDI file to path: \(midiFilePath)")
                 
                 print("here")
                 saveMIDI(path: midiFilePath, pitches: pitches, intervals: intervals, velocities: velocities)
                             
                 
             } else {
                 print("Failed to make prediction")
             }


             
         } catch {
             print("Error processing audio:", error.localizedDescription)
         }
        
    }
    
    
    
//    func savePianoroll(path: String, onset: [Float], frame: [Float]) {
//        var plot = Plot()
//        var scatterPlot = ScatterPlot<Float, Float>()
//        scatterPlot.addSeries(onset, frame, label: "Onsets and Frames")
//        plot.addPlot(scatterPlot)
//        
//        plot.plotTitle = PlotTitle("Pianoroll")
//        plot.plotLabel = PlotLabel(xLabel: "Time", yLabel: "Frequency")
//        
//        let renderer = AGGRenderer()
//        try? plot.drawGraphAndOutput(fileName: path, renderer: renderer)
//    }



    func saveMIDI(path: String, pitches: [UInt8], intervals: [[Double]], velocities: [UInt8]) {
        var musicSequence: MusicSequence?
        var musicTrack: MusicTrack?
        
        var status = NewMusicSequence(&musicSequence)
        guard status == noErr else {
            print("Error creating MusicSequence: \(status)")
            return
        }
        
        status = MusicSequenceNewTrack(musicSequence!, &musicTrack)
        guard status == noErr else {
            print("Error creating MusicTrack: \(status)")
            return
        }
        
        for (index, pitch) in pitches.enumerated() {
            let onset = intervals[index][0]
            let offset = intervals[index][1]
            let velocity = velocities[index]
            
            var note = MIDINoteMessage(channel: 0,
                                       note: pitch,
                                       velocity: velocity,
                                       releaseVelocity: 0,
                                       duration: Float32(offset - onset))
            
            status = MusicTrackNewMIDINoteEvent(musicTrack!,
                                                MusicTimeStamp(onset),
                                                &note)
            guard status == noErr else {
                print("Error adding MIDINoteEvent to MusicTrack: \(status)")
                return
            }
        }
        
        var sequenceLength = intervals.last?.last ?? 0.0
        status = MusicTrackSetProperty(musicTrack!,
                                       kSequenceTrackProperty_TrackLength,
                                       &sequenceLength,
                                       UInt32(MemoryLayout<Float64>.size))
        guard status == noErr else {
            print("Error setting MusicTrack length: \(status)")
            return
        }
        
        let url = URL(fileURLWithPath: path) as CFURL
        status = MusicSequenceFileCreate(musicSequence!, url, .midiType, .eraseFile, 0)
        guard status == noErr else {
            print("Error creating MIDI file: \(status)")
            return
        }
        
        status = DisposeMusicSequence(musicSequence!)
        guard status == noErr else {
            print("Error disposing MusicSequence: \(status)")
            return
        }
        
        print("MIDI file saved successfully at \(path)")
    }


    
    func processAudioBuffer(_ buffer: AVAudioPCMBuffer) -> [Float] {
        var processedData: [Float] = []
        
        
        return processedData
    }
}

extension MLMultiArray {
    func to2DArray() -> [[Float]] {
        let pointer = UnsafeMutablePointer<Float>(OpaquePointer(self.dataPointer))
        var array: [[Float]] = Array(repeating: Array(repeating: 0.0, count: self.shape[2].intValue), count: self.shape[1].intValue)
        for i in 0..<self.shape[1].intValue {
            for j in 0..<self.shape[2].intValue {
                array[i][j] = pointer[i * self.shape[2].intValue + j]
            }
        }
        return array
    }
}
