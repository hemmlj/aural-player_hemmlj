import Cocoa

@IBDesignable
class EffectsUnitTabButtonCell: NSButtonCell {
    
    private var selectionBoxColor: NSColor {return Colors.selectedTabButtonColor}
    
    var unitState: EffectsUnitState = .bypassed

    @IBInspectable var imgWidth: Int = 14
    @IBInspectable var imgHeight: Int = 14
    
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        drawInterior(withFrame: cellFrame, in: controlView)
    }
    
    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        
        // Draw image (left aligned)
        let rectWidth: CGFloat = cellFrame.width, rectHeight: CGFloat = cellFrame.height
        let xInset = (rectWidth - CGFloat(imgWidth)) / 2
        let yInset = (rectHeight - CGFloat(imgHeight)) / 2
        
        // Raise the selected tab image by a few pixels so it is prominent
        let imgRect = cellFrame.insetBy(dx: xInset, dy: yInset).offsetBy(dx: 0, dy: isOn ? -2 : 0)
        self.image?.draw(in: imgRect)
        
        // Selection underline
        if isOn {
            
            let drawRect = NSRect(x: cellFrame.centerX - (imgRect.width / 2), y: cellFrame.maxY - 2, width: imgRect.width, height: 2)
            
            selectionBoxColor.setFill()
            drawRect.fill()
        }
    }
}
