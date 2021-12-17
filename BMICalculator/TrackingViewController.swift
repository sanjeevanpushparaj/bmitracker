//BMI Calculator
//Sanjeevan Pushparaj
//301213104
//2021/12/17

import UIKit
import CoreData

class TrackingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var tableView: UITableView!
    var listOfBMIRecords: [NSManagedObject] = []
    var appContext: NSManagedObjectContext!
    var isFirstime: Bool = true;
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as! AppDelegate;
        appContext = appDelegate.persistentContainer.viewContext;
        
        self.reloadBMIRecords();
        
        tableView.delegate = self;
        tableView.dataSource = self;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if(!self.isFirstime) {
            self.reloadBMIRecords();
        }
        
        self.isFirstime = false;
    }
    //function to reload records
    func reloadBMIRecords() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "BMIRecord");
        
        do {
            listOfBMIRecords = try appContext.fetch(fetchRequest) as! [NSManagedObject];
            tableView.reloadData();
        } catch {
            print("Couldn't fetch the data at now.");
        }
        
        do {
            listOfBMIRecords = try appContext.fetch(fetchRequest) as! [NSManagedObject];
            if(listOfBMIRecords.count > 0) {
                if(tableView.delegate != nil) {
                    tableView.reloadData();
                }
            } else {
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "dataEnterScreen") as! PersonalInfoViewController
                self.navigationController?.pushViewController(vc, animated: true);
            }
        } catch {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "dataEnterScreen") as! PersonalInfoViewController
            self.navigationController?.pushViewController(vc, animated: true);
        }
    }
    
    //function to delete record
    func deleteBMIRecord(index: Int) {
        let uuid = listOfBMIRecords[index].value(forKey: "id") as? UUID;
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "BMIRecord");
        fetchRequest.predicate = NSPredicate(format: "id = %@", uuid!.uuidString);
        
        do {
            let selectedObjects = try appContext.fetch(fetchRequest);
            let objectToDelete = selectedObjects[0] as! NSManagedObject;
            appContext.delete(objectToDelete);
            
            do {
                try appContext.save();
                self.reloadBMIRecords();
            } catch {
                print("Couldn't delete the record.");
            }
        } catch {
            print("Couldn't fetch the record.");
        }
    }
    //add new record
    @IBAction func addNewBMIButtonAction(_ sender: UIButton) {
        let vc = storyboard?.instantiateViewController(identifier: "AddBMIController") as! AddBMIController
        vc.isLessFieldMode = true
        vc.name = listOfBMIRecords[0].value(forKey: "name") as? String ?? "";
        vc.age = listOfBMIRecords[0].value(forKey: "age") as? Int ?? 0;
        vc.gender = listOfBMIRecords[0].value(forKey: "gender") as? String ?? "male";
        vc.view.frame = CGRect(x: 0, y: 0, width: 299, height: 400)
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        vc.dataUpdated = { 
            self.reloadBMIRecords();
        }
        self.present(vc, animated: true, completion: nil)
    }
    //update function
    func updateBMIRecord(index: Int, weight: Double, height: Double) {
        let uuid = listOfBMIRecords[index].value(forKey: "id") as? UUID;
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "BMIRecord");
        fetchRequest.predicate = NSPredicate(format: "id = %@", uuid!.uuidString);
        
        do {
            let selectedObjects = try appContext.fetch(fetchRequest);
            let objectToUpdate = selectedObjects[0] as! NSManagedObject;
            
            // Get height and isMetric
            let isMetric = objectToUpdate.value(forKey: "isMetric") as! Bool;
            
            
            let personalInfoVC = PersonalInfoViewController();
            
            // Recalculate the BMI
            let newBMIValue = personalInfoVC.calculateBMIValue(isMetric: isMetric, weight: weight, height: height);
            let newBMIDescription = personalInfoVC.getBMIDescription(bmiValue: newBMIValue);
            
            // Update the details
            objectToUpdate.setValue(weight, forKey: "weight");
            objectToUpdate.setValue(height, forKey: "height");
            objectToUpdate.setValue(newBMIValue, forKey: "bmiValue");
            objectToUpdate.setValue(newBMIDescription, forKey: "bmiDescription");
            objectToUpdate.setValue(Date(), forKey: "updatedDate");
            
            do {
                try appContext.save();
                self.reloadBMIRecords();
            } catch {
                print("Couldn't update the record.");
            }
        } catch {
            print("Couldn't fetch the record.");
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1; // No sections
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listOfBMIRecords.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableCell = tableView.dequeueReusableCell(withIdentifier: "BMIDetailCell", for: indexPath);
        
        
        let bmiValue = listOfBMIRecords[indexPath.row].value(forKey: "bmiValue") as? Double;
        let bmiDescription = listOfBMIRecords[indexPath.row].value(forKey: "bmiDescription") as? String;
        let isMetric = listOfBMIRecords[indexPath.row].value(forKey: "isMetric") as! Bool;
        let weight = listOfBMIRecords[indexPath.row].value(forKey: "weight") as! Double;
        let updatedDate = listOfBMIRecords[indexPath.row].value(forKey: "updatedDate") as! Date;
        let dateFormatter = DateFormatter();
        dateFormatter.dateFormat = "yyyy-MM-dd";
        
        tableCell.textLabel?.text = "BMI: " + String(format: "%.2f", bmiValue!) + " (" + bmiDescription! + ")";
        tableCell.detailTextLabel?.text = String(format: "%.2f", weight) + (isMetric ? " kg" : " lbs") + "\t(" + dateFormatter.string(from: updatedDate) + ")";
        
        return tableCell;
    }
    //creating table view
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let weight = listOfBMIRecords[indexPath.row].value(forKey: "weight") as! Double;
        let height = listOfBMIRecords[indexPath.row].value(forKey: "height") as! Double;
        let isMetric = listOfBMIRecords[indexPath.row].value(forKey: "isMetric") as! Bool;
        let measureHeight = isMetric ? "(in)" : "(m)"
        let measureWeight = isMetric ? "(kg)" : "(lb)"
        
        let alert = UIAlertController(title: "BMI Calculator", message: "Enter new weight\(measureWeight) and height\(measureHeight)", preferredStyle: .alert)
        alert.addTextField { (textField:UITextField) in
            textField.placeholder = "Enter new weight"
            
            textField.text = String(format: "%.2f ", weight)
            textField.keyboardType = .numberPad
        }
        alert.addTextField { (textField:UITextField) in
            textField.placeholder = "Enter new height"
            textField.text = String(format: "%.2f", height)
            textField.keyboardType = .numberPad
        }
        
        
        alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { (action:UIAlertAction) in
            guard let weightTextField = alert.textFields?.first, let heightTextField = alert.textFields?.last else {
                return
            }
           
            let newWeight = Double(weightTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "0") ?? 0
            let newHeight = Double(heightTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "0") ?? 0
            // Check the the weight value is not empty
            if newWeight > 0 && newHeight > 0 {
                self.updateBMIRecord(index: indexPath.row, weight: newWeight, height: newHeight);
            };
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    //creating delete option
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.deleteBMIRecord(index: indexPath.row);
        }
    }
}
