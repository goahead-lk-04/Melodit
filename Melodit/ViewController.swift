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
    
    var blurEffectView: UIVisualEffectView?
    
    var selectedFileURL: URL?
    
    @IBOutlet weak var piano_img: UIImageView!
    
    @IBOutlet weak var upload_music_button: UIButton!
    
    @IBAction func click_upload_music(_ sender: Any) {
        getMusicFiles()

        self.startAnimating()
    }
   
    @IBAction func goToNotes(_ sender: Any) {
        
        guard selectedFileURL != nil else {
            let alertController = UIAlertController(title: "No Music File Selected",
                                                       message: "Please upload a music file first.",
                                                       preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
            
            present(alertController, animated: true, completion: nil)
          
            return
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAnalyzing()
        
        if let image = UIImage(named: "piano") {
            piano_img.image = image
        } else {
            print("Image not found")
        }
    }
    
    func setupAnalyzing() {
        
        let blurEffect = UIBlurEffect(style: .light)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView?.frame = self.view.bounds
        blurEffectView?.alpha = 0.4
        blurEffectView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
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
            self.stopAnimating()
            
        } else {
            print("Error: Could not access security-scoped resource.")
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
  
        print("Document picker was cancelled")
    }

    
    func startAnimating() {
        
        if let blurEffectView = blurEffectView {
               self.view.addSubview(blurEffectView)
           }
        
        UIView.animate(withDuration: 0.3) {
            self.blurEffectView?.alpha = 0.8
        }
         
        UIView.animate(withDuration: 2.0, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.blurEffectView?.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        })
     
    }

    func stopAnimating() {
            
        blurEffectView?.layer.removeAllAnimations()
        UIView.animate(withDuration: 0.3, animations: {
            self.blurEffectView?.alpha = 0.0
        }) { _ in
            self.blurEffectView?.removeFromSuperview()
            self.blurEffectView = nil
        }
    }
}



