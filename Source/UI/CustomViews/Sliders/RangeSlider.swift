//
//  RangeSlider.swift
//  RangeSlider
//
//  Created by Matt Reagan on 10/29/16.
//  Copyright © 2016 Matt Reagan.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
//  modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
//  WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
//  OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import Foundation
import Cocoa

struct SelectionRange {
    var start: Double
    var end: Double
}

enum DraggedSlider {
    case start
    case end
}

fileprivate let bandStopColor: NSColor = NSColor(red: 0.65, green: 0, blue: 0, alpha: 1)
fileprivate let bandPassColor: NSColor = NSColor(red: 0, green: 0.45, blue: 0, alpha: 1)
fileprivate let bypassedColor: NSColor = Colors.Constants.white35Percent
fileprivate let suppressedColor: NSColor = NSColor(red: 0.53, green: 0.4, blue: 0, alpha: 1)

@IBDesignable
<<<<<<< HEAD:Aural/RangeSlider.swift
class RangeSlider: MouseTrackingView, EffectsUnitSliderProtocol {
=======
class RangeSlider: NSControl, EffectsUnitSliderProtocol {
>>>>>>> upstream/master:Source/UI/CustomViews/Sliders/RangeSlider.swift
    
    //****************************************************************************//
    //****************************************************************************//
    /*
     RangeSlider is a general-purpose macOS control which is similar to NSSlider
     except that it allows for the selection of a span or range (it has two control
     points, a start and end, which can both be adjusted).
     */
    //****************************************************************************//
    //****************************************************************************//
    
    override func awakeFromNib() {
        self.startTracking()
    }
    
    //MARK: - Public API -
    
    @IBInspectable var index: Int = 0
    
    var unitState: EffectsUnitState = .bypassed {
        
        didSet {
            redraw()
        }
    }
    
    var stateFunction: (() -> EffectsUnitState)?
    
    func updateState() {
        
        if let function = stateFunction {
            
            unitState = function()
            redraw()
        }
    }
    
    private let verticalShadowPadding: CGFloat = 4.0
    private let barTrailingMargin: CGFloat = 1.0
    private let disabledControlDimmingRatio: CGFloat = 0.65
    
    var shouldTriggerHandler: Bool = true
    
    /** Optional action block, called when the control's start or end values change. */
    var onControlChanged : ((RangeSlider) -> Void)?
    
    /** The start of the selected span in the slider. */
    var start: Double {
        get {
            return (selection.start * (maxValue - minValue)) + minValue
        }
        
        set {
            let fractionalStart = (newValue - minValue) / (maxValue - minValue)
            selection = SelectionRange(start: fractionalStart, end: selection.end)
            redraw()
        }
    }
    
    /** The end of the selected span in the slider. */
    var end: Double {
        get {
            return (selection.end * (maxValue - minValue)) + minValue
        }
        
        set {
            let fractionalEnd = (newValue - minValue) / (maxValue - minValue)
            selection = SelectionRange(start: selection.start, end: fractionalEnd)
            redraw()
        }
    }
    
    /** The length of the selected span. Note that by default
     this length is inclusive when snapsToIntegers is true,
     which will be the expected/desired behavior in most such
     configurations. In scenarios where it may be weird to have
     a length of 1.0 when the start and end slider are at an
     identical value, you can disable this by setting
     inclusiveLengthForSnapTo to false. */
    var length: Double {
        get {
            let fractionalLength = (selection.end - selection.start)
            
            return (fractionalLength * (maxValue - minValue))
        }
    }
    
    /** The minimum value of the slider. */
    @IBInspectable var minValue: Double = 0.0 {
        didSet {
            redraw()
        }
    }
    
    /** The maximum value of the slider. */
    @IBInspectable var maxValue: Double = 1.0 {
        didSet {
            redraw()
        }
    }
    
    //****************************************************************************//
    //****************************************************************************//
    
    //MARK: - Properties -
    
