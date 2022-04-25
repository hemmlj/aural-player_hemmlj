import Cocoa
import AVFoundation

class MasterUnitAUTableViewDelegate: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    
    private let audioGraph: AudioGraphDelegateProtocol = ObjectGraph.audioGraphDelegate
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return audioGraph.audioUnits.count
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 24
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {false}
    
    // Returns a view for a single row
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return AudioUnitsTableRowView()
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        switch tableColumn!.identifier {
        
        case .uid_audioUnitSwitch:
            
            return createSwitchCell(tableView, tableColumn!.identifier.rawValue, row)
            
        case .uid_audioUnitName:
            
            return createNameCell(tableView, tableColumn!.identifier.rawValue, row)
            
        default: return nil
            
        }
    }

    private func createSwitchCell(_ tableView: NSTableView, _ id: String, _ row: Int) -> AudioUnitSwitchCellView? {
     
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(id), owner: nil) as? AudioUnitSwitchCellView {
            
            let audioUnit = audioGraph.audioUnits[row]
            
            cell.btnSwitch.stateFunction = audioUnit.stateFunction
            
            cell.btnSwitch.offStateTooltip = "Activate this Audio Unit"
            cell.btnSwitch.onStateTooltip = "Deactivate this Audio Unit"
            
            cell.btnSwitch.updateState()
            
            cell.action = {
                
                _ = audioUnit.toggleState()
                Messenger.publish(.fx_unitStateChanged)
            }
            
            return cell
        }
        
        return nil
    }
    
    private func createNameCell(_ tableView: NSTableView, _ id: String, _ row: Int) -> MasterUnitAUTableNameCellView? {
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(id), owner: nil) as? MasterUnitAUTableNameCellView {
            
            let audioUnit = audioGraph.audioUnits[row]
            
            cell.textField?.stringValue = audioUnit.name
            cell.textField?.font = FontSchemes.systemScheme.effects.unitFunctionFont
            cell.realignText(yOffset: FontSchemes.systemScheme.effects.auRowTextYOffset)

            switch audioUnit.state {
            
            case .active:
                
                cell.textField?.textColor = ColorSchemes.systemScheme.effects.activeUnitStateColor
                
            case .bypassed:
                
                cell.textField?.textColor = ColorSchemes.systemScheme.effects.bypassedUnitStateColor
                
            case .suppressed:
                
                cell.textField?.textColor = ColorSchemes.systemScheme.effects.suppressedUnitStateColor
            }
            
            return cell
        }
        
        return nil
    }
}

class MasterUnitAUTableNameCellView: NSTableCellView {
    
    // Constraints
    func realignText(yOffset: CGFloat) {
        
        guard let textField = self.textField else {return}
        
        // Remove any existing constraints on the text field's 'bottom' attribute
        self.constraints.filter {$0.firstItem === textField && $0.firstAttribute == .bottom}.forEach {self.deactivateAndRemoveConstraint($0)}

        let textFieldBottomConstraint = NSLayoutConstraint(item: textField, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: yOffset)
        
        self.activateAndAddConstraint(textFieldBottomConstraint)
    }
}
