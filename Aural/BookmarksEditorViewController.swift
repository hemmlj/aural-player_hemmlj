import Cocoa

class BookmarksEditorViewController: NSViewController, NSTableViewDataSource,  NSTableViewDelegate, NSTextFieldDelegate {

    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var editorView: NSTableView!
    @IBOutlet weak var editorViewHeader: NSTableHeaderView!
    
    @IBOutlet weak var btnDelete: NSButton!
    @IBOutlet weak var btnPlay: NSButton!
    @IBOutlet weak var btnRename: NSButton!
    
    // Delegate that relays accessor operations to the bookmarks model
    private let bookmarks: BookmarksDelegateProtocol = ObjectGraph.getBookmarksDelegate()
    
    override var nibName: String? {return "BookmarksEditor"}
    
    override func viewDidLoad() {
        
        headerHeight()
        editorView.headerView?.wantsLayer = true
        editorView.headerView?.layer?.backgroundColor = NSColor.black.cgColor
        
        editorView.tableColumns.forEach({
            
            let col = $0
            let header = AuralTableHeaderCell()
            
            header.stringValue = col.headerCell.stringValue
            header.isBordered = false
            
            col.headerCell = header
        })
    }
    
    private func headerHeight() {
        
        scrollView.subviews.forEach({
        
            let subView = $0
            subView.subviews.forEach({
            
                let subSubView = $0
                
                if subView.className == "NSClipView" && subSubView.className == "NSTableHeaderView" {
                    
                    subSubView.setFrameSize(NSMakeSize(subSubView.frame.size.width, subSubView.frame.size.height + 10))
                    subView.setFrameSize(NSMakeSize(subView.frame.size.width, subView.frame.size.height + 10))
                }
            })
            
            if subView.className == "NSCornerView" {
                subView.setFrameSize(NSMakeSize(subView.frame.size.width, subView.frame.size.height + 10))
            }
        })
    }
    
    override func viewDidAppear() {
        
        editorView.reloadData()
        editorView.deselectAll(self)
        
        [btnDelete, btnPlay, btnRename].forEach({$0.isEnabled = false})
    }
    
    @IBAction func deleteSelectedBookmarksAction(_ sender: AnyObject) {
        
        // Descending order
        let sortedSelection = editorView.selectedRowIndexes.sorted(by: {x, y -> Bool in x > y})
        
        sortedSelection.forEach({
            bookmarks.deleteBookmarkAtIndex($0)
        })
        
        editorView.reloadData()
        editorView.deselectAll(self)
        updateButtonStates()
    }
    
    @IBAction func playSelectedBookmarkAction(_ sender: AnyObject) {
        
        if editorView.selectedRowIndexes.count == 1 {
            bookmarks.playBookmark(bookmarks.getBookmarkAtIndex(editorView.selectedRow))
        }
    }
    
    @IBAction func renameBookmarkAction(_ sender: AnyObject) {
        
        let rowIndex = editorView.selectedRow
        let rowView = editorView.rowView(atRow: rowIndex, makeIfNecessary: true)
        let editedTextField = (rowView?.view(atColumn: 0) as! NSTableCellView).textField!
        
        self.view.window?.makeFirstResponder(editedTextField)
    }
    
    @IBAction func doneAction(_ sender: AnyObject) {
        
        WindowState.showingPopover = false
        UIUtils.dismissModalDialog()
    }
    
    // MARK: View delegate functions
    
    // Returns the total number of playlist rows
    func numberOfRows(in tableView: NSTableView) -> Int {
        return bookmarks.countBookmarks()
    }
    
    // Enables type selection, allowing the user to conveniently and efficiently find a playlist track by typing its display name, which results in the track, if found, being selected within the playlist
    func tableView(_ tableView: NSTableView, typeSelectStringFor tableColumn: NSTableColumn?, row: Int) -> String? {
        
        // Only the bookmark name column is used for type selection
        if (tableColumn?.identifier != UIConstants.bookmarkNameColumnID) {
            return nil
        }
        
        return bookmarks.getBookmarkAtIndex(row).name
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        updateButtonStates()
    }
    
