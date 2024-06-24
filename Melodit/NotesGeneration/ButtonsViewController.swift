//
//  ButtonsViewController.swift
//  Melodit
//
//  Created by Inna Boiko on 23.06.2024.
//


import UIKit

class ButtonsViewController : UIViewController {
    
    let navig_identifier = "notes"
    
    @IBOutlet weak var piano_img: UIImageView!
    @IBAction func showNotes(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let notesVC = storyboard.instantiateViewController(withIdentifier: "ShowNotesController") as? ShowNotesController {
            present(notesVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func downloadNotes(_ sender: Any) {
        saveAsPDF()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let image = UIImage(named: "piano") {
            piano_img.image = image
            piano_img.layer.cornerRadius = 60
        } else {
            print("Image not found")
        }
        
        
    }
    
    
    
    @objc func saveAsPDF() {
        let pdfFileName = "notessheets.pdf"
        let fileManager = FileManager.default
        
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to access documents directory")
        }
        

        let pdfFilePath = documentsURL.appendingPathComponent(pdfFileName)
        
          if let currentVC = navigationController?.visibleViewController as? ShowNotesController {
            let staffView = currentVC.staffView
            
            guard let staffView = staffView else {
                print("StaffView is not available")
                return
            }
            
            UIGraphicsBeginPDFContextToFile(pdfFilePath.path, staffView.bounds, nil)
            UIGraphicsBeginPDFPageWithInfo(staffView.bounds, nil)
            
            if let pdfContext = UIGraphicsGetCurrentContext() {
                staffView.layer.render(in: pdfContext)
            }
            
            UIGraphicsEndPDFContext()
            print("PDF saved at: \(pdfFilePath.path)")
        } else {
            print("ShowNotesController is not visible")
        }
    }
    
}
