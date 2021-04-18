import Foundation

class WindowLayoutState: PersistentState {
    
    var showEffects: Bool = true
    var showPlaylist: Bool = true
    
    var mainWindowOrigin: NSPoint = NSPoint.zero
    var effectsWindowOrigin: NSPoint? = nil
    var playlistWindowFrame: NSRect? = nil
    
    var userLayouts: [WindowLayout] = [WindowLayout]()
    
    static func deserialize(_ map: NSDictionary) -> WindowLayoutState {
        
        let state = WindowLayoutState()
        
        state.showPlaylist = mapDirectly(map, "showPlaylist", true)
        state.showEffects = mapDirectly(map, "showEffects", true)
        
        if let mainWindowOriginDict = map["mainWindowOrigin"] as? NSDictionary, let origin = mapNSPoint(mainWindowOriginDict) {
            state.mainWindowOrigin = origin
        }
        
        if let effectsWindowOriginDict = map["effectsWindowOrigin"] as? NSDictionary, let origin = mapNSPoint(effectsWindowOriginDict) {
            state.effectsWindowOrigin = origin
        }
        
        if let frameDict = map["playlistWindowFrame"] as? NSDictionary, let originDict = frameDict["origin"] as? NSDictionary, let origin = mapNSPoint(originDict), let sizeDict = frameDict["size"] as? NSDictionary, let size = mapNSSize(sizeDict) {
            
            state.playlistWindowFrame = NSRect(origin: origin, size: size)
        }
        
        if let userLayouts = map["userLayouts"] as? [NSDictionary] {
            
            for layout in userLayouts {
                
                if let layoutName = layout["name"] as? String {
                    
                    let layoutShowEffects: Bool? = mapDirectly(layout, "showEffects")
                    let layoutShowPlaylist: Bool? = mapDirectly(layout, "showPlaylist")
                    
                    var layoutMainWindowOrigin: NSPoint?
                    var layoutEffectsWindowOrigin: NSPoint?
                    var layoutPlaylistWindowFrame: NSRect?
                    
                    if let mainWindowOriginDict = layout["mainWindowOrigin"] as? NSDictionary, let origin = mapNSPoint(mainWindowOriginDict) {
                        layoutMainWindowOrigin = origin
                    }
                    
                    if let effectsWindowOriginDict = layout["effectsWindowOrigin"] as? NSDictionary, let origin = mapNSPoint(effectsWindowOriginDict) {
                        layoutEffectsWindowOrigin = origin
                    }
                    
                    if let frameDict = layout["playlistWindowFrame"] as? NSDictionary, let originDict = frameDict["origin"] as? NSDictionary, let origin = mapNSPoint(originDict), let sizeDict = frameDict["size"] as? NSDictionary, let size = mapNSSize(sizeDict) {
                        
                        layoutPlaylistWindowFrame = NSRect(origin: origin, size: size)
                    }
                    
                    // Make sure you have all the required info
                    if layoutShowEffects != nil && layoutShowPlaylist != nil && layoutMainWindowOrigin != nil {
                        
                        if ((layoutShowEffects! && layoutEffectsWindowOrigin != nil) || !layoutShowEffects!) {
                            
                            if ((layoutShowPlaylist! && layoutPlaylistWindowFrame != nil) || !layoutShowPlaylist!) {
                                
                                let newLayout = WindowLayout(layoutName, layoutShowEffects!, layoutShowPlaylist!, layoutMainWindowOrigin!, layoutEffectsWindowOrigin, layoutPlaylistWindowFrame, false)
                                
                                state.userLayouts.append(newLayout)
                            }
                        }
                    }
                }
            }
        }
        
        return state
    }
}

fileprivate func mapNSPoint(_ map: NSDictionary) -> NSPoint? {
    
    if let px = map["x"] as? NSNumber, let py = map["y"] as? NSNumber {
        return NSPoint(x: CGFloat(px.floatValue), y: CGFloat(py.floatValue))
    }
    
    return nil
}

fileprivate func mapNSSize(_ map: NSDictionary) -> NSSize? {
    
    if let wd = map["width"] as? NSNumber, let ht = map["height"] as? NSNumber {
        return NSSize(width: CGFloat(wd.floatValue), height: CGFloat(ht.floatValue))
    }
    
    return nil
}