import Cocoa

class FilterBandViewController: NSViewController {
    
    override var nibName: String? {return "FilterBand"}
    
    @IBOutlet weak var filterTypeMenu: NSPopUpButton!
    
    @IBOutlet weak var freqRangeSlider: FilterBandSlider!
    @IBOutlet weak var cutoffSlider: CutoffFrequencySlider!
    @IBOutlet weak var cutoffSliderCell: FilterCutoffFrequencySliderCell!
    
    @IBOutlet weak var lblRangeCaption: NSTextField!
    @IBOutlet weak var presetRangesMenu: NSPopUpButton!
    @IBOutlet weak var presetRangesIconMenuItem: TintedIconMenuItem!
    
    @IBOutlet weak var lblCutoffCaption: NSTextField!
    @IBOutlet weak var presetCutoffsMenu: NSPopUpButton!
    @IBOutlet weak var presetCutoffsIconMenuItem: TintedIconMenuItem!
    
    @IBOutlet weak var lblFrequencies: NSTextField!
    
    @IBOutlet weak var tabButton: NSButton!
    
    private var functionLabels: [NSTextField] = []
    
    private let filterUnit: FilterUnitDelegateProtocol = ObjectGraph.audioGraphDelegate.filterUnit
    
    var band: FilterBand = FilterBand.init(.bandStop).withMinFreq(AppConstants.Sound.audibleRangeMin).withMaxFreq(AppConstants.Sound.subBass_max)
    var bandIndex: Int!
    
    var bandChangedCallback: (() -> Void) = {() -> Void in
        // Do nothing
    }
    
    override func viewDidLoad() {
        
        oneTimeSetup()
        resetFields()
<<<<<<< HEAD:Aural/FilterBandViewController.swift
        changeTextSize()
        changeColorScheme()
=======
        
        applyFontScheme(FontSchemes.systemScheme)
        applyColorScheme(ColorSchemes.systemScheme)
    }
    
    private func oneTimeSetup() {
        
        freqRangeSlider.onControlChanged = {(slider: RangeSlider) -> Void in self.freqRangeChanged()}
        freqRangeSlider.stateFunction = filterUnit.stateFunction
        cutoffSlider.stateFunction = filterUnit.stateFunction
        
        functionLabels = findFunctionLabels(self.view)
        
        presetRangesIconMenuItem.tintFunction = {return Colors.functionButtonColor}
        presetCutoffsIconMenuItem.tintFunction = {return Colors.functionButtonColor}
>>>>>>> upstream/master:Source/UI/Effects/Filter/FilterBandViewController.swift
    }
    
    private func resetFields() {
        
        let filterType = band.type
        
        filterTypeMenu.selectItem(withTitle: filterType.description)
        
        [freqRangeSlider, lblRangeCaption, presetRangesMenu].forEach({$0?.showIf(filterType == .bandPass || filterType == .bandStop)})
        [cutoffSlider, lblCutoffCaption, presetCutoffsMenu].forEach({$0?.hideIf(filterType == .bandPass || filterType == .bandStop)})
        
        if filterType == .bandPass || filterType == .bandStop {
            
            freqRangeSlider.filterType = filterType
            
            freqRangeSlider.setFrequencyRange(band.minFreq!, band.maxFreq!)
            lblFrequencies.stringValue = String(format: "[ %@ - %@ ]", formatFrequency(freqRangeSlider.startFrequency), formatFrequency(freqRangeSlider.endFrequency))
            
            cutoffSlider.setFrequency(AppConstants.Sound.audibleRangeMin)
            
        } else {
            
            cutoffSlider.setFrequency(filterType == .lowPass ? band.maxFreq! : band.minFreq!)
            
            cutoffSliderCell.filterType = filterType
            cutoffSlider.redraw()
            lblFrequencies.stringValue = formatFrequency(cutoffSlider.frequency)
            
            freqRangeSlider.setFrequencyRange(AppConstants.Sound.audibleRangeMin, AppConstants.Sound.subBass_max)
        }
        
        freqRangeSlider.updateState()
        cutoffSlider.updateState()
        
        presetCutoffsMenu.selectItem(at: -1)
        presetRangesMenu.selectItem(at: -1)
    }
    
    @IBAction func bandTypeAction(_ sender: Any) {
        
        let filterType = FilterBandType.fromDescription(filterTypeMenu.titleOfSelectedItem!)
        band.type = filterType
        
        [freqRangeSlider, lblRangeCaption, presetRangesMenu].forEach({$0?.showIf(filterType == .bandPass || filterType == .bandStop)})
        [cutoffSlider, lblCutoffCaption, presetCutoffsMenu].forEach({$0?.hideIf(filterType == .bandPass || filterType == .bandStop)})
        
        if filterType == .bandPass || filterType == .bandStop {
            
            freqRangeSlider.filterType = filterType
            freqRangeChanged()
            
            band.minFreq = freqRangeSlider.startFrequency
            band.maxFreq = freqRangeSlider.endFrequency
            
        } else {
            
            cutoffSliderCell.filterType = filterType
            cutoffSlider.redraw()
            cutoffSliderAction(self)
            
            band.minFreq = filterType == .lowPass ? nil : cutoffSlider.frequency
            band.maxFreq = filterType == .lowPass ? cutoffSlider.frequency : nil
        }
        
        filterUnit.updateBand(bandIndex, band)
        
        bandChangedCallback()
    }
    
