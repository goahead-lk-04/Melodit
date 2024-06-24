//
//  ShowNotesController.swift
//  Melodit
//
//  Created by Inna Boiko on 23.06.2024.
//

import UIKit

class ShowNotesController : UIViewController {
    
    @IBOutlet var staffView: StaffView!
    let noteconverter = NoteConverter()
    var currentNotes: [(UInt8,Velocity)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

              
        loadMIDIFile()
        setupStaffView()
        updateNotes(currentNotes)
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
    
    func setupStaffView() {
        guard let staffView = staffView else {
            print("StaffView is not initialized")
            return
        }
        staffView.frame = view.bounds
        staffView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        staffView.backgroundColor = .white
        view.addSubview(staffView)
    }

    func updateNotes(_ notes: [(UInt8,Velocity)]) {
           staffView.setNotes(midiNumbers: notes)
       }
    
}
