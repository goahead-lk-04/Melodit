//
//  ViewController.swift
//  Melodit
//
//  Created by Lisa Kuchyna on 2024-06-08.
//

import UIKit
import CoreML
import AVFoundation

let model = MusicModel()

class ViewController: UIViewController {
    
    

    
    @IBOutlet weak var upload_music_button: UIButton!
    
    
    @IBAction func click_upload_music(_ sender: Any) {
        getMusicFiles()
       
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    func getMusicFiles() {
        let documentPicker =
            UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        documentPicker.delegate = self

        present(documentPicker, animated: true, completion: nil)

    }
}

extension ViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else { return }
        
        model.processAudio(music_file: selectedFileURL)
        
        print("Selected file URL: \(selectedFileURL)")
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
  
        print("Document picker was cancelled")
    }
}

