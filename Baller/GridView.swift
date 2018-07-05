//
//  GridView.swift
//  Baller
//
//  Created by Frank Gao on 6/10/18.
//  Copyright © 2018 Frank Gao. All rights reserved.
//

import UIKit
import Foundation
import CoreGraphics


class GridView: UIView {
    let X_OFF = 10
    let Y_OFF = 20
    let COLUMNS = 4
    let ROWS = 5
    let MAX_NEW_BALLS = 2
    let START_NUM = 4
    let FONT_H = 60
    var x_stride = 0
    var y_stride = 0

    var mRadius = 0
    var mCenterX = 0
    var mCenterY = 0
    var mW = 0
    var mH = 0

    var showBallTimer: Timer? = nil
    var showNewBallAlpha: UInt32 = 0
    var showNewBallInProgress = false
    var newBallCount = 0

    private var balls: [Ball] = []
    var newBallIndex: [Int] = []

    private struct Ball: Equatable {
        var color: Int
        var score: Int

        init() {
            self.score = 0
            self.color = 0
        }
    }

    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    //var aalpha = 0x00000000
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        setNeedsDisplay()
        // Drawing code
        drawGrid()
        drawBalls(rect)
        if isGameOver() {
            parentViewController!.present(GameOverViewController(), animated: true, completion: nil)
        }
        //drawBall(x: X_OFF, y: Y_OFF, score: 0, color_code: 4, alpha: 0xff000000, rect: rect)
        //showBallTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(run), userInfo: nil, repeats: true)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setSizeVars()
        setUpGestures()

        balls = Array(repeating: Ball(), count: ROWS * COLUMNS)
        newBallIndex = Array(repeating: 0, count: MAX_NEW_BALLS)

        var rdmNumbers: Set<Int> = []
        while rdmNumbers.count < START_NUM {
            rdmNumbers.insert(Int(arc4random_uniform(UInt32(UInt32(balls.count)))))
        }

        /*for i in 0...balls.count - 1 {
         print(balls[i].color)
         }*/
        let startColors = [1, 2, 4]
        for rdm in rdmNumbers {
            balls[rdm].color = startColors[Int(arc4random_uniform(3))]
            balls[rdm].score = 1
            //print(balls[rdm].color)
        }

