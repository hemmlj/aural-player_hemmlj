import Foundation

// Intended to be used as a callback interface for clients of StringInputPopover
protocol StringInputClient {
    
    // Asks the client to validate the given string input. Returns true if the input string is valid, false otherwise. Optional errorMsg return value describes the validation error if there is one.
    func validate(_ string: String) -> (valid: Bool, errorMsg: String?)
    
    // Tells the client to accept the given (validated) string received from the user
    func acceptInput(_ string: String)
    
    // Returns a message that is used when prompting the user for string input, describing the information being requested. e.g. "Please enter the preset name:"
    var inputPrompt: String {get}
    
    // Returns an appropriate (optional) default value for the information being requested. e.g. "New preset"
    var defaultValue: String? {get}
    
    var inputFontSize: TextSizeScheme {get}
}
