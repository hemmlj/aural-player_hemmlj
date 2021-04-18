import Foundation

class WindowUIState: PersistentState {
    
    var cornerRadius: Float = Float(AppDefaults.windowCornerRadius)
    
    static func deserialize(_ map: NSDictionary) -> WindowUIState {
        
        let state = WindowUIState()
        
        if let cornerRadius = (map["cornerRadius"] as? NSNumber)?.floatValue {
            state.cornerRadius = cornerRadius
        }
        
        return state
    }
}

extension WindowAppearanceState {
    
    static func initialize(_ appState: WindowUIState) {
        cornerRadius = CGFloat(appState.cornerRadius)
    }
    
    static var persistentState: WindowUIState {
        
        let state = WindowUIState()
        state.cornerRadius = Float(cornerRadius)
        
        return state
    }
}