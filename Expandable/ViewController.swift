//
//  ViewController.swift
//  Expandable
//
//  Created by Gabriel Theodoropoulos on 28/10/15.
//  Copyright © 2015 Appcoda. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // this array will contain all the cell description dictionaries that will be loaded from the property list file.
    var cellDescriptors: NSMutableArray!
    
    // this 2-dimensional array will store the visible cells for each section
    var visibleRowsPerSection = [[Int]]()
    
    // MARK: IBOutlet Properties
    
    @IBOutlet weak var tblExpandable: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        configureTableView()
    
        // calling loadCellDescriptors will be exectued just before the view loads BUT after the table has been configured.
        // we dont want to load the table before it is configured!
        loadCellDescriptors()
        print(cellDescriptors)
    
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: Tutorial Functions
    
    // this function is responsible for loading the file contents into the array
    func loadCellDescriptors() {
    // we first make sure that the path to the property lists is valid, and then we initialize the cellDescriptors array by loading the file contents.
        if let path = NSBundle.mainBundle().pathForResource("CellDescriptor", ofType: "plist") {
            cellDescriptors = NSMutableArray(contentsOfFile: path)
            // the getIndiciesOfVisibleRows func needs to first be called after the cellDescriptors have been loaded
            getIndiciesOfVisibleRows()
            tblExpandable.reloadData()
        }
    }
    
    // this function provides the row index values for the cells that have been designated as visible only.  A normal implementation of cellForRowAtIndexPath will not work in this situation because we have cells designated as visible and not visible.
    func getIndiciesOfVisibleRows() {
        visibleRowsPerSection.removeAll()
        
        for currentSectionCells in cellDescriptors {
            var visibleRows = [Int]()
            
            for row in 0...((currentSectionCells as! [[String: AnyObject]]).count - 1) {
                if currentSectionCells[row]["isVisible"] as! Bool == true {
                    visibleRows.append(row)
                }
            }
            
            visibleRowsPerSection.append(visibleRows)
        }
    }
    
    // this function locates and returns the cell description from the cellDescriptors array (the visibleRowsPerSection func is a pre-req for this function)
    // this function accepts the index path of the cell this is being processed by the TBview as a parameter and returns the properties of that cell
    func getCellDescriptorForIndexPath(indexPath: NSIndexPath) -> [String: AnyObject] {
        // the first step is to find the index of the visible row
        let indexOfVisibleRow = visibleRowsPerSection[indexPath.section][indexPath.row]
        // next, since we have the index of the row for each cell, we can cast the cell description from the cellDescriptors array to the indexOfVisibleRow aray.
        let cellDescriptor = cellDescriptors[indexPath.section][indexOfVisibleRow] as! [String: AnyObject]
        return cellDescriptor
    }
    
    // MARK: Custom Functions
    
    func configureTableView() {
        tblExpandable.delegate = self
        tblExpandable.dataSource = self
        tblExpandable.tableFooterView = UIView(frame: CGRectZero)
        
        tblExpandable.registerNib(UINib(nibName: "NormalCell", bundle: nil), forCellReuseIdentifier: "idCellNormal")
        tblExpandable.registerNib(UINib(nibName: "TextfieldCell", bundle: nil), forCellReuseIdentifier: "idCellTextfield")
        tblExpandable.registerNib(UINib(nibName: "DatePickerCell", bundle: nil), forCellReuseIdentifier: "idCellDatePicker")
        tblExpandable.registerNib(UINib(nibName: "SwitchCell", bundle: nil), forCellReuseIdentifier: "idCellSwitch")
        tblExpandable.registerNib(UINib(nibName: "ValuePickerCell", bundle: nil), forCellReuseIdentifier: "idCellValuePicker")
        tblExpandable.registerNib(UINib(nibName: "SliderCell", bundle: nil), forCellReuseIdentifier: "idCellSlider")
    }

    
    // MARK: UITableView Delegate and Datasource Functions
    
    //this function fixes the existing TBview method to specify the number of sections in the TBView
    // NOTE - we have to handle if the cellDesciptors is nil
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if cellDescriptors != nil {
            return cellDescriptors.count
        }
        else {
            return 0
        }
    }
    
    // the number of rows per section is always equal to the number of visible cells
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visibleRowsPerSection[section].count
    }
    
    // this function determines the titles for the sections
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Personal"
            
        case 1:
            return "Preferences"
            
        default:
            return "Work Experience"
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let currentCellDescriptor = getCellDescriptorForIndexPath(indexPath)
        let cell = tableView.dequeueReusableCellWithIdentifier(currentCellDescriptor["cellIdentifier"] as! String, forIndexPath: indexPath) as! CustomCell
        
        // normal cells are the cells with idCellNormal identifier and are the top-level cells with are expanded and collapsed 
        // normal cells are set with the primaryTitle & secondaryTitle text values
        if currentCellDescriptor["cellIdentifier"] as! String == "idCellNormal" {
            if let primaryTitle = currentCellDescriptor["primaryTitle"] {
                cell.textLabel?.text = primaryTitle as? String
            }
            
            if let secondaryTitle = currentCellDescriptor["secondaryTitle"] {
                cell.detailTextLabel?.text = secondaryTitle as? String
            }
        }
        // for cells containing a textfield, we set the placeholder value to the primaryTitle property of the cell descriptor
        else if currentCellDescriptor["cellIdentifier"] as! String == "idCellTextfield" {
            cell.textField.placeholder = currentCellDescriptor["primaryTitle"] as? String
        }
        // switch control cells- first we specifiy the displayed text before the switch & second we set the switch to the proper state (on or off)
        else if currentCellDescriptor["cellIdentifier"] as! String == "idCellSwitch" {
            cell.lblSwitchLabel.text = currentCellDescriptor["primaryTitle"] as? String
            
            let value = currentCellDescriptor["value"] as? String
            cell.swMaritalStatus.on = (value == "true") ? true : false
        }
        // cells with a picker - provide a list of options and when an option has been selected, the cell will collapse and the value will be displayed in the text label
        else if currentCellDescriptor["cellIdentifier"] as! String == "idCellValuePicker" {
            cell.textLabel?.text = currentCellDescriptor["primaryTitle"] as? String
        }
        // cells with a slider - first we grab the current value from the currentCellDescriptor dictionary and convert it to a float. We assign the float to the slider control
        else if currentCellDescriptor["cellIdentifier"] as! String == "idCellSlider" {
            let value = currentCellDescriptor["value"] as! String
            cell.slExperienceLevel.value = (value as NSString).floatValue
        }
        
        return cell
    }
    
    // this function determines the cell height based on the respective xib files
    // this is the first use of the getCellDescriptorForIndexPath method declared earlier.
    // first we need to get the proper cell descriptor, next we need the "cellIdentifier" property which will determine the cell row height.
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let currentCellDescriptor = getCellDescriptorForIndexPath(indexPath)
        
        switch currentCellDescriptor["cellIdentifier"] as! String {
        case "idCellNormal":
            return 60.0
            
        case "idCellDatePicker":
            return 270.0
            
        default:
            return 44.0
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // first we need to get the actual index of the tapped row, seen below
        let indexOfTappedRow = visibleRowsPerSection[indexPath.section][indexPath.row]
        
        // then we need to check the cellDescriptors array to see if the selected cell is expandable or not.
        if cellDescriptors[indexPath.section][indexOfTappedRow]["isExpandable"] as! Bool == true {
            var shouldExpandAndShowSubRows = false
            if cellDescriptors[indexPath.section][indexOfTappedRow]["isExpanded"] as! Bool == false {
                // In this case the cell should expand.
                shouldExpandAndShowSubRows = true
            }
        
            cellDescriptors[indexPath.section][indexOfTappedRow].setValue(shouldExpandAndShowSubRows, forKey: "isExpanded")
            
            for i in (indexOfTappedRow + 1)...(indexOfTappedRow + (cellDescriptors[indexPath.section][indexOfTappedRow]["additionalRows"] as! Int)) {
                cellDescriptors[indexPath.section][i].setValue(shouldExpandAndShowSubRows, forKey: "isVisible")
            }
        
        }   else {
            //We’ll find the row index of the top-level cell that is supposed to be the “parent” cell of the tapped one. In truth, we’ll perform a search towards the beginning of the cell descriptors and the first top-level cell that is spotted (the first cell that is expandable) is the one we want.
                if cellDescriptors[indexPath.section][indexOfTappedRow]["cellIdentifier"] as! String == "idCellValuePicker" {
         
                var indexOfParentCell: Int!
                
                for var i=indexOfTappedRow - 1; i>=0; --i {
                    if cellDescriptors[indexPath.section][i]["isExpandable"] as! Bool == true {
                        indexOfParentCell = i
                        break
                    }
                }
                // We’ll set the displayed value of the selected cell as the text of the textLabel label of the top-level cell.
                // We’ll mark the top-level cell as not expanded.
                cellDescriptors[indexPath.section][indexOfParentCell].setValue((tblExpandable.cellForRowAtIndexPath(indexPath) as! CustomCell).textLabel?.text, forKey: "primaryTitle")
                cellDescriptors[indexPath.section][indexOfParentCell].setValue(false, forKey: "isExpanded")
                    
                // We’ll mark all the sub-cells of the found top-level one as not visible.
                for i in (indexOfParentCell + 1)...(indexOfParentCell + (cellDescriptors[indexPath.section][indexOfParentCell]["additionalRows"] as! Int)) {
                    cellDescriptors[indexPath.section][i].setValue(false, forKey: "isVisible")
                    }
            
                }
            
        }
        
        getIndiciesOfVisibleRows()
        tblExpandable.reloadSections(NSIndexSet(index: indexPath.section), withRowAnimation: UITableViewRowAnimation.Fade)
        
    }




}











