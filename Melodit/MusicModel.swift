//
//  MusicModel.swift
//  Melodit
//
//  Created by Lisa Kuchyna on 2024-06-15.
//

import Foundation
import CoreML
import AVFoundation

class MusicModel {
    
    var model = try! converted_model()
    
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
                 let onsetPred = modelOutput.linear_8

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
             } else {
                 print("Failed to make prediction")
             }


             
         } catch {
             print("Error processing audio:", error.localizedDescription)
         }
        
    }
    
    func processAudioBuffer(_ buffer: AVAudioPCMBuffer) -> [Float] {
        var processedData: [Float] = []
        
        
        return processedData
    }
}