        /*for i in 0...balls.count - 1 {
         print(balls[i].color)
         }*/


    }

    func isGameOver() -> Bool {
        for i in 0...balls.count - 2 {
            if balls[i].color == 0 {
                return false
            }

            var belowColor = 0
            var rightColor = 0

            if !((i + COLUMNS) >= balls.count) {
                belowColor = balls[i + COLUMNS].color
            }
            if ((i / COLUMNS) == ((i + 1) / COLUMNS)) && ((i + 1) < balls.count) {
                rightColor = balls[i + 1].color
            }

            if isSingleColor(balls[i].color) {
                if ((belowColor & balls[i].color) > 0) && ((rightColor & balls[i].color) > 0) { return false }
            } else {
                for color in [belowColor, rightColor] {
                    if isSingleColor(color) {
                        if (color & balls[i].color) > 0 { return false }
                    } else if color == balls[i].color { return false }
                }
            }
        }
        return true
    }

    func setUpGestures() {
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(onSwipeLeft))
        leftSwipe.direction = .left
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(onSwipeRight))
        rightSwipe.direction = .right
        let topSwipe = UISwipeGestureRecognizer(target: self, action: #selector(onSwipeTop))
        topSwipe.direction = .up
        let bottomSwipe = UISwipeGestureRecognizer(target: self, action: #selector(onSwipeBottom))
        bottomSwipe.direction = .down

        self.addGestureRecognizer(leftSwipe)
        self.addGestureRecognizer(rightSwipe)
        self.addGestureRecognizer(topSwipe)
        self.addGestureRecognizer(bottomSwipe)
    }

    @objc func onSwipeLeft() {
        var index = 0
        for _ in 0...ROWS - 1 {
            var current = 0
            var last = current + 1 //first ball in the row to have non-white color

            while (last <= (COLUMNS - 1)) {
                //find first ball on this row
                while ((last <= (COLUMNS - 1)) && (balls[index + last].color == 0)) { last += 1 }
                if (last > COLUMNS - 1) {
                    //all empty, done
                } else {
                    //if the leading ball is white, move the color ball into that spot
                    if (balls[index + current].color == 0) {
                        balls[index + current].color = balls[index + last].color
                        balls[index + current].score = balls[index + last].score

                        balls[index + last].color = 0
                        last += 1
                    //if the two balls have the same color, combine them(score) into the leading space
                    } else if (balls[index + current].color == balls[index + last].color) {
                        balls[index + current].score += balls[index + last].score

                        balls[index + last].color = 0
                        last += 1
                    //otherwise, merge the multicolor ball, and if the two balls have diff colors, they won't merge
                    } else {
                        mergeMultiColor(idx1: index + current, idx2: index + last)

                        current += 1
                        last = current + 1
                    }
                }
            }

            index += COLUMNS
        }

        addRandomBall()
        setNeedsDisplay()
    }

    @objc func onSwipeRight() {
        var index = 0
        for _ in 0...ROWS - 1 {
            var current = COLUMNS - 1
            var last = current - 1

            while (last >= 0) {
                //find the first ball on this row
                while ((last >= 0) && (balls[index + last].color == 0)) { last -= 1 }
                if (last < 0) {
                    //all empty, done
                } else {
                    if (balls[index + current].color == 0) {
                        balls[index + current].color = balls[index + last].color
                        balls[index + current].score = balls[index + last].score

                        balls[index + last].color = 0
                        last -= 1
                    } else if (balls[index + current].color == balls[index + last].color) {
                        balls[index + current].score += balls[index + last].score

                        balls[index + last].color = 0
                        last -= 1
                    } else {
                        mergeMultiColor(idx1: index + current, idx2: index + last)

                        current -= 1
                        last = current - 1
                    }
                }
            }

            index += COLUMNS
        }

        addRandomBall()
        setNeedsDisplay()
    }

    @objc func onSwipeTop() {
        var index = 0
        for _ in 0...COLUMNS - 1 {
            var current = 0
            var last = current + 1

            while (last <= (ROWS - 1)) {
                //find first ball on this row
                while ((last <= (ROWS - 1)) && (balls[index + last * COLUMNS].color == 0)) { last += 1 }
                if (last > ROWS - 1) {
                    //all empty, done
                } else {
                    if (balls[index + current * COLUMNS].color == 0) {
                        balls[index + current * COLUMNS].color = balls[index + last * COLUMNS].color
                        balls[index + current * COLUMNS].score = balls[index + last * COLUMNS].score

                        balls[index + last * COLUMNS].color = 0
                        last += 1
                    } else if (balls[index + current * COLUMNS].color == balls[index + last * COLUMNS].color) {
                        balls[index + current * COLUMNS].score += balls[index + last * COLUMNS].score

                        balls[index + last * COLUMNS].color = 0
                        last += 1
                    } else {
                        mergeMultiColor(idx1: index + current * COLUMNS, idx2: index + last * COLUMNS)

                        current += 1
                        last = current + 1
                    }
                }
            }

            index += 1
        }

        addRandomBall()
        setNeedsDisplay()
    }

    @objc func onSwipeBottom() {
        var index = 0
        for _ in 0...COLUMNS - 1 {
            var current = ROWS - 1
            var last = current - 1
            while (last >= 0) {
                //find first ball on this row
                while ((last >= 0) && (balls[index + last * COLUMNS].color == 0)) { last -= 1 }
                if (last < 0) {
                    //all empty, done
                } else {
                    if (balls[index + current * COLUMNS].color == 0) {
                        balls[index + current * COLUMNS].color = balls[index + last * COLUMNS].color
                        balls[index + current * COLUMNS].score = balls[index + last * COLUMNS].score

                        balls[index + last * COLUMNS].color = 0
                        last -= 1
                    } else if (balls[index + current * COLUMNS].color == balls[index + last * COLUMNS].color) {
                        balls[index + current * COLUMNS].score += balls[index + last * COLUMNS].score

                        balls[index + last * COLUMNS].color = 0
                        last -= 1
                    } else {
                        mergeMultiColor(idx1: index + current * COLUMNS, idx2: index + last * COLUMNS)

                        current -= 1
                        last = current - 1
                    }
                }
            }

            index += 1
        }

        addRandomBall()
        setNeedsDisplay()
    }

    func isSingleColor(_ color_code: Int) -> Bool {
        return numOfColors(color_code) == 1
    }

    func mergeMultiColor(idx1: Int, idx2: Int) {
        var score = 0
        if isSingleColor(balls[idx1].color) {
            if ((balls[idx1].color & balls[idx2].color) == balls[idx1].color) {
                score = balls[idx2].score / numOfColors(balls[idx2].color)
                balls[idx1].score += score
                balls[idx2].score -= score
                balls[idx2].color ^= balls[idx1].color
            }
        } else if isSingleColor(balls[idx2].color) {
            if ((balls[idx2].color & balls[idx1].color) == balls[idx2].color) {
                score = balls[idx1].score / numOfColors(balls[idx1].color)
                balls[idx2].score += score
                balls[idx1].score -= score
                balls[idx1].color ^= balls[idx2].color
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: self)
            print(position.x)
            print(position.y)
        }
    }
    override func setNeedsDisplay() {
        super.setNeedsDisplay()

        setSizeVars()
    }

    func setSizeVars() {
        mW = Int(self.frame.width)
        mH = Int(self.frame.height)
        mCenterX = Int(self.frame.width) / 2
        mCenterY = Int(self.frame.height) / 2
    }

    func drawGrid() {
        x_stride = (mW - 2 * X_OFF) / COLUMNS
        y_stride = (mH - 2 * Y_OFF) / ROWS

        var x = X_OFF
        var y = Y_OFF

        let path = UIBezierPath()

        for _ in 0...ROWS {
            path.move(to: CGPoint(x: X_OFF, y: y))
            path.addLine(to: CGPoint(x: mW - X_OFF - 3, y: y))
            y += y_stride
        }

        for _ in 0...COLUMNS {
            path.move(to: CGPoint(x: x, y: Y_OFF))
            path.addLine(to: CGPoint(x: x, y: mH - Y_OFF - 3))
            x += x_stride
        }

        path.close()
        UIColor.black.set()
        path.stroke()
    }

    let PADDING = 5
    func drawBall(x: Int, y: Int, score: Int, color_code: Int, alpha: UInt32, rect: CGRect) {
        if color_code == 0 { return }

        var color: [UInt32] = [alpha, alpha, alpha]
        var colors = 0

        if ((color_code & 1) == 1) {
            color[colors] |= 0xff0000
            colors += 1
        }
        if ((color_code & 2) == 2) {
            color[colors] |= 0x00ff00
            colors += 1
        }
        if ((color_code & 4) == 4) {
            color[colors] |= 0x0000ff
            colors += 1
        }

        let xx = x + PADDING
        let yy = y + PADDING
        let xx_stride = x_stride - 2 * PADDING
        let yy_stride = y_stride - 2 * PADDING

        let textAttributes = [
            NSAttributedStringKey.font : UIFont.systemFont(ofSize: CGFloat(FONT_H / 2)),
            NSAttributedStringKey.foregroundColor : UIColor.white
        ]
        var path = UIBezierPath()
        if colors == 1 {
            path = UIBezierPath(rect: CGRect(x: xx, y: yy, width: xx_stride, height: yy_stride))
            UIColor(hex: color[0]).set()
            path.stroke()
            path.fill()

            let text_width = Int(String(score).size(withAttributes: textAttributes).width)
            String(score).draw(at: CGPoint(x: xx + xx_stride / 2 - text_width / 2, y: yy + yy_stride / 2 - FONT_H / 4), withAttributes: textAttributes)
        } else if (colors == 2) {
            path = UIBezierPath(rect: CGRect(x: xx, y: yy, width: xx_stride, height: yy_stride / 2))
            UIColor(hex: color[0]).set()
            path.stroke()
            path.fill()

            path = UIBezierPath(rect: CGRect(x: xx, y: yy + yy_stride / 2, width: xx_stride, height: yy_stride / 2))
            UIColor(hex: color[1]).set()
            path.stroke()
            path.fill()
        } else {
            path = UIBezierPath(rect: CGRect(x: xx, y: yy, width: xx_stride, height: yy_stride / 3))
            UIColor(hex: color[0]).set()
            path.stroke()
            path.fill()

            path = UIBezierPath(rect: CGRect(x: xx, y: yy + yy_stride / 3, width: xx_stride, height: yy_stride / 3))
            UIColor(hex: color[1]).set()
            path.stroke()
            path.fill()

            path = UIBezierPath(rect: CGRect(x: xx, y: yy + yy_stride * 2 / 3, width: xx_stride, height: yy_stride / 3))
            UIColor(hex: color[2]).set()
            path.stroke()
            path.fill()
        }
    }

    func drawBalls(_ rect: CGRect) {
        var alpha: UInt32 = 0xff000000
        for ii in 0...((ROWS * COLUMNS) - 1) {
            alpha = 0xff000000
            if balls[ii].color == 0 { continue }
            if showNewBallInProgress && (newBallCount > 0) {
                for jj in 0...newBallCount - 1 {
                    if newBallIndex[jj] == ii {
                        alpha = showNewBallAlpha << 24
                        break
                    }
                }
            }
            drawBall(x: X_OFF + (ii % COLUMNS) * x_stride, y: Y_OFF + ((ii / COLUMNS) % ROWS) * y_stride, score: balls[ii].score, color_code: balls[ii].color, alpha: alpha, rect: rect)
        }
    }

    func numOfColors(_ color_code: Int) -> Int {
        var colors = 0

        if ((color_code & 1) == 1) {
            colors += 1
        }
        if ((color_code & 2) == 2) {
            colors += 1
        }
        if ((color_code & 4) == 4) {
            colors += 1
        }
        return colors
    }

    func addRandomBall() {
        var count = 0
        var start = Int(arc4random_uniform(UInt32(ROWS * COLUMNS)))
        for _ in 0...ROWS * COLUMNS - 1 {
            if balls[start].color == 0 {
                balls[start].color = Int(arc4random_uniform(7) + 1)
                balls[start].score = numOfColors(balls[start].color)

                newBallIndex[count] = start

                count += 1
                if (count == MAX_NEW_BALLS) { break }
            }
            start += 7
            start %= (ROWS * COLUMNS)
        }

        newBallCount = count
        showNewBallAlpha = 0
        showNewBallInProgress = true
        showBallTimer = nil
        showBallTimer = Timer.scheduledTimer(timeInterval: 0.015, target: self, selector: #selector(run), userInfo: nil, repeats: true)
    }

    @objc func run() {
        showNewBallAlpha += 5
        if showNewBallAlpha > 0xff {
            showNewBallAlpha = 0xff
            showBallTimer?.invalidate()
            showBallTimer = nil
            showNewBallInProgress = false
        }
        setNeedsDisplay()
    }
}

extension UIColor {
    public convenience init(hex: UInt32) {
        let r, g, b: CGFloat
        var a: CGFloat

        a = CGFloat((hex & 0xff000000) >> 24) / 255
        r = CGFloat((hex & 0x00ff0000) >> 16) / 255
        g = CGFloat((hex & 0x0000ff00) >> 8) / 255
        b = CGFloat(hex & 0x000000ff) / 255

        self.init(red: r, green: g, blue: b, alpha: a)
    }
}

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}