    var selection: SelectionRange = SelectionRange(start: 0.0, end: 1.0) {
        
        willSet {
            if newValue.start != selection.start {
                self.willChangeValue(forKey: "start")
            }
            
            if newValue.end != selection.end {
                self.willChangeValue(forKey: "end")
            }
            
            if (newValue.end - newValue.start) != (selection.end - selection.start) {
                self.willChangeValue(forKey: "length")
            }
        }
        
        didSet {
            var valuesChanged: Bool = false
            
            if oldValue.start != selection.start {
                self.didChangeValue(forKey: "start")
                valuesChanged = true
            }
            
            if oldValue.end != selection.end {
                self.didChangeValue(forKey: "end")
                valuesChanged = true
            }
            
            if (oldValue.end - oldValue.start) != (selection.end - selection.start) {
                self.didChangeValue(forKey: "length")
            }
            
            if valuesChanged {
                if shouldTriggerHandler, let block = onControlChanged {
                    block(self)
                }
            }
        }
    }
    
    private var currentSliderDragging: DraggedSlider? = nil
    
    //MARK: - Appearance -
    
    let _barBackgroundColor: NSColor = NSColor(white: 0.2, alpha: 1.0)
    
    var barBackgroundColor: NSColor {return _barBackgroundColor}
    
    private lazy var sliderGradient: NSGradient = {
        let backgroundStart = NSColor(white: 0.92, alpha: 1.0)
        let backgroundEnd =  NSColor(white: 0.80, alpha: 1.0)
        let barBackgroundColor = NSGradient(starting: backgroundStart, ending: backgroundEnd)
        assert(barBackgroundColor != nil, "Couldn't generate gradient.")
        
        return barBackgroundColor!
    }()
    
<<<<<<< HEAD:Aural/RangeSlider.swift
    var knobColor: NSColor {return Colors.neutralKnobColor}
=======
    // TODO: Change this to a computed color
    var knobColor: NSColor {return Colors.Constants.white50Percent}
>>>>>>> upstream/master:Source/UI/CustomViews/Sliders/RangeSlider.swift
    
    var barFillColor: NSColor {
        
        switch unitState {
            
        case .active:   return bandPassColor
            
        case .bypassed: return bypassedColor
            
        case .suppressed:   return suppressedColor
            
        }
    }
    
    private let barStrokeColor: NSColor = NSColor(white: 0.0, alpha: 0.25)
    
    private var barFillStrokeColor: NSColor = NSColor(deviceRed: CGFloat(0.7), green: CGFloat(0.7), blue: CGFloat(0.7), alpha: CGFloat(1))
    
    private var _sliderShadow: NSShadow? = nil
    private func sliderShadow() -> NSShadow? {
        
        if (_sliderShadow == nil) {
            let shadowOffset = NSMakeSize(2.0, -2.0)
            let shadowBlurRadius: CGFloat = 2.0
            let shadowColor = NSColor(white: 0.0, alpha: 0.12)
            
            let shadow = NSShadow()
            shadow.shadowOffset = shadowOffset
            shadow.shadowBlurRadius = shadowBlurRadius
            shadow.shadowColor = shadowColor
            
            _sliderShadow = shadow
        }
        
        return _sliderShadow
    }
    
    //MARK: - UI Sizing -
    
<<<<<<< HEAD:Aural/RangeSlider.swift
    private let sliderWidth: CGFloat = 9
    private let sliderHeight: CGFloat = 9
=======
    private let sliderWidth: CGFloat = 10
    private let sliderHeight: CGFloat = 5
>>>>>>> upstream/master:Source/UI/CustomViews/Sliders/RangeSlider.swift
    
    private let minSliderX: CGFloat = 0
    private var maxSliderX: CGFloat { return NSWidth(bounds) - sliderWidth - barTrailingMargin }
    
    //MARK: - Event -
    
    override func updateTrackingAreas() {
        
        if !isTracking {return}
        
        // Create a tracking area that covers the bounds of the view. It should respond whenever the mouse enters or exits.
        
        self.trackingArea = NSTrackingArea(rect: self.bounds, options: [NSTrackingArea.Options.activeAlways,  NSTrackingArea.Options.mouseEnteredAndExited], owner: self, userInfo: nil)
        
        // Add the new tracking area to the view
        addTrackingArea(self.trackingArea!)
    }
    