    private func updateButtonStates() {
        
        let selRows: Int = editorView.selectedRowIndexes.count
        
        btnDelete.isEnabled = selRows > 0
        [btnPlay, btnRename].forEach({$0.isEnabled = selRows == 1})
    }
    
    // Returns a view for a single row
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return AuralTableRowView()
    }
    
    // Returns a view for a single column
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let bookmark = bookmarks.getBookmarkAtIndex(row)
        
        switch tableColumn!.identifier {
            
        case UIConstants.bookmarkNameColumnID:
            
            return createTextCell(tableView, tableColumn!, row, bookmark.name, true)
            
        case UIConstants.bookmarkTrackColumnID:
            
            return createTextCell(tableView, tableColumn!, row, bookmark.file.path, false)
            
        case UIConstants.bookmarkPositionColumnID:
            
            let formattedPosition = StringUtils.formatSecondsToHMS(bookmark.position)
            return createTextCell(tableView, tableColumn!, row, formattedPosition, false)
            
        default:    return nil
            
        }
    }
    
    // Creates a cell view containing text
    private func createTextCell(_ tableView: NSTableView, _ column: NSTableColumn, _ row: Int, _ text: String, _ editable: Bool) -> EditorTableCellView? {
        
        if let cell = tableView.make(withIdentifier: column.identifier, owner: nil) as? EditorTableCellView {
            
            cell.isSelectedFunction = {
                
                (row: Int) -> Bool in
                
                return self.editorView.selectedRowIndexes.contains(row)
            }
            
            cell.textField?.stringValue = text
            cell.textField?.textColor = Colors.playlistTextColor
            cell.row = row
            
            // Set tool tip on name/track only if text wider than column width
            let font = cell.textField!.font!
            if StringUtils.numberOfLines(text, font, column.width) > 1 {
                cell.toolTip = text
            }
            
            // Name column is editable
            if editable {
                cell.textField?.delegate = self
            }
            
            return cell
        }
        
        return nil
    }
    
    func tableViewColumnDidResize(_ notification: Notification) {
     
        // Update tool tips as some may no longer be needed or some new ones may be needed
        
        if let column = notification.userInfo?["NSTableColumn"] as? NSTableColumn {
        
            let count = bookmarks.countBookmarks()
            if count > 0 {
                
                for index in 0..<count {
                    
                    let cell = tableView(editorView, viewFor: column, row: index) as! NSTableCellView
                    
                    let text = cell.textField!.stringValue
                    let font = cell.textField!.font!
                    
                    if StringUtils.numberOfLines(text, font, column.width) > 1 {
                        cell.toolTip = text
                    } else {
                        cell.toolTip = nil
                    }
                }
            }
        }
    }
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        
        let rowIndex = editorView.selectedRow
        let rowView = editorView.rowView(atRow: rowIndex, makeIfNecessary: true)
        let cell = rowView?.view(atColumn: 0) as! NSTableCellView
        let editedTextField = cell.textField!
        
        let bookmark = bookmarks.getBookmarkAtIndex(rowIndex)
        let newBookmarkName = editedTextField.stringValue
        
        editedTextField.textColor = Colors.playlistSelectedTextColor
        
        // TODO: What if the string is too long ?
        
        // Empty string is invalid, revert to old value
        if (StringUtils.isStringEmpty(newBookmarkName)) {
            editedTextField.stringValue = bookmark.name
            
        } else {
            
            // Update the bookmark name
            bookmark.name = newBookmarkName
        }
        
        // Update the tool tip

        let font = cell.textField!.font!
        let nameColumn = editorView.tableColumns[0]
        
        if StringUtils.numberOfLines(newBookmarkName, font, nameColumn.width) > 1 {
            cell.toolTip = newBookmarkName
        } else {
            cell.toolTip = nil
        }
    }
}
