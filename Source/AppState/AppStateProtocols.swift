import Foundation

// Marks an object as having state that needs to be persisted
protocol PersistentModelObject {
    
    associatedtype T: PersistentState
    
    // Retrieves persistent state for this model object
    var persistentState: T {get}
}

// Marks an object as being suitable for persistence, i.e. it is serializable/deserializable
protocol PersistentState {
    
    associatedtype T
    
    // Constructs an instance of this state object from the given map
    static func deserialize(_ map: NSDictionary) -> T
}
