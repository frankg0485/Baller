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
    var mCenterY = 9
    var mW = 0
    var mH = 0

    var newBallCount = 0

    private var balls: [Ball] = []
    var newBallIndex: [Int] = []

    private struct Ball {
        var color: Int
        var score: Int

        init() {
            self.score = 0
            self.color = 0
        }
    }

    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        // Drawing code
        drawGrid()
        drawBalls(rect)
        //drawBall(x: X_OFF, y: Y_OFF, score: 0, color_code: 4, alpha: 1, rect: rect)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setSizeVars()
        setUpGestures()

        balls = Array(repeating: Ball(), count: ROWS * COLUMNS)
        newBallIndex = Array(repeating: 0, count: MAX_NEW_BALLS)

        var rdmNumbers: Set<Int> = []
        while rdmNumbers.count < START_NUM {
            rdmNumbers.insert(Int(arc4random_uniform(UInt32(balls.count))))
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
        layoutSubviews()
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
        layoutSubviews()
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
        layoutSubviews()
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
        layoutSubviews()
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
    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()

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
            path.addLine(to: CGPoint(x: mW - X_OFF, y: y))
            y += y_stride
        }

        for _ in 0...COLUMNS {
            path.move(to: CGPoint(x: x, y: Y_OFF))
            path.addLine(to: CGPoint(x: x, y: mH - Y_OFF))
            x += x_stride
        }

        path.close()
        UIColor.black.set()
        path.stroke()
    }

    let PADDING = 5
    func drawBall(x: Int, y: Int, score: Int, color_code: Int, alpha: Int, rect: CGRect) {
        if color_code == 0 { return }

        var color: [Int] = [alpha, alpha, alpha]
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
            NSAttributedStringKey.font : UIFont.systemFont(ofSize: CGFloat(FONT_H)),
            NSAttributedStringKey.foregroundColor : UIColor.white
        ]
        var path = UIBezierPath()
        if colors == 1 {
            path = UIBezierPath(rect: CGRect(x: xx, y: yy, width: xx_stride, height: yy_stride))
            UIColor(hex: color[0]).set()
            path.stroke()
            path.fill()

            let text_width = Int(String(score).size(withAttributes: textAttributes).width)
            let text_height = Int(String(score).size(withAttributes: textAttributes).height)
            String(score).draw(at: CGPoint(x: xx + xx_stride / 2 - text_width / 2, y: yy + yy_stride / 2 - FONT_H / 2), withAttributes: textAttributes)
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
        var alpha = 0xff000000
        for ii in 0...((ROWS * COLUMNS) - 1) {
            alpha = 0xff000000
            if balls[ii].color == 0 { continue }
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
    }
}

extension UIColor {
    convenience init(hex: Int) {
        let components = (
            R: CGFloat((hex >> 16) & 0xff) / 255,
            G: CGFloat((hex >> 08) & 0xff) / 255,
            B: CGFloat((hex >> 00) & 0xff) / 255
        )
        self.init(red: components.R, green: components.G, blue: components.B, alpha: 1)
    }
}
