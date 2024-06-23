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
import Accelerate

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
              

            let processedData = processAudioBuffer(audioBuffer!)
             
            // input for the CoreML model
            let input = try MLMultiArray(shape: [1, 384, 228, 1] as [NSNumber], dataType: .float32)
            let inputPointer = UnsafeMutablePointer<Float>(OpaquePointer(input.dataPointer))
             
            for i in 0..<processedData.count {
                inputPointer[i] = Float(processedData[i])
            }
             
            // prediction
            if let modelOutput = try? model.prediction(input: input) {
            let onsetPred = modelOutput.onset
            let batchSize = onsetPred.shape[0].intValue
            let height = onsetPred.shape[1].intValue
            let width = onsetPred.shape[2].intValue
    
            for b in 0..<batchSize {
                for h in 0..<height {
                    for w in 0..<width {
                        let onsetValue = onsetPred[[b, h, w] as [NSNumber]].floatValue
                        let offsetValue = modelOutput.offset[[b, h, w] as [NSNumber]].floatValue
                        let frameValue = modelOutput.frame[[b, h, w] as [NSNumber]].floatValue
                        let velocityValue = modelOutput.velocity[[b, h, w] as [NSNumber]].floatValue
                        let activation = modelOutput.activation[[b, h, w] as [NSNumber]].floatValue
                        
                            
                        print("Value at (\(b), \(h), \(w)): Onset=\(onsetValue), Offset=\(offsetValue), Frame=\(frameValue), Velocity=\(velocityValue), Activation=\(activation)")
                    }
                }
            }
         
            let onsetPredictions: [[Float]] = modelOutput.onset.to2DArray()
            let offsetPredictions: [[Float]] = modelOutput.offset.to2DArray()
            let framePredictions: [[Float]] = modelOutput.frame.to2DArray()
            let velocityPredictions: [[Float]] = modelOutput.velocity.to2DArray()
          

            let midiFilePath = "/Users/lizzikuchyna/AppleProjects/Melodit/midi/file3.mid"
            print("Saving MIDI file to path: \(midiFilePath)")
        
            let notes = extractNotes(onsetPredictions: onsetPredictions, offsetPredictions: offsetPredictions, framePredictions: framePredictions, velocityPredictions: velocityPredictions)

            var convertedPitches: [UInt8] = []
            for e in notes.enumerated() {
                convertedPitches.append(UInt8(e.element.pitch))
            }

            var convertedIntervals: [[Double]] = []
            for e in notes.enumerated() {
                let start = Double(e.element.startTime)
                let end = Double(e.element.endTime)
                convertedIntervals.append([start, end])
            }

            var convertedVelocities: [UInt8] = []
            for e in notes.enumerated() {
                convertedVelocities.append(UInt8(e.element.velocity))
            }

            saveMIDI(path: midiFilePath, pitches: convertedPitches, intervals: convertedIntervals, velocities: convertedVelocities)


            } else {
                print("Failed to make prediction")
            }
        } catch {
            print("Error processing audio:", error.localizedDescription)
        }
    }

    func processAudioBuffer(_ buffer: AVAudioPCMBuffer) -> [Float] {
        return generateMelSpectrogram(from: buffer)
    }

    // метод для генерації спектограми, перероблений з пайтона
    func generateMelSpectrogram(from buffer: AVAudioPCMBuffer) -> [Float] {
        guard let floatChannelData = buffer.floatChannelData else {
            fatalError("Buffer must have float channel data")
        }
        
        let numSamples = vDSP_Length(buffer.frameLength)
        let numChannels = Int(buffer.format.channelCount)
        let sampleRate = Float(buffer.format.sampleRate)
        let hopLength = Int(sampleRate * 0.01)
        
        var melSpectrogram: [Float] = []
        
        for channel in 0..<numChannels {
            var channelData = Array(UnsafeBufferPointer(start: floatChannelData[channel], count: Int(numSamples)))
            
            // Hann window function
            var window = [Float](repeating: 0.0, count: Int(buffer.frameLength))
            vDSP_hann_window(&window, vDSP_Length(buffer.frameLength), Int32(vDSP_HANN_NORM))
            vDSP_vmul(channelData, 1, window, 1, &channelData, 1, vDSP_Length(buffer.frameLength))
            
            var complexData = [DSPComplex](repeating: DSPComplex(), count: Int(buffer.frameLength / 2))
            for i in 0..<complexData.count {
                complexData[i].real = channelData[2*i]
                complexData[i].imag = channelData[2*i + 1]
            }
            
            var fftSetup = vDSP_create_fftsetup(vDSP_Length(log2(Float(buffer.frameLength))), FFTRadix(FFT_RADIX2))
            var realParts = complexData.map { $0.real }
            var imagParts = complexData.map { $0.imag }
            var splitComplex = DSPSplitComplex(realp: &realParts, imagp: &imagParts)
            
            vDSP_fft_zrip(fftSetup!, &splitComplex, 1, vDSP_Length(log2(Float(buffer.frameLength))), FFTDirection(FFT_FORWARD))
            
            var magnitudes = [Float](repeating: 0.0, count: Int(buffer.frameLength / 2))
            vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(buffer.frameLength / 2))
            
            let N_MELS = 64
            var melOutput = [Float](repeating: 0.0, count: N_MELS )
            let numFFTbins = Int(buffer.frameLength / 2)
            var melBasis = Array(repeating: [Float](repeating: 0.0, count: numFFTbins), count: N_MELS)
            
            // similar to torch.matmul in Python
            for m in 0..<N_MELS {
                for k in 0..<Int(buffer.frameLength / 2) {
                    melOutput[m] += magnitudes[k] * melBasis[m][k]
                }
            }
            for m in 0..<N_MELS {
                melOutput[m] = logf(max(melOutput[m], 1e-5))
            }
            
            melSpectrogram.append(contentsOf: melOutput)
            
            vDSP_destroy_fftsetup(fftSetup)
        }
        
        return melSpectrogram
    }
    
    
    func extractNotes(onsetPredictions: [[Float]], offsetPredictions: [[Float]], framePredictions: [[Float]], velocityPredictions: [[Float]]) -> [Note] {
        var notes = [Note]()
        let threshold: Float = 0.5

        let height = onsetPredictions.count
        let width = onsetPredictions[0].count

        for h in 0..<height {
            for w in 0..<width {
                //print(onsetPredictions[h][w] )
                if onsetPredictions[h][w] > 0.001124{
              
                    var startTime = Double(h)
                    var endTime = startTime
                    let pitch = w
                    var velocity = Int(velocityPredictions[h][w])
                    
                    for h2 in h..<height {
                        if offsetPredictions[h2][w] > threshold {
                            endTime = Double(h2)
                            break
                        }
                    }
                    
                    print("s \(startTime)")
                    print("e \(endTime)")
                    endTime += 1
                    if endTime > startTime  {
                        print("ff")
                        
                        if velocity < 0 { velocity *= -1 }
                        if w % 2 == 0 {
                            velocity += 10
                            startTime -= 8
                            endTime -= 5
                        } else {
                            velocity += 5
                            startTime -= 5
                            endTime -= 2
                        }
                        let note = Note(startTime: startTime, endTime: endTime, pitch: pitch, velocity: velocity)
                        notes.append(note)
                    }
                }
            }
        }
        print("here \(notes)")
        return notes
    }

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

struct Note {
    var startTime: Double
    var endTime: Double
    var pitch: Int
    var velocity: Int
}
