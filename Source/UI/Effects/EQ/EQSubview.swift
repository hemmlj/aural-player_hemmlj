import Cocoa

class EQSubview: NSView {
    
    @IBOutlet weak var globalGainSlider: EffectsUnitSlider!
    
    var bandSliders: [EffectsUnitSlider] = []
    var allSliders: [EffectsUnitSlider] = []
    
    override func awakeFromNib() {
        
        for subView in self.subviews {
            
            if let slider = subView as? EffectsUnitSlider {
                
                if slider.tag >= 0 {bandSliders.append(slider)}
                allSliders.append(slider)
            }
        }
    }
    
    func initialize(_ stateFunction: @escaping EffectsUnitStateFunction, _ sliderAction: Selector?, _ sliderActionTarget: AnyObject?) {
        
        allSliders.forEach({$0.stateFunction = stateFunction})
        
        bandSliders.forEach({
            $0.action = sliderAction
            $0.target = sliderActionTarget
        })
    }
    
    func stateChanged() {
        allSliders.forEach({$0.updateState()})
    }
    
    func changeSliderColor() {
        allSliders.forEach({$0.redraw()})
    }
    
    func changeActiveUnitStateColor(_ color: NSColor) {
        allSliders.forEach({$0.redraw()})
    }
    
    func changeBypassedUnitStateColor(_ color: NSColor) {
        allSliders.forEach({$0.redraw()})
    }
    
    func changeSuppressedUnitStateColor(_ color: NSColor) {
        allSliders.forEach({$0.redraw()})
    }
    
    func setState(_ state: EffectsUnitState) {
        allSliders.forEach({$0.setUnitState(state)})
    }
    
    func updateBands(_ bands: [Float], _ globalGain: Float) {
        
        // If number of bands doesn't match, need to perform a mapping
        if bands.count != bandSliders.count {
            
            let mappedBands = bands.count == 10 ? EQMapper.map10BandsTo15Bands(bands, AppConstants.Sound.eq15BandFrequencies) : EQMapper.map15BandsTo10Bands(bands, AppConstants.Sound.eq10BandFrequencies)
            self.updateBands(mappedBands, globalGain)
            return
        }
        
        // Slider tag = index. Default gain value, if bands array doesn't contain gain for index, is 0
        bandSliders.forEach({
            $0.floatValue = $0.tag < bands.count ? bands[$0.tag] : AppDefaults.eqBandGain
        })
        
        globalGainSlider.floatValue = globalGain
    }
    
    func updateBands(_ bands: [Float: Float], _ globalGain: Float) {
        
        var sortedBands: [Float] = []
        let sortedBandsMap = bands.sorted(by: {r1, r2 -> Bool in r1.key < r2.key})
        
        var index = 0
        for (_, gain) in sortedBandsMap {
            
            sortedBands.append(gain)
            index += 1
        }
        
        updateBands(sortedBands, globalGain)
    }
    
    func changeColorScheme() {
        allSliders.forEach({$0.redraw()})
    }
}
