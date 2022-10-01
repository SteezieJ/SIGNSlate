//
//  ResultsViewController.swift
//  SIGNSlate
//
//  Created by Stephanie Joubert on 01/10/2022.
//

import UIKit


class ResultsViewController: UIViewController {
    var textarr: String = ""
    @IBOutlet weak var Expressions: UILabel!
    @IBOutlet weak var HandSigns: UILabel!
    @IBOutlet weak var Combined: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        HandSigns.text = "words"

        // Do any additional setup after loading the view.
    }
    



    
}


extension ResultsViewController: SendResultsDelegate {
    func SendHandResults(WordsArray: Array<String>) {
//        DispatchQueue.main.async {
//            self.HandSigns.text = "one two three"
//        }
        textarr = WordsArray.joined(separator: " ")
        print("array",textarr)
//        textarr = self.SendHandResults(WordsArray: Array<String>)
        
        
//        self.displayText.text = self.arrOfWords.joined(separator: " ")
//        self.HandSigns.text = "one two three"
        
    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        HandSigns.text = textarr
//
//        // Do any additional setup after loading the view.
//    }
    
}
