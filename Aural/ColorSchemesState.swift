import Cocoa

class ColorSchemesState {
    
    var userSchemes: [ColorSchemeState] = []
    var systemScheme: ColorSchemeState
    
    convenience init() {
        self.init(ColorSchemeState(), [])
    }
    
    init(_ systemScheme: ColorSchemeState, _ userSchemes: [ColorSchemeState]) {
        
        self.systemScheme = systemScheme
        self.userSchemes = userSchemes
    }
}

class ColorSchemeState {
    
    var general: GeneralColorSchemeState
    var player: PlayerColorSchemeState
    var playlist: PlaylistColorSchemeState
    var effects: EffectsColorSchemeState
    
    convenience init() {
        self.init(ColorSchemes.systemScheme)
    }
    
    init(_ scheme: ColorScheme) {
        
        self.general = GeneralColorSchemeState(scheme.general)
        self.player = PlayerColorSchemeState(scheme.player)
        self.playlist = PlaylistColorSchemeState(scheme.playlist)
        self.effects = EffectsColorSchemeState(scheme.effects)
    }
}

class GeneralColorSchemeState {
    
    var appLogoColor: ColorState
    var backgroundColor: ColorState
    
    var viewControlButtonColor: ColorState
    var functionButtonColor: ColorState
    var toggleButtonOffStateColor: ColorState
    var selectedTabButtonColor: ColorState
    
    var mainCaptionTextColor: ColorState
    var tabButtonTextColor: ColorState
    var selectedTabButtonTextColor: ColorState
    var functionButtonTextColor: ColorState
    
    init(_ scheme: GeneralColorScheme) {
        
        self.appLogoColor = ColorState.fromColor(scheme.appLogoColor)
        self.backgroundColor = ColorState.fromColor(scheme.backgroundColor)
        
        self.viewControlButtonColor = ColorState.fromColor(scheme.viewControlButtonColor)
        self.functionButtonColor = ColorState.fromColor(scheme.functionButtonColor)
        self.toggleButtonOffStateColor = ColorState.fromColor(scheme.toggleButtonOffStateColor)
        self.selectedTabButtonColor = ColorState.fromColor(scheme.selectedTabButtonColor)
        
        self.mainCaptionTextColor = ColorState.fromColor(scheme.mainCaptionTextColor)
        self.tabButtonTextColor = ColorState.fromColor(scheme.tabButtonTextColor)
        self.selectedTabButtonTextColor = ColorState.fromColor(scheme.selectedTabButtonTextColor)
        self.functionButtonTextColor = ColorState.fromColor(scheme.functionButtonTextColor)
    }
}

class PlayerColorSchemeState {
    
    var trackInfoPrimaryTextColor: ColorState
    var trackInfoSecondaryTextColor: ColorState
    var trackInfoTertiaryTextColor: ColorState
    var sliderValueTextColor: ColorState
    
    var sliderForegroundColor: ColorState
    var sliderBackgroundColor: ColorState
    var sliderKnobColor: ColorState
    var sliderLoopSegmentColor: ColorState
    
    init(_ scheme: PlayerColorScheme) {
        
        self.trackInfoPrimaryTextColor = ColorState.fromColor(scheme.trackInfoPrimaryTextColor)
        self.trackInfoSecondaryTextColor = ColorState.fromColor(scheme.trackInfoSecondaryTextColor)
        self.trackInfoTertiaryTextColor = ColorState.fromColor(scheme.trackInfoTertiaryTextColor)
        self.sliderValueTextColor = ColorState.fromColor(scheme.sliderValueTextColor)
        
        self.sliderBackgroundColor = ColorState.fromColor(scheme.sliderBackgroundColor)
        self.sliderForegroundColor = ColorState.fromColor(scheme.sliderForegroundColor)
        self.sliderKnobColor = ColorState.fromColor(scheme.sliderKnobColor)
        self.sliderLoopSegmentColor = ColorState.fromColor(scheme.sliderLoopSegmentColor)
    }
}

class PlaylistColorSchemeState {
    
    var trackNameTextColor: ColorState
    var groupNameTextColor: ColorState
    var indexDurationTextColor: ColorState
    
    var trackNameSelectedTextColor: ColorState
    var groupNameSelectedTextColor: ColorState
    var indexDurationSelectedTextColor: ColorState
    
    var summaryInfoColor: ColorState
    
    var playingTrackIconColor: ColorState
    var selectionBoxColor: ColorState
    
    var groupIconColor: ColorState
    var groupDisclosureTriangleColor: ColorState
    
    init(_ scheme: PlaylistColorScheme) {
        
        self.trackNameTextColor = ColorState.fromColor(scheme.trackNameTextColor)
        self.groupNameTextColor = ColorState.fromColor(scheme.groupNameTextColor)
        self.indexDurationTextColor = ColorState.fromColor(scheme.indexDurationTextColor)
        
        self.trackNameSelectedTextColor = ColorState.fromColor(scheme.trackNameSelectedTextColor)
        self.groupNameSelectedTextColor = ColorState.fromColor(scheme.groupNameSelectedTextColor)
        self.indexDurationSelectedTextColor = ColorState.fromColor(scheme.indexDurationSelectedTextColor)
        
        self.groupIconColor = ColorState.fromColor(scheme.groupIconColor)
        self.groupDisclosureTriangleColor = ColorState.fromColor(scheme.groupDisclosureTriangleColor)
        self.selectionBoxColor = ColorState.fromColor(scheme.selectionBoxColor)
        self.playingTrackIconColor = ColorState.fromColor(scheme.playingTrackIconColor)
        self.summaryInfoColor = ColorState.fromColor(scheme.summaryInfoColor)
    }
}

class EffectsColorSchemeState {
    
    var functionCaptionTextColor: ColorState
    var functionValueTextColor: ColorState
    
    var sliderBackgroundColor: ColorState
    
    var activeUnitStateColor: ColorState
    var bypassedUnitStateColor: ColorState
    var suppressedUnitStateColor: ColorState
    
    init(_ scheme: EffectsColorScheme) {
     
        self.functionCaptionTextColor = ColorState.fromColor(scheme.functionCaptionTextColor)
        self.functionValueTextColor = ColorState.fromColor(scheme.functionValueTextColor)
        
        self.sliderBackgroundColor = ColorState.fromColor(scheme.sliderBackgroundColor)
        
        self.activeUnitStateColor = ColorState.fromColor(scheme.activeUnitStateColor)
        self.bypassedUnitStateColor = ColorState.fromColor(scheme.bypassedUnitStateColor)
        self.suppressedUnitStateColor = ColorState.fromColor(scheme.suppressedUnitStateColor)
    }
}
