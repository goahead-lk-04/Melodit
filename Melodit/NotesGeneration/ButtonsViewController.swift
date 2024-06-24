import UIKit

class ButtonsViewController : UIViewController {
    
    
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
        } else {
            print("Image not found")
        }
    }
    
    func saveAsPDF() {
     
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let notesVC = storyboard.instantiateViewController(withIdentifier: "ShowNotesController") as? ShowNotesController else {
            print("Failed to instantiate ShowNotesController")
            return
        }
        
        
        notesVC.loadViewIfNeeded()
        
        guard let staffView = notesVC.staffView else {
            print("staffView is not available")
            return
        }
        
     
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, staffView.bounds, nil)
        UIGraphicsBeginPDFPageWithInfo(staffView.bounds, nil)
        guard let pdfContext = UIGraphicsGetCurrentContext() else {
            print("Failed to create PDF")
            return
        }
        
        staffView.layer.render(in: pdfContext)
        UIGraphicsEndPDFContext()
        
      
        let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent("notesSheets.pdf")
        do {
            try pdfData.write(to: temporaryURL, options: .atomic)
            
           
            let documentPicker = UIDocumentPickerViewController(forExporting: [temporaryURL])
            documentPicker.delegate = self
            self.present(documentPicker, animated: true, completion: nil)
            
        } catch {
            print("Failed to save PDF: \(error)")
        }
    }
    
}

extension ButtonsViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
//        print("PDF saved at: \(url.path)")
    }
}
