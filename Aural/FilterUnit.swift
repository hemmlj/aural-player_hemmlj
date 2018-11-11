import AVFoundation

class FilterUnit: FXUnit, FilterUnitProtocol {
    
    private let node: FlexibleFilterNode = FlexibleFilterNode()
    let presets: FilterPresets = FilterPresets()
    
    override var avNodes: [AVAudioNode] {return [node]}
    
    init(_ appState: AudioGraphState) {
        
        let filterState = appState.filterUnitState
        
        super.init(.filter, filterState.unitState)
        
        node.addBands(filterState.bands)
        presets.addPresets(filterState.userPresets)
    }
    
    var bands: [FilterBand] {
        
        get {return node.allBands()}
        set(newValue) {node.setBands(newValue)}
    }
    
    override func stateChanged() {
        
        super.stateChanged()
        node.bypass = !isActive
    }
    
    func getFilterBand(_ index: Int) -> FilterBand {
        return node.getBand(index)
    }
    
    func addFilterBand(_ band: FilterBand) -> Int {
        return node.addBand(band)
    }
    
    func updateFilterBand(_ index: Int, _ band: FilterBand) {
        node.updateBand(index, band)
    }
    
    func removeFilterBands(_ indexSet: IndexSet) {
        node.removeBands(indexSet)
    }
    
    func removeAllFilterBands() {
        node.removeAllBands()
    }
    
    override func savePreset(_ presetName: String) {
        
        // Need to clone the filter's bands to create separate identical copies so that changes to the current filter bands don't modify the preset's bands
        var presetBands: [FilterBand] = []
        bands.forEach({presetBands.append($0.clone())})
        
        presets.addPreset(FilterPreset(presetName, .active, presetBands, false))
    }
    
    override func applyPreset(_ presetName: String) {
        
        if let preset = presets.presetByName(presetName) {
            applyPreset(preset)
        }
    }
    
    func applyPreset(_ preset: FilterPreset) {
        
        state = preset.state
        
        // Need to clone the filter's bands to create separate identical copies so that changes to the current filter bands don't modify the preset's bands
        var filterBands: [FilterBand] = []
        preset.bands.forEach({filterBands.append($0.clone())})
        
        bands = filterBands
    }
    
    func getSettingsAsPreset() -> FilterPreset {
        return FilterPreset("filterSettings", state, bands, false)
    }
    
    func persistentState() -> FilterUnitState {
        
        let filterState = FilterUnitState()
        
        filterState.unitState = state
        filterState.bands = bands
        filterState.userPresets = presets.userDefinedPresets
        
        return filterState
    }
}
