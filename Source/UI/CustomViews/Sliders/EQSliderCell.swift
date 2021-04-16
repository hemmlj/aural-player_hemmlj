/*
 Customizes the look and feel of the parametric EQ sliders
 */

import Cocoa

class EQSliderCell: NSSliderCell, EffectsUnitSliderCellProtocol {
    
    let barRadius: CGFloat = 0.75
    let barInsetX: CGFloat = 0
    let barInsetY: CGFloat = 0
    
    let knobHeight: CGFloat = 10
<<<<<<< HEAD:Aural/EQSliderCell.swift
    let knobInsetX: CGFloat = 1.5
    let knobInsetY: CGFloat = 0
    let knobRadius: CGFloat = 2
    let knobWidthOutsideBar: CGFloat = 3.5
=======
    let knobRadius: CGFloat = 1
    let knobWidthOutsideBar: CGFloat = 1.5
>>>>>>> upstream/master:Source/UI/CustomViews/Sliders/EQSliderCell.swift
    
    var unitState: EffectsUnitState = .bypassed
    
    var foregroundGradient: NSGradient {
    
        switch self.unitState {
        
        case .active:   return Colors.Effects.activeSliderGradient
        
        case .bypassed: return Colors.Effects.bypassedSliderGradient
        
        case .suppressed:   return Colors.Effects.suppressedSliderGradient
        
        }
    }
    
    var backgroundGradient: NSGradient {
        return Colors.Effects.sliderBackgroundGradient
    }
    
    var knobColor: NSColor {
        return Colors.Effects.sliderKnobColorForState(self.unitState)
    }
    
    // Force knobRect and barRect to NOT be flipped
    
    override func knobRect(flipped: Bool) -> NSRect {
        return super.knobRect(flipped: SystemUtils.isBigSur)
    }
    
    override func barRect(flipped: Bool) -> NSRect {
        
        if SystemUtils.isBigSur {
            return NSRect(x: 10, y: 2, width: 4, height: super.barRect(flipped: false).height)
        } else {
            return super.barRect(flipped: false)
        }
    }
    
    override internal func drawKnob(_ knobRect: NSRect) {
        
        let rectHeight = knobRect.height
        let bar = barRect(flipped: false).insetBy(dx: barInsetX, dy: barInsetY)
        let yCenter = knobRect.minY + (rectHeight / 2)

        let knobWidth: CGFloat = bar.width + knobWidthOutsideBar
        let knobMinY = yCenter - (knobHeight / 2)
        let rect = NSRect(x: bar.minX - ((knobWidth - bar.width) / 2), y: knobMinY, width: knobWidth, height: knobHeight)

        let knobPath = NSBezierPath(roundedRect: rect, xRadius: knobRadius, yRadius: knobRadius)
        knobColor.setFill()
        knobPath.fill()
    }
    
    override internal func drawBar(inside drawRect: NSRect, flipped: Bool) {
        
        let knobFrame = knobRect(flipped: false)
        let halfKnobWidth = knobFrame.width / 2
        
        let topRect = NSRect(x: drawRect.minX, y: drawRect.minY, width: drawRect.width, height: knobFrame.minY + halfKnobWidth).insetBy(dx: barInsetX, dy: barInsetY)
        
        let bottomRect = NSRect(x: drawRect.minX, y: knobFrame.maxY - halfKnobWidth, width: drawRect.width, height: drawRect.height - knobFrame.maxY + halfKnobWidth).insetBy(dx: barInsetX, dy: barInsetY)
        
        // Bottom rect
        var drawPath = NSBezierPath.init(roundedRect: bottomRect, xRadius: barRadius, yRadius: barRadius)
        
        foregroundGradient.draw(in: drawPath, angle: -UIConstants.verticalGradientDegrees)
        
        // Top rect
        drawPath = NSBezierPath.init(roundedRect: topRect, xRadius: barRadius, yRadius: barRadius)
        backgroundGradient.draw(in: drawPath, angle: -UIConstants.verticalGradientDegrees)
        
        // Draw one tick across the center of the bar (marking 0dB)
        let tickMinX = drawRect.minX + 1
        let tickMaxX = drawRect.maxX - 1
        
        let tickRect = rectOfTickMark(at: 0)
        let y = (tickRect.minY + tickRect.maxY) / 2
        
        // Tick
<<<<<<< HEAD:Aural/EQSliderCell.swift
        GraphicsUtils.drawLine(Colors.sliderNotchColor, pt1: NSMakePoint(tickMinX, y), pt2: NSMakePoint(tickMaxX, y), width: 2)
=======
        GraphicsUtils.drawLine(Colors.Effects.sliderTickColor, pt1: NSMakePoint(tickMinX, y), pt2: NSMakePoint(tickMaxX, y), width: 2)
>>>>>>> upstream/master:Source/UI/CustomViews/Sliders/EQSliderCell.swift
    }
    
    override func drawTickMarks() {
        // Do nothing (ticks are drawn in drawBar)
    }
}