    private func freqRangeChanged() {
        
        band.minFreq = freqRangeSlider.startFrequency
        band.maxFreq = freqRangeSlider.endFrequency
        
        filterUnit.updateBand(bandIndex, band)
        
        lblFrequencies.stringValue = String(format: "[ %@ - %@ ]", formatFrequency(freqRangeSlider.startFrequency), formatFrequency(freqRangeSlider.endFrequency))
        
        bandChangedCallback()
    }
    
    @IBAction func cutoffSliderAction(_ sender: Any) {
        
        band.minFreq = band.type == .lowPass ? nil : cutoffSlider.frequency
        band.maxFreq = band.type == .lowPass ? cutoffSlider.frequency : nil
        
        filterUnit.updateBand(bandIndex, band)
        
        lblFrequencies.stringValue = formatFrequency(cutoffSlider.frequency)
        
        bandChangedCallback()
    }
    
    @IBAction func presetRangeAction(_ sender: NSPopUpButton) {
        
        if let range = sender.selectedItem as? FrequencyRangeMenuItem {
            
            freqRangeSlider.setFrequencyRange(range.minFreq, range.maxFreq)
            freqRangeChanged()
        }
        
        presetRangesMenu.selectItem(at: -1)
    }
    
    @IBAction func presetCutoffAction(_ sender: NSPopUpButton) {
        
        cutoffSlider.setFrequency(Float(sender.selectedItem!.tag))
        cutoffSliderAction(self)
        presetCutoffsMenu.selectItem(at: -1)
    }
    
    private func formatFrequency(_ freq: Float) -> String {
        
        let rounded = roundedInt(freq)
        
        if rounded % 1000 == 0 {
            return String(format: "%d KHz", rounded / 1000)
        } else {
            return String(format: "%d Hz", rounded)
        }
    }
    
    func stateChanged() {
        
        freqRangeSlider.updateState()
        cutoffSlider.updateState()
    }
    
    func applyFontScheme(_ fontScheme: FontScheme) {
        
        tabButton.redraw()
        
        functionLabels.forEach({$0.font = FontSchemes.systemScheme.effects.unitFunctionFont})
        
        filterTypeMenu.font = FontSchemes.systemScheme.effects.unitFunctionFont
        filterTypeMenu.redraw()
        
<<<<<<< HEAD:Aural/FilterBandViewController.swift
        presetRangesMenu.font = TextSizes.fxUnitFunctionFont
        presetCutoffsMenu.font = TextSizes.fxUnitFunctionFont
    }
    
    func changeColorScheme() {
        
        tabButton.redraw()
        
        let labels = findFunctionLabels(self.view)
        labels.forEach({$0.textColor = Colors.fxUnitFunctionColor})
        
        // TODO: Redraw the sliders
        cutoffSlider.redraw()
        freqRangeSlider.redraw()
=======
        presetRangesMenu.font = FontSchemes.systemScheme.effects.unitFunctionFont
        lblFrequencies.font = FontSchemes.systemScheme.effects.unitFunctionFont
    }
    
    func applyColorScheme(_ scheme: ColorScheme) {
        
        changeFunctionButtonColor()
        changeTextButtonMenuColor()
        changeFunctionCaptionTextColor(scheme.effects.functionCaptionTextColor)
        changeFunctionValueTextColor(scheme.effects.functionValueTextColor)
        redrawSliders()
        tabButton.redraw()
    }
    
    func changeFunctionButtonColor() {
        [presetCutoffsIconMenuItem, presetRangesIconMenuItem].forEach({$0?.reTint()})
    }

    func changeTextButtonMenuColor() {
        filterTypeMenu.redraw()
    }
    
    func changeButtonMenuTextColor() {
        filterTypeMenu.redraw()
    }
    
    func changeFunctionCaptionTextColor(_ color: NSColor) {
        functionLabels.forEach({$0.textColor = color})
    }
    
    func changeFunctionValueTextColor(_ color: NSColor) {
        lblFrequencies.textColor = color
    }
    
    func redrawSliders() {
        [cutoffSlider, freqRangeSlider].forEach({$0?.redraw()})
>>>>>>> upstream/master:Source/UI/Effects/Filter/FilterBandViewController.swift
    }
    
    private func findFunctionLabels(_ view: NSView) -> [NSTextField] {
        
        var labels: [NSTextField] = []
        
        for subview in view.subviews {
            
            if let label = subview as? NSTextField, !(label is FunctionValueLabel) {
                labels.append(label)
            }
            
            // Recursive call
            let subviewLabels = findFunctionLabels(subview)
            labels.append(contentsOf: subviewLabels)
        }
        
        return labels
    }
}

@IBDesignable
class FrequencyRangeMenuItem: NSMenuItem {
    
    @IBInspectable var minFreq: Float = AppConstants.Sound.audibleRangeMin
    @IBInspectable var maxFreq: Float = AppConstants.Sound.audibleRangeMax
}