    // This function is a workaround to get the slider working in a window with no title bar and when nested within a tabless tab view
    override func mouseEntered(with event: NSEvent) {
        
        super.mouseEntered(with: event)
        window?.isMovableByWindowBackground = false
    }
    
    // This function is a workaround to get the slider working in a window with no title bar and when nested within a tabless tab view
    override func mouseExited(with event: NSEvent) {
        
        super.mouseExited(with: event)
        window?.isMovableByWindowBackground = true
    }
    
    override func mouseDown(with event: NSEvent) {
        
        if !isEnabled {return}

        let point = convert(event.locationInWindow, from: nil)
        let startSlider = startKnobFrame()
        let endSlider = endKnobFrame()
        
        if NSPointInRect(point, startSlider) {
            currentSliderDragging = .start
        } else if NSPointInRect(point, endSlider) {
            currentSliderDragging = .end
        } else {
            
            let startDist = abs(NSMidX(startSlider) - point.x)
            let endDist = abs(NSMidX(endSlider) - point.x)
            
            if (startDist < endDist) {
                currentSliderDragging = .start
            } else {
                currentSliderDragging = .end
            }
            
            updateForClick(atPoint: point)
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        
        if isEnabled {
        
            let point = convert(event.locationInWindow, from: nil)
            updateForClick(atPoint: point)
        }
    }
    
    private func updateForClick(atPoint point: NSPoint) {
        
        if currentSliderDragging != nil {
            
            var x = Double(point.x / NSWidth(bounds))
            x = max(min(1.0, x), 0.0)
            
            if currentSliderDragging! == .start {
                selection = SelectionRange(start: x, end: max(selection.end, x))
            } else {
                selection = SelectionRange(start: min(selection.start, x), end: x)
            }
            
            redraw()
        }
    }
    
    //MARK: - Utility -
    
    private func crispLineRect(_ rect: NSRect) -> NSRect {
        /*  Floor the rect values here, rather than use NSIntegralRect etc. */
        var newRect = NSMakeRect(floor(rect.origin.x),
                                 floor(rect.origin.y),
                                 floor(rect.size.width),
                                 floor(rect.size.height))
        newRect.origin.x += 0.5
        newRect.origin.y += 0.5
        
        return newRect
    }
    
    private func startKnobFrame() -> NSRect {
        var x = max(CGFloat(selection.start) * NSWidth(bounds) - (sliderWidth / 2.0), minSliderX)
        x = min(x, maxSliderX)
        
        return crispLineRect(NSMakeRect(x, (NSHeight(bounds) - sliderHeight) / 2.0, sliderWidth, sliderHeight))
    }
    
    private func endKnobFrame() -> NSRect {
        let width = NSWidth(bounds)
        var x = CGFloat(selection.end) * width
        x -= (sliderWidth / 2.0)
        x = min(x, maxSliderX)
        x = max(x, minSliderX)
        
        return crispLineRect(NSMakeRect(x, (NSHeight(bounds) - sliderHeight) / 2.0, sliderWidth, sliderHeight))
    }
    
    //MARK: - Layout
    
    override func layout() {
        super.layout()
        
        assert(NSWidth(bounds) >= (NSHeight(bounds) * 2), "Range control expects a reasonable width to height ratio, width should be greater than twice the height at least.");
        assert(NSWidth(bounds) >= (sliderWidth * 2.0), "Width must be able to accommodate two range sliders.")
        assert(NSHeight(bounds) >= sliderHeight, "Expects minimum height of at least \(sliderHeight)")
    }
    
    //MARK: - Drawing -
    
    override func draw(_ dirtyRect: NSRect) {
        
        /*  Setup, calculations */
        let width = NSWidth(bounds) - barTrailingMargin
        let height = NSHeight(bounds)
        
        let barHeight: CGFloat = 5
        let barY = floor((height - barHeight) / 2.0)
        
        let startSliderFrame = startKnobFrame()
        let endSliderFrame = endKnobFrame()
        
        let barRect = crispLineRect(NSMakeRect(0, barY, width, barHeight))
        let selectedRect = crispLineRect(NSMakeRect(CGFloat(selection.start) * width, barY,
                                                    width * CGFloat(selection.end - selection.start), barHeight))
        
        /*  Create bezier paths */
        let framePath = NSBezierPath(roundedRect: barRect, xRadius: 1.5, yRadius: 1.5)
        let selectedPath = NSBezierPath(roundedRect: selectedRect, xRadius: 1.5, yRadius: 1.5)
        
        let startSliderPath = NSBezierPath(roundedRect: startSliderFrame, xRadius: 2, yRadius: 2)
        let endSliderPath = NSBezierPath(roundedRect: endSliderFrame, xRadius: 2, yRadius: 2)
        
        barBackgroundColor.setFill()
        framePath.fill()
        
//        /*  Draw bar background */
//        barBackgroundColor.draw(in: framePath, angle: -UIConstants.horizontalGradientDegrees)
        
        /*  Draw bar fill */
        if NSWidth(selectedRect) > 0.0 {

            barFillColor.setFill()
            selectedPath.fill()
            barFillStrokeColor.setStroke()
        }
        
        barStrokeColor.setStroke()
        framePath.stroke()
        
        /*  Draw slider shadows */
        if let shadow = sliderShadow() {
            NSGraphicsContext.saveGraphicsState()
            shadow.set()
            
            NSColor.white.set()
            startSliderPath.fill()
            endSliderPath.fill()
            NSGraphicsContext.restoreGraphicsState()
        }
        
        /*  Draw slider knobs */
        sliderGradient.draw(in: endSliderPath, angle: UIConstants.horizontalGradientDegrees)
        endSliderPath.stroke()
        
        sliderGradient.draw(in: startSliderPath, angle: UIConstants.horizontalGradientDegrees)
        startSliderPath.stroke()
        
        knobColor.setFill()
        
        startSliderPath.fill()
        endSliderPath.fill()
    }
}

extension NSColor {
    func colorByDesaturating(_ desaturationRatio: CGFloat) -> NSColor {
        return NSColor(hue: self.hueComponent,
                       saturation: self.saturationComponent * desaturationRatio,
                       brightness: self.brightnessComponent,
                       alpha: self.alphaComponent);
    }
}

class FilterBandSlider: RangeSlider {
    
