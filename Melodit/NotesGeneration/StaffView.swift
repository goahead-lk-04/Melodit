//
//  StaffView.swift
//  midinotes
//
//  Created by Inna Boiko on 23.06.2024.
//

import Foundation
import UIKit

class StaffView: UIView {
    
    let trebleClefImage = UIImage(named: "treble-clef.png")
    var notes: [(UInt8,Velocity)] = []
    
    let topOffset: CGFloat = UIScreen.main.bounds.height/20
    let gapBetweenGroups: CGFloat = UIScreen.main.bounds.height/40
    let gapBetweenLines = 10.0
    let numberOfNotesInOnegroup = (UIScreen.main.bounds.maxX - UIScreen.main.bounds.minX - 60.0)/30.0
    let noteWidth: CGFloat = 12
    let noteHeight: CGFloat = 9
    let widthOfTrebleClefImage = 60.0
    let editionalSpaceForC4 = 10.0
    let noteSpacing = 30.0
    
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
           drawStaff(context: context, rect: self.bounds)
           drawAllNotes()

    }
    
    
    func setNotes(midiNumbers: [(UInt8,Velocity)]) {
            self.notes = midiNumbers
            setNeedsDisplay()
        }
    
    func drawStaff(context: CGContext, rect: CGRect) {

            var currentY = rect.minY + topOffset
        for _ in 0..<9 {
            currentY = drawGroupOfLines(context: context, rect: rect, gapBetweenLines: gapBetweenLines, currentY: currentY)
            currentY += gapBetweenGroups
        }
    }

    func drawAllNotes() {
           guard !notes.isEmpty else { return }
           
           var currentY = topOffset
           var startIndex = 0
           
           let numberOfGroups = Int(ceil(Double(notes.count) / Double(numberOfNotesInOnegroup)))
           
           for _ in 0..<numberOfGroups {
               let endIndex = min(startIndex + Int(numberOfNotesInOnegroup), notes.count)
               
               drawNotesInGroup(startY: currentY, endY: currentY + gapBetweenLines * 4, startIndex: startIndex, endIndex: endIndex)
               
               startIndex = endIndex
               currentY += gapBetweenGroups + gapBetweenLines * 4 + editionalSpaceForC4
           }
           
 
       }
       
       func drawNotesInGroup(startY: CGFloat, endY: CGFloat, startIndex: Int, endIndex: Int) {
           guard UIGraphicsGetCurrentContext() != nil else { return }
           
           
           
           let endy = endY + editionalSpaceForC4
        
           for index in startIndex..<endIndex {
               guard index < notes.count else { continue }
               
               let (midiNumber, velocity) = notes[index]
               let (noteName, octave) = NoteConverter.midiNoteNumberToNoteAndOctaveAsTuple(noteNumber: Int(midiNumber))
               let (staffPosition,isSigned) = calculateStaffPosition(noteName: noteName, octave: octave)
               
               
               if isSigned {
                   let xPositionsign = UIScreen.main.bounds.minX + widthOfTrebleClefImage + CGFloat(index - startIndex) * noteSpacing - 15.0
                   let yPositionsign = endy - (CGFloat(staffPosition) * gapBetweenLines / 2)
                   drawFlatSymbol(at: CGPoint(x: xPositionsign, y: yPositionsign))
               }
               
               let xPosition = UIScreen.main.bounds.minX + widthOfTrebleClefImage + CGFloat(index - startIndex) * noteSpacing
               let yPosition = endy - (CGFloat(staffPosition) * gapBetweenLines / 2)
               
               if staffPosition == 0 || staffPosition == 12 || staffPosition == 13 { //до,сі,до
                   drawLedgerLine(at: CGPoint(x: xPosition, y: yPosition + 5.0))
               }
               if staffPosition == 13 {
                   drawNoteWithVelocity(at: CGPoint(x: xPosition, y: yPosition ), velocity: velocity)
               } else{
                   drawNoteWithVelocity(at: CGPoint(x: xPosition, y: yPosition), velocity: velocity)
                   
               }}
           
         
       }
       

    
    func calculateStaffPosition(noteName: String, octave: Int) -> (Int,Bool) {//position and does it have sign
    print(noteName,octave)
       let middleCOctave = 4
       
        let noteOffsets: [String: Int] = ["C": 0, "C#/Db": -1, "D": 1, "E": 2, "F": 3,"D#/Eb": -2,  "F#/Gb": -3, "G": 4, "G#/Ab": -4, "A": 5, "A#/Bb": -6,"B": 6]
  
        
        guard let noteOffset = noteOffsets[noteName] else { return (0,false) }
        let octaveDifference = octave - middleCOctave
        
        let adjustedOctaveDifference: Int
          if octaveDifference % 2 == 0 {
              adjustedOctaveDifference = 0
          } else {
              adjustedOctaveDifference = 7
          }
        
        let absPos = abs(noteOffset)
        let position = absPos + adjustedOctaveDifference
        print(position)
        if noteOffset < 0 {
            return (position, true)
        }
      
        return (position, false)
    }
       
       
    
    
    func drawGroupOfLines(context: CGContext, rect: CGRect, gapBetweenLines : CGFloat, currentY : CGFloat) -> CGFloat {
        let linesPerGroup = 5
        context.setLineWidth(1.0)
        context.setStrokeColor(UIColor.black.cgColor)
        var currenty = currentY
       
        for lineIndex in 0..<linesPerGroup {
            let y = currentY + CGFloat(lineIndex) * gapBetweenLines
            context.move(to: CGPoint(x: rect.minX, y: y))
            context.addLine(to: CGPoint(x: rect.maxX, y: y))
            currenty += gapBetweenLines
        }
        
        context.strokePath()
        
        if let clefImage = trebleClefImage {
                 let clefRect = CGRect(x: rect.minX, y: currentY, width: 50, height: 50)
                 clefImage.draw(in: clefRect)
             }
        return currenty
    }


 
    func drawLedgerLine(at position: CGPoint) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let ledgerLineLength: CGFloat = 20.0
        let xStart = position.x - ledgerLineLength / 2
        let xEnd = position.x + ledgerLineLength / 2
        let y = position.y
        
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1.0)
        context.move(to: CGPoint(x: xStart, y: y))
        context.addLine(to: CGPoint(x: xEnd, y: y))
        context.strokePath()
    }
    
    
    func drawNoteWhole(at position: CGPoint) {
        let noteRect = CGRect(x: position.x - 5, y: position.y - 5, width: 14, height: 11)
        let context = UIGraphicsGetCurrentContext()
        
        context?.setLineWidth(1.0)
        context?.setStrokeColor(UIColor.black.cgColor)
        context?.strokeEllipse(in: noteRect)
    }
    
    func drawNoteHalf(at position: CGPoint) {

        let noteRect = CGRect(x: position.x - noteWidth / 2, y: position.y - noteHeight / 2, width: noteWidth, height: noteHeight)
        let context = UIGraphicsGetCurrentContext()
        
        context?.setLineWidth(1.0)
        context?.setStrokeColor(UIColor.black.cgColor)
        
      
        context?.strokeEllipse(in: noteRect)
 
        context?.move(to: CGPoint(x: position.x + noteWidth / 2, y: position.y))
        context?.addLine(to: CGPoint(x: position.x + noteWidth / 2, y: position.y - 30.0))
        context?.strokePath()
    }
    
    func drawNoteQuarter(at position: CGPoint) {
        let noteRect = CGRect(x: position.x - noteWidth / 2, y: position.y - noteHeight / 2, width: noteWidth, height: noteHeight)
        let context = UIGraphicsGetCurrentContext()
        
        context?.setFillColor(UIColor.black.cgColor)
        context?.fillEllipse(in: noteRect)
        
        context?.setLineWidth(1.0)
        context?.setStrokeColor(UIColor.black.cgColor)
        context?.strokeEllipse(in: noteRect)
        
        context?.move(to: CGPoint(x: position.x + noteWidth / 2, y: position.y))
        context?.addLine(to: CGPoint(x: position.x + noteWidth / 2, y: position.y - 30.0))
        context?.strokePath()
        
    }
    
    func drawNote8th(at position: CGPoint) {
        let noteRect = CGRect(x: position.x - noteWidth / 2, y: position.y - noteHeight / 2, width: noteWidth, height: noteHeight)
        
        let context = UIGraphicsGetCurrentContext()
        
        context?.setFillColor(UIColor.black.cgColor)
        context?.fillEllipse(in: noteRect)
        
        context?.setLineWidth(1.0)
        let tailStartPoint = CGPoint(x: position.x + noteWidth / 2, y: position.y)
        let tailEndPoint = CGPoint(x: position.x + noteWidth / 2, y: position.y - 30.0)
            context?.move(to: tailStartPoint)
            context?.addLine(to: tailEndPoint)
            context?.strokePath()
            
        context?.setLineWidth(2.0)
        let flagStartPoint = CGPoint(x: position.x + noteWidth / 2, y: position.y - 30.0)
        let flagEndPoint = CGPoint(x: position.x + noteWidth / 2 + 7.0, y: position.y - 10.0)
            context?.move(to: flagStartPoint)
            context?.addLine(to: flagEndPoint)
            context?.strokePath()
    }
    
    func drawNote16th(at position: CGPoint) {
        let noteRect = CGRect(x: position.x - noteWidth / 2, y: position.y - noteHeight / 2, width: noteWidth, height: noteHeight)
        let context = UIGraphicsGetCurrentContext()
        
        context?.setFillColor(UIColor.black.cgColor)
        context?.fillEllipse(in: noteRect)
        
        context?.setLineWidth(1.0)
        let tailStartPoint = CGPoint(x: position.x + noteWidth / 2, y: position.y)
        let tailEndPoint = CGPoint(x: position.x + noteWidth / 2, y: position.y - 30.0)
            context?.move(to: tailStartPoint)
            context?.addLine(to: tailEndPoint)
            context?.strokePath()
            
  
        let flagStartPoint = CGPoint(x: position.x + noteWidth / 2, y: position.y - 30.0)
        let flagEndPoint = CGPoint(x: position.x + noteWidth / 2 + 7.0, y: position.y - 13.0)
            context?.move(to: flagStartPoint)
            context?.addLine(to: flagEndPoint)
        
        let flag2StartPoint = CGPoint(x: position.x + noteWidth / 2, y: position.y - 20.0)
        let flag2EndPoint = CGPoint(x: position.x + noteWidth / 2 + 7.0, y: position.y - 3.0)
            context?.move(to: flag2StartPoint)
            context?.addLine(to: flag2EndPoint)
            context?.strokePath()
    }
    
    func drawSharpSymbol(at position: CGPoint) {//неправильне
    
        let context = UIGraphicsGetCurrentContext()
       
        context?.setStrokeColor(UIColor.black.cgColor)
        context?.setLineWidth(1.0)
        
      
        context?.move(to: CGPoint(x: position.x , y: position.y )) //
        context?.addLine(to: CGPoint(x: position.x  + 5.0 , y: position.y - 10.0))
            
          
        context?.move(to: CGPoint(x: position.x  + 5.0, y: position.y))
        context?.addLine(to: CGPoint(x: position.x + 10.0, y: position.y - 10.0))

        
        context?.move(to: CGPoint(x: position.x - 2.5 , y: position.y - 6.5))
        context?.addLine(to: CGPoint(x: position.x  + 12.5 , y: position.y - 6.5))
            
          
        context?.move(to: CGPoint(x: position.x - 2.5 , y: position.y - 2.5))
        context?.addLine(to: CGPoint(x: position.x  + 12.5 , y: position.y - 2.5))
        
   context?.strokePath()
    }
    
    func drawFlatSymbol(at position: CGPoint) {

        let context = UIGraphicsGetCurrentContext()
        
        context?.setStrokeColor(UIColor.black.cgColor)
        context?.setLineWidth(1.0)
        
       
        context?.move(to: CGPoint(x: position.x, y: position.y))
        context?.addLine(to: CGPoint(x: position.x, y: position.y - 10))
        
        context?.move(to: CGPoint(x: position.x, y: position.y))
        context?.addArc(center: CGPoint(x: position.x, y: position.y - 2.5),
                        radius: 4,
                        startAngle: CGFloat.pi/2,
                        endAngle: CGFloat.pi * 3/2,
                        clockwise: true)
        
        context?.strokePath()
    }
    
    func drawNoteWithVelocity(at position: CGPoint, velocity: Velocity) {
       
        switch velocity {
        case .none:
            drawNoteQuarter(at: position)
        case .noteWhole:
            drawNoteWhole(at: position)
        case .noteHalf:
            drawNoteHalf(at: position)
        case .noteQuarter:
            drawNoteQuarter(at: position)
        case .note8th:
            drawNote8th(at: position)
        case .note16th:
            drawNote16th(at: position)
        case .note32nd:
            drawNote16th(at: position)
        case .note64th:
            drawNote16th(at: position)
        case .note128th:
            drawNote16th(at: position)
        case .note256th:
            drawNote16th(at: position)
        }
    }
    
}

