//
//  ResultsViewController.swift
//  SIGNSlate
//
//  Created by Stephanie Joubert on 01/10/2022.
//

import UIKit


class ResultsViewController: UIViewController {
    public var textstring: String? // = "none"
//    public var textstring: String = "none"

    @IBOutlet weak var Expressions: UILabel!
  //  @IBOutlet weak var HandSigns: UILabel!
    @IBOutlet weak var Combined: UILabel!
    
    var passedArrOfHandsigns:[String]?
    var passedArrOfFacesigns:[String]?
    var passedArrOfCombinedSigns:[CombineModel]?
    var phraseBook:[String:String]!
    override func viewDidLoad() {
        super.viewDidLoad()
        //setupNavigationAppearance()
        phraseBook = getJSON()
        Combined.text = passedArrOfCombinedSigns?.map { phraseBook.keys.contains($0.handPose!+"+"+$0.facePose!) ? phraseBook[$0.handPose!+"+"+$0.facePose!]! : "" }.joined(separator: "\n") //passedArrOfFacesigns?.joined(separator: "\n")
      //  HandSigns.text = passedArrOfHandsigns?.joined(separator: "\n")
        Expressions.text = passedArrOfCombinedSigns?.map { "\($0.handPose!)(\($0.facePose!))" }.joined(separator: "\n")
    }
    func setupNavigationAppearance() {
        let appearance = UINavigationBarAppearance()
          appearance.backgroundColor = .clear
        self.navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }


    //MARK: -  Utilities
    func getJSON() -> [String:String] {
        guard let url = Bundle.main.url(forResource: "phraseBook", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decodedData = try? JSONDecoder().decode([String:String].self, from: data) else {
            return [String:String]()
        }
        return decodedData
    }
    
}


extension ResultsViewController: SendResultsDelegate {
    func SendHandResults(text WordsArray: String?) {

        textstring = WordsArray
//        textstring = WordsArray.joined(separator: " ")
        print("array", textstring!)
//        textarr = self.SendHandResults(WordsArray: Array<String>)
        print("array2", WordsArray ?? "none")

//        self.displayText.text = self.arrOfWords.joined(separator: " ")
//        self.HandSigns.text = textstring

    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        HandSigns.text = textarr
//
//        // Do any additional setup after loading the view.
//    }

    
}
