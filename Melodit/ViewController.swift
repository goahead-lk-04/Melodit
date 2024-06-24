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
    
    var analyzingSign: UIView!
    
    @IBAction func click_upload_music(_ sender: Any) {
        getMusicFiles()

        self.startAnimatingBall()
    }
   
    @IBAction func goToNotes(_ sender: Any) {
        
        guard selectedFileURL != nil else {
               let alertController = UIAlertController(title: "No Music File Selected",
                                                       message: "Please upload a music file first.",
                                                       preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                }))
               present(alertController, animated: true, completion: nil)
          
               return
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAnalyzingSign()
        
        
        if let image = UIImage(named: "piano") {
            piano_img.image = image
        } else {
            print("Image not found")
        }
        
        
    }
    
    func setupAnalyzingSign() {
        
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
            

            self.stopAnimatingBall()
        } else {
            print("Error: Could not access security-scoped resource.")
        }
        
        
        print("Selected file URL: \(selectedFileURL)")
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
  
        print("Document picker was cancelled")
    }
    
    func fileSavingDidComplete() {
        
        print("here1")
            DispatchQueue.main.async {
                self.stopAnimatingBall()
            }
        }
    
    func startAnimatingBall() {
        
        if let blurEffectView = blurEffectView {
               self.view.addSubview(blurEffectView)
           }
        
        // Show blur effect view with animation
            UIView.animate(withDuration: 0.3) {
                self.blurEffectView?.alpha = 0.8
            }
            
            // Simulate an animation by scaling the blurEffectView itself
            UIView.animate(withDuration: 2.0, delay: 0, options: [.repeat, .autoreverse], animations: {
                self.blurEffectView?.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            })
     
        print("aa")
//        self.analyzingSign.transform = CGAffineTransform.identity
//            UIView.animate(withDuration: 2.0, delay: 0, options: [.repeat, .autoreverse], animations: {
//                self.analyzingSign.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
//            })
    }

        func stopAnimatingBall() {
            
            //self.analyzingSign.isHidden = true
            blurEffectView?.layer.removeAllAnimations()
               
               // Hide blur effect view with animation
               UIView.animate(withDuration: 0.3, animations: {
                   self.blurEffectView?.alpha = 0.0
               }) { _ in
                   // Remove blur effect view from superview
                   self.blurEffectView?.removeFromSuperview()
                   self.blurEffectView = nil
               }
        }
}



