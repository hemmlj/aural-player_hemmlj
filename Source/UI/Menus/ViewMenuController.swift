import Cocoa

/*
    Provides actions for the View menu that alters the layout of the app's windows and views.
 
    NOTE - No actions are directly handled by this class. Command notifications are published to another app component that is responsible for these functions.
 */
class ViewMenuController: NSObject, NSMenuDelegate {
    
    // Menu items whose states are toggled when they (or others) are clicked
    @IBOutlet weak var togglePlaylistMenuItem: NSMenuItem!
    @IBOutlet weak var toggleEffectsMenuItem: NSMenuItem!
    @IBOutlet weak var toggleChaptersListMenuItem: NSMenuItem!
    @IBOutlet weak var toggleVisualizerMenuItem: NSMenuItem!
    
    @IBOutlet weak var playerViewMenuItem: NSMenuItem!
    
    @IBOutlet weak var applyFontSchemeMenuItem: NSMenuItem!
    @IBOutlet weak var saveFontSchemeMenuItem: NSMenuItem!
    @IBOutlet weak var manageFontSchemesMenuItem: NSMenuItem!
    
    @IBOutlet weak var applyColorSchemeMenuItem: NSMenuItem!
    @IBOutlet weak var saveColorSchemeMenuItem: NSMenuItem!
    @IBOutlet weak var manageColorSchemesMenuItem: NSMenuItem!
    
    @IBOutlet weak var manageLayoutsMenuItem: NSMenuItem!
    
    private let viewAppState = ObjectGraph.appState.ui.player
    
    private let player: PlaybackInfoDelegateProtocol = ObjectGraph.playbackInfoDelegate
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        
        manageLayoutsMenuItem.enableIf(!WindowLayouts.userDefinedLayouts.isEmpty)
        toggleChaptersListMenuItem.enableIf(player.chapterCount > 0)
        
        let showingModalComponent: Bool = WindowManager.isShowingModalComponent
        
        [applyFontSchemeMenuItem, saveFontSchemeMenuItem].forEach({$0.enableIf(!showingModalComponent)})
        manageFontSchemesMenuItem.enableIf(!showingModalComponent && (FontSchemes.numberOfUserDefinedSchemes > 0))
        
        [applyColorSchemeMenuItem, saveColorSchemeMenuItem].forEach({$0.enableIf(!showingModalComponent)})
        manageColorSchemesMenuItem.enableIf(!showingModalComponent && (ColorSchemes.numberOfUserDefinedSchemes > 0))
    }
    
    // When the menu is about to open, set the menu item states according to the current window/view state
    func menuWillOpen(_ menu: NSMenu) {
        
        [togglePlaylistMenuItem, toggleEffectsMenuItem].forEach({$0?.show()})
        
        togglePlaylistMenuItem.onIf(WindowManager.isShowingPlaylist)
        toggleEffectsMenuItem.onIf(WindowManager.isShowingEffects)
        toggleChaptersListMenuItem.onIf(WindowManager.isShowingChaptersList)
        toggleVisualizerMenuItem.onIf(WindowManager.isShowingVisualizer)
        
        playerViewMenuItem.off()
    }
 
    // Shows/hides the playlist window
    @IBAction func togglePlaylistAction(_ sender: AnyObject) {
        Messenger.publish(.windowManager_togglePlaylistWindow)
    }
    
    // Shows/hides the effects window
    @IBAction func toggleEffectsAction(_ sender: AnyObject) {
        Messenger.publish(.windowManager_toggleEffectsWindow)
    }
    
    // Shows/hides the chapters list window
    @IBAction func toggleChaptersListAction(_ sender: AnyObject) {
        WindowManager.toggleChaptersList()
    }
    
    @IBAction func toggleVisualizerAction(_ sender: AnyObject) {
        WindowManager.toggleVisualizer()
    }
    
    // TODO: Revisit this
    @IBAction func alwaysOnTopAction(_ sender: NSMenuItem) {
//        WindowManager.toggleAlwaysOnTop()
    }
}
