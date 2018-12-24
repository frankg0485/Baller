//
//  GameOverViewController.swift
//  Baller
//
//  Created by Frank Gao on 7/2/18.
//  Copyright © 2018 Frank Gao. All rights reserved
//

import UIKit

class GameOverViewController: UIViewController {
    @IBOutlet weak var gameOverLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var highScoreLabel: UILabel!
    @IBOutlet weak var restartButton: UIButton!

    //These are set in GridView.swift, when about to present this view controller
    var highScore = 0
    var score = 0
    var FONT_H: Double = 0

    var delegate: ModalHandler?

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpText()
        //fadeIn() is called upon completion of presenting this view controller
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func restartClicked(_ sender: UIButton) {
        self.delegate?.modalDismissed()
        dismiss(animated: true, completion: nil)
    }

    func setUpText() {
        let attributedStrings = getAttributedText()

        gameOverLabel.attributedText = attributedStrings[0]
        scoreLabel.attributedText = attributedStrings[1]
        highScoreLabel.attributedText = attributedStrings[2]
        restartButton.setAttributedTitle(attributedStrings[3], for: .normal)
    }

    func getAttributedText() -> [NSMutableAttributedString] {
        let gameOverStr: NSMutableAttributedString = NSMutableAttributedString(string: "GAME OVER!")
        /*gameOverStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: NSRange(0...2))
        gameOverStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.green, range: NSRange(3...6))
        gameOverStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.blue, range: NSRange(7...9))
        gameOverStr.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: CGFloat(FONT_H / 2)), range: NSMakeRange(0, gameOverStr.length))*/

        let scoreStr: NSMutableAttributedString = NSMutableAttributedString(string: "SCORE: \(score)")
        /*scoreStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: NSRange(0...1))
        scoreStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.green, range: NSRange(2...3))
        scoreStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.blue, range: NSRange(4...5))
        scoreStr.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: CGFloat(FONT_H / 2)), range: NSMakeRange(0, scoreStr.length))*/

        let highScoreStr: NSMutableAttributedString = NSMutableAttributedString(string: "HIGH SCORE: \(highScore)")
        /*highScoreStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: NSRange(0...2))
        highScoreStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.green, range: NSRange(3...6))
        highScoreStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.blue, range: NSRange(7...10))
        highScoreStr.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: CGFloat(FONT_H / 2)), range: NSMakeRange(0, highScoreStr.length))*/

        let playAgainStr: NSMutableAttributedString = NSMutableAttributedString(string: "PLAY AGAIN")
        /*playAgainStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: NSRange(0...2))
        playAgainStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.green, range: NSRange(3...6))
        playAgainStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.blue, range: NSRange(7...9))
        playAgainStr.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: CGFloat(FONT_H / 2)), range: NSMakeRange(0, playAgainStr.length))*/

        return [gameOverStr, scoreStr, highScoreStr, playAgainStr]
    }

    func fadeIn() {
        //view.alpha = 0
        /*UIView.animate(withDuration: 0.5, delay: 0.0, options: UIView.AnimationOptions.curveEaseIn, animations: {
            self.view.alpha = 1.0
        }, completion: { finished in
            if finished {
                //Upon completion of the previous label fading in, the next one begins to fade in
                UIView.animate(withDuration: 0.5, delay: 0.0, options: UIView.AnimationOptions.curveEaseIn, animations: {
                    self.gameOverLabel.alpha = 1.0
                }, completion: { finished in
                    if finished {
                        UIView.animate(withDuration: 0.5, delay: 0.0, options: UIView.AnimationOptions.curveEaseIn, animations: {
                            self.scoreLabel.alpha = 1.0
                        }, completion: { finished in
                            if finished {
                                UIView.animate(withDuration: 0.5, delay: 0.0, options: UIView.AnimationOptions.curveEaseIn, animations: {
                                    self.highScoreLabel.alpha = 1.0
                                }, completion: { finished in
                                    if finished {
                                        UIView.animate(withDuration: 0.5, delay: 0.0, options: UIView.AnimationOptions.curveEaseIn, animations: {
                                            self.restartButton.alpha = 1.0
                                        }, completion: nil)
                                    }
                                })
                            }
                        })
                    }
                })
            }
        })*/
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
