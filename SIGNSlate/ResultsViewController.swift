//
//  ResultsViewController.swift
//  SIGNSlate
//
//  Created by Stephanie Joubert on 24/09/2022.
//

import UIKit

class ResultsViewController: UIViewController {
    
//    var totArray = LatingViewController().arrOfWords
    @IBOutlet weak var orderedTranslation: UILabel!
    @IBOutlet weak var directTranslation: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        totArray = LatingViewController().arrOfWords1
//        directTranslation.text = totArray.joined(separator: " ")
        self.directTranslation.text = "one two thee"
//        LatingViewController().arrOfWords1.joined(separator: " ")
        print("heyo", LatingViewController().arrOfWords1.joined(separator: " "))
        
        
    
     

        // Do any additional setup after loading the view.
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
