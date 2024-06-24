//
//  ShowNotesController.swift
//  Melodit
//
//  Created by Inna Boiko on 23.06.2024.
//

import UIKit

class ShowNotesController : UIViewController {
    
    
    let topOffset: CGFloat = 20.0
    let gapBetweenGroups: CGFloat = 30.0
    let gapBetweenLines = 10.0
    let numberOfNotesInOnegroup = 11.0

    
    private let scrollView: UIScrollView = {
          return UIScrollView()
        }()
        
    var staffView : StaffView!
    
    let noteconverter = NoteConverter()
    var currentNotes: [(UInt8,Velocity)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadMIDIFile()
        setupScrollView()
        setupStaffView()
        updateNotes(currentNotes)
    }
    
    
    
    func setupScrollView() {
          scrollView.frame = view.bounds
          scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
          scrollView.backgroundColor = .white
          scrollView.showsVerticalScrollIndicator = true
          scrollView.showsHorizontalScrollIndicator = false
          view.addSubview(scrollView)
      }

    func setupStaffView() {
        staffView = StaffView(
                frame: CGRect(x: 0, y: 0, width: scrollView.frame.width, height: staffViewHeight()),
                topOffset: topOffset,
                gapBetweenGroups: gapBetweenGroups,
                gapBetweenLines: gapBetweenLines,
                numberOfNotesInOnegroup: numberOfNotesInOnegroup
            )
  
        scrollView.addSubview(staffView)
        scrollView.contentSize = staffView.bounds.size
    }

    private func staffViewHeight() -> CGFloat {
      
        let numberOfGroups = Int(ceil(Double(currentNotes.count) / Double(numberOfNotesInOnegroup)))
        let height = topOffset + CGFloat(numberOfGroups) * (gapBetweenLines * 4 + gapBetweenGroups) + topOffset
        return height
    }

    func loadMIDIFile() {
      
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to access documents directory")
        }

       
        let destinationURL = documentsURL.appendingPathComponent("currentFile.mid")

       
        guard fileManager.fileExists(atPath: destinationURL.path) else {
            print("MIDI file not found at \(destinationURL.path)")
            return
        }

    
        do {
            let noteTuples = try extractMIDINoteNumbers(from: destinationURL.path)
            currentNotes = noteTuples
        } catch {
            print("Failed to read MIDI file: \(error)")
        }
    }

    func updateNotes(_ notes: [(UInt8,Velocity)]) {
           staffView.setNotes(midiNumbers: notes)
       }
    
}
