//
//  ViewController.swift
//  Baller
//
//  Created by Frank Gao on 6/12/18.
//  Copyright © 2018 Frank Gao. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        //setTitleColors()
        // Do any additional setup after loading the view, typically from a nib.
    }

   /* func setTitleColors() {
        let titleString: NSMutableAttributedString = titleLabel.attributedText! as! NSMutableAttributedString
        var counter = 0
        for color in [UIColor.red, UIColor.green, UIColor.blue] {
            titleString.addAttribute(NSAttributedStringKey.foregroundColor, value: color, range: NSRange(counter...counter))
            counter += 1
        }

        titleString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.red, range: NSRange(4...6))
        titleString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.green, range: NSRange(7...9))
        titleString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.blue, range: NSRange(10...11))

        titleLabel.attributedText = titleString
    }*/

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

