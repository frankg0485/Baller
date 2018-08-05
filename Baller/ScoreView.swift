//
//  ScoreView.swift
//  Baller
//
//  Created by Frank Gao on 7/10/18.
//  Copyright © 2018 Frank Gao. All rights reserved.
//

import UIKit

class ScoreView: UIView {


    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        drawScoreCircle(rect)
    }

    func drawScoreCircle(_ rect: CGRect) {
        /*let circle = UIBezierPath(ovalIn: rect)
        UIColor.red.set()
        circle.stroke()
        circle.fill()*/
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let redArc = UIBezierPath()
        redArc.addArc(withCenter: center, radius: rect.midX - 5, startAngle: CGFloat.pi / 6, endAngle: 5 * CGFloat.pi / 6, clockwise: true)
        redArc.addLine(to: center)
        redArc.close()
        UIColor.red.set()
        redArc.fill()

        let greenArc = UIBezierPath()
        greenArc.addArc(withCenter: center, radius: rect.midX - 5, startAngle: 5 * CGFloat.pi / 6, endAngle: 3 * CGFloat.pi / 2, clockwise: true)
        greenArc.addLine(to: center)
        greenArc.close()
        UIColor.green.set()
        greenArc.fill()

        let blueArc = UIBezierPath()
        blueArc.addArc(withCenter: center, radius: rect.midX - 5, startAngle: 3 * CGFloat.pi / 2, endAngle: CGFloat.pi / 6, clockwise: true)
        blueArc.addLine(to: center)
        blueArc.close()
        UIColor.blue.set()
        blueArc.fill()

        /*let path = UIBezierPath()
        path.move(to: lineDivide)
        path.addLine(to: center)
        path.addLine(to: lineDivide2)
        path.move(to: center)
        path.addLine(to: lineDivide3)
        UIColor.black.set()
        path.stroke()*/
    }
}
