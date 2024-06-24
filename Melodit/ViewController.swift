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
    
    var selectedFileURL: URL?
    @IBOutlet weak var piano_img: UIImageView!
    
    @IBOutlet weak var upload_music_button: UIButton!
    
    @IBAction func click_upload_music(_ sender: Any) {
        getMusicFiles()

    }
   
    @IBAction func goToNotes(_ sender: Any) {
        
        guard selectedFileURL != nil else {
               let alertController = UIAlertController(title: "No Music File Selected",
                                                       message: "Please upload a music file first.",
                                                       preferredStyle: .alert)
               alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
               present(alertController, animated: true, completion: nil)
               return
           }
        
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//                   if let buttonsVC = storyboard.instantiateViewController(withIdentifier: "ButtonsViewController") as? ButtonsViewController {
//                       navigationController?.pushViewController(buttonsVC, animated: true)
//                   }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let image = UIImage(named: "piano") {
            piano_img.image = image
//            piano_img.layer.cornerRadius = 60
        } else {
            print("Image not found")
        }
//        view.backgroundColor = UIColor(named: "backgroundC")
        
        
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
        self.selectedFileURL = selectedFileURL
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




