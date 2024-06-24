//
//  ViewController.swift
//  Melodit
//
//  Created by Lisa Kuchyna on 2024-06-08.
//

import UIKit
import CoreML
import AVFoundation
import Accelerate


let model = MusicModel()

class ViewController: UIViewController {
    
    
    @IBOutlet weak var piano_img: UIImageView!
    
    @IBOutlet weak var upload_music_button: UIButton!
    
    @IBAction func click_upload_music(_ sender: Any) {
        getMusicFiles()
    }
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let image = UIImage(named: "piano") {
            piano_img.image = image
            piano_img.layer.cornerRadius = 60
        } else {
            print("Image not found")
        }
        view.backgroundColor = UIColor(named: "backgroundC")
        
        model.processAudio(music_file: URL(fileURLWithPath: "/Users/lizzikuchyna/AppleProjects/Melodit/midi/example.flac"))
        
    }
    
    func getMusicFiles() {
        let documentTypes = [UTType(filenameExtension: "flac")!]
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: documentTypes)
                
        documentPicker.delegate = self

        present(documentPicker, animated: true, completion: nil)

    }
    

}

extension ViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else { return }
                
        if selectedFileURL.startAccessingSecurityScopedResource() {
            defer {
                selectedFileURL.stopAccessingSecurityScopedResource()
            }
            print("Selected file URL: \(selectedFileURL)")
    
            model.processAudio(music_file: selectedFileURL)
        } else {
            print("Error: Could not access security-scoped resource.")
        }
        
        
        print("Selected file URL: \(selectedFileURL)")
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
  
        print("Document picker was cancelled")
    }
}