    var filterType: FilterBandType = .bandStop {
        
        didSet {
            redraw()
        }
    }
    
    override var barFillColor: NSColor {
        
        switch unitState {
            
        case .active:   return filterType == .bandPass ? Colors.Effects.activeUnitStateColor : Colors.Effects.bypassedUnitStateColor
            
        case .bypassed: return Colors.Effects.bypassedUnitStateColor
            
        case .suppressed:   return Colors.Effects.suppressedUnitStateColor
            
        }
    }
    
    override var knobColor: NSColor {
<<<<<<< HEAD:Aural/RangeSlider.swift
        
        switch unitState {
            
        case .active:   return filterType == .bandPass ? bandPassColor : bandStopColor
            
        case .bypassed: return bypassedColor
            
        case .suppressed:   return suppressedColor
            
        }
=======
        return ColorSchemes.systemScheme.effects.sliderKnobColorSameAsForeground ? barFillColor : ColorSchemes.systemScheme.effects.sliderKnobColor
    }
    
    override var barBackgroundColor: NSColor {
        return Colors.Effects.sliderBackgroundColor
>>>>>>> upstream/master:Source/UI/CustomViews/Sliders/RangeSlider.swift
    }
    
    var startFrequency: Float {
        return Float(20 * pow(10, (start - 20) / 6660))
    }
    
    var endFrequency: Float {
        return Float(20 * pow(10, (end - 20) / 6660))
    }
    
    func setFrequencyRange(_ min: Float, _ max: Float) {
        
        let temp = shouldTriggerHandler
        shouldTriggerHandler = false
        
        start = Double(6660 * log10(min/20) + 20)
        end = Double(6660 * log10(max/20) + 20)
        
        shouldTriggerHandler = temp
    }
}
