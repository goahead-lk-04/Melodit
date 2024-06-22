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
    
    
    @IBOutlet weak var upload_music_button: UIButton!
    
    @IBAction func click_upload_music(_ sender: Any) {
        model.processAudio(music_file: URL(fileURLWithPath: "/Users/lizzikuchyna/PycharmProjects/onsets-and-frames/data/MAPS/flac/MAPS_MUS-alb_se2_ENSTDkCl.flac"))
        getMusicFiles()
       
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        model.processAudio(music_file: URL(fileURLWithPath: "/Users/lizzikuchyna/PycharmProjects/onsets-and-frames/data/MAPS/flac/MAPS_MUS-alb_se2_ENSTDkCl.flac"))
        print("end")
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
        
        model.processAudio(music_file: URL(fileURLWithPath: "/Users/lizzikuchyna/PycharmProjects/onsets-and-frames/data/MAPS/flac/MAPS_MUS-alb_esp2_AkPnCGdD.flac"))
        
        print("Selected file URL: \(selectedFileURL)")
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
  
        print("Document picker was cancelled")
    }
}




