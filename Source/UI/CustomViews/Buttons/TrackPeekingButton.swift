import Cocoa

/*
    A "smart" button that determines and sets its own tool tip dynamically based on logic (closure) that can be set externally. Useful when tool tips need to change based on app state, e.g. to display the previous/next track name in a tool tip for the previous/next track control buttons.
 */
@IBDesignable
<<<<<<< HEAD:Aural/TrackPeekingButton.swift
class TrackPeekingButton: ColorSensitiveImageButton {
=======
class TrackPeekingButton: TintedImageButton {
>>>>>>> upstream/master:Source/UI/CustomViews/Buttons/TrackPeekingButton.swift
    
    @IBInspectable var defaultTooltip: String!
    
    // This function will be invoked, on the fly (when the user hovers over the button), to determine the button's tool tip
    var toolTipFunction: (() -> String?)?
    
    override func awakeFromNib() {
        
        // Create a tracking area that covers the bounds of the view. It should respond whenever the mouse enters or exits.
        addTrackingArea(NSTrackingArea(rect: self.bounds, options: [NSTrackingArea.Options.activeAlways, NSTrackingArea.Options.mouseEnteredAndExited], owner: self, userInfo: nil))
        
        self.updateTrackingAreas()
    }
    
    func updateTooltip() {
        self.toolTip = toolTipFunction?() ?? defaultTooltip
    }
    
    override func mouseEntered(with event: NSEvent) {
        updateTooltip()
    }
}
