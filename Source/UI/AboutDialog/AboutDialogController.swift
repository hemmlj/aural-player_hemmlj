import Cocoa

<<<<<<< HEAD:Aural/AboutDialogController.swift
class AboutDialogController: NSWindowController {
=======
class AboutDialogController: NSWindowController, ModalComponentProtocol {
>>>>>>> upstream/master:Source/UI/AboutDialog/AboutDialogController.swift
    
    override var windowNibName: String? {return "AboutDialog"}
    
    @IBOutlet weak var versionLabel: NSTextField! {
        
        didSet {
            
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
            versionLabel.stringValue = appVersion
        }
    }
<<<<<<< HEAD:Aural/AboutDialogController.swift
=======
    
    override func windowDidLoad() {
        WindowManager.registerModalComponent(self)
    }
    
    var isModal: Bool {
        return self.window?.isVisible ?? false
    }
>>>>>>> upstream/master:Source/UI/AboutDialog/AboutDialogController.swift
}
