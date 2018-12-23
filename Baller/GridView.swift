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

protocol ModalHandler {
    func modalDismissed()
}

class GridView: UIView, ModalHandler, UIPopoverPresentationControllerDelegate {
    let X_OFF: Double = 10
    let Y_OFF: Double = 10
    let COLUMNS = 4
    let ROWS = 5
    let MAX_NEW_BALLS = 2
    let START_NUM = 4
    let FONT_H: Double = 60
    var x_stride: Double = 0
    var y_stride: Double = 0

    var mRadius: Double = 0
    var mCenterX: Double = 0
    var mCenterY: Double = 0
    var mW: Double = 0
    var mH: Double = 0

    var animateScoreTimer: Timer? = nil
    var showBallTimer: Timer? = nil
    var scoreTime: Double = 0
    let timerSpeed = 0.001
    var showNewBallAlpha: UInt32 = 0
    var showNewBallInProgress = false
    var newBallCount = 0

    private var balls: [Ball] = []
    var newBallIndex: [Int] = []
    var savedIndex = 0

    var realScore = 0
    var displayScore = 0
    var highScore = SavedData.getHighScore()

    var once = false
    var redrawBalls = true

    var startingPositions = [CGPoint]()
    private var scoreAnimationData = [ScoreData]()

    //This is set in drawScore()
    var mainScorePosition = CGPoint(x: 0, y: 0)

    let deltaLength = 1.5

    let tests = [0, 0, 0, 0,
                 0, 0, 0, 0,
                 0, 0, 0, 0,
                 0, 0, 0, 0,
                 1, 1, 1, 1]

    private struct Ball: Equatable {
        var color: Int
        var score: Int

        init() {
            self.score = 0
            self.color = 0
        }
    }

    private struct ScoreData: Equatable {
        var score: Int
        var position: CGPoint
        var deltaX: Double
        var deltaY: Double
        var ballDiameter: Double = 25
        var color: Int

        init(score: Int, point: CGPoint, delta: (Double, Double), color: Int) {
            self.score = score
            self.position = point
            self.deltaX = delta.0
            self.deltaY = delta.1
            self.color = color
        }
    }
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    //var aalpha = 0x00000000
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        // Drawing code
        drawScoreAnimation()
        drawScore(rect)
        setSizeVars()
        drawGrid()
        drawBalls()
        if isGameOver() && (once == false) {
            if SavedData.getHighScore() < highScore { SavedData.setHighScore(score: highScore) }

            if !redrawBalls {
                once = true
                animateScoreTimer?.invalidate()
                animateScoreTimer = nil
                showBallTimer?.invalidate()
                showBallTimer = nil

                usleep(250000)
                presentGameOver()
            } else { redrawBalls = false }
        }
        //drawBall(x: X_OFF, y: Y_OFF, score: 0, color_code: 4, alpha: 0xff000000, rect: rect)
        //showBallTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(run), userInfo: nil, repeats: true)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        gridInit()
    }

    /*func stopTimers() {
        animateScoreTimer?.invalidate()
        animateScoreTimer = nil
        showBallTimer?.invalidate()
        showBallTimer = nil
    }*/

    func modalDismissed() {
        gridInit()
        setNeedsDisplay()
    }

    func gridInit() {
        realScore = 0
        displayScore = 0
        once = false
        redrawBalls = true

        setSizeVars()
        setUpGestures()

        balls = Array(repeating: Ball(), count: ROWS * COLUMNS)
        newBallIndex = Array(repeating: 0, count: MAX_NEW_BALLS)
        scoreAnimationData = [ScoreData]()
        startingPositions = Array(repeating: CGPoint(x: 0, y: 0), count: ROWS * COLUMNS)

        beginAnimation()

        var rdmNumbers: Set<Int> = []
        while rdmNumbers.count < START_NUM {
            rdmNumbers.insert(Int(arc4random_uniform(UInt32(UInt32(balls.count)))))
        }

        let startColors = [1, 2, 4]
        for rdm in rdmNumbers {
            balls[rdm].color = startColors[Int(arc4random_uniform(3))]
            balls[rdm].score = 1
        }
        for i in 0...ROWS*COLUMNS - 1 {
            balls[i].color = tests[i]
            balls[i].score = numOfColors(balls[i].color)
        }
    }

    func drawScore(_ rect: CGRect) {
        /*let textAttributes = [
            NSAttributedStringKey.font : UIFont.systemFont(ofSize: CGFloat(FONT_H / 2)),
            NSAttributedStringKey.foregroundColor : UIColor.red
        ]*/
        let scoreStr: NSMutableAttributedString = NSMutableAttributedString(string: "SCORE: \(displayScore)")
        scoreStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: NSRange(0...1))
        scoreStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.green, range: NSRange(2...3))
        scoreStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.blue, range: NSRange(4...5))
        scoreStr.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: CGFloat(FONT_H / 3)), range: NSMakeRange(0, scoreStr.length))
        var halfLen = scoreStr.attributedSubstring(from: NSRange(location: 0, length: 6)).size().width / 2
        scoreStr.attributedSubstring(from: NSRange(location: 0, length: 6)).draw(at: CGPoint(x: rect.maxX / 3 - halfLen, y: 50))
        halfLen = scoreStr.attributedSubstring(from: NSRange(location: 7, length: scoreStr.length - 7)).size().width / 2
        mainScorePosition = CGPoint(x: rect.maxX / 3 - halfLen, y: 100)
        scoreStr.attributedSubstring(from: NSRange(location: 7, length: scoreStr.length - 7)).draw(at: mainScorePosition)

        let highScoreStr: NSMutableAttributedString = NSMutableAttributedString(string: "HIGH SCORE: \(highScore)")
        print(scoreStr, highScoreStr)
        highScoreStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: NSRange(0...2))
        highScoreStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.green, range: NSRange(3...6))
        highScoreStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.blue, range: NSRange(7...10))
        highScoreStr.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: CGFloat(FONT_H / 3)), range: NSMakeRange(0, highScoreStr.length))
        halfLen = highScoreStr.attributedSubstring(from: NSRange(location: 0, length: 12)).size().width / 2
        highScoreStr.attributedSubstring(from: NSRange(location: 0, length: 12)).draw(at: CGPoint(x: rect.maxX * 2 / 3 - halfLen, y: 50))
        halfLen = highScoreStr.attributedSubstring(from: NSRange(location: 12, length: highScoreStr.length - 12)).size().width / 2
        highScoreStr.attributedSubstring(from: NSRange(location: 12, length: highScoreStr.length - 12)).draw(at: CGPoint(x: rect.maxX * 2 / 3 - halfLen, y: 100))
    }

    /*func resetScoreAnimationData() {
        scoreTime = 0
        positionsInUse = Array(repeating: false, count: ROWS * COLUMNS)
        scores = Array(repeating: 0, count: ROWS * COLUMNS)
        animationInProgress = false
     }*/

    private func removeScoreElement(_ scoreElement: ScoreData) {
        scoreAnimationData.remove(at: scoreAnimationData.firstIndex(of: scoreElement)!)
    }

    func drawSmallBall(index: Int, strSize: CGSize) {
        var colors: [UInt32] = [0x30000000, 0x30000000, 0x30000000]
        var colorCount = 0
        let color = scoreAnimationData[index].color

        if ((color & 1) == 1) {
            colors[colorCount] |= 0xff0000
            colorCount += 1
        }
        if ((color & 2) == 2) {
            colors[colorCount] |= 0x00ff00
            colorCount += 1
        }
        if ((color & 4) == 4) {
            colors[colorCount] |= 0x0000ff
            colorCount += 1
        }
        let pointX = Double(scoreAnimationData[index].position.x) - scoreAnimationData[index].ballDiameter / 2 + Double(strSize.width) / 2
        let pointY = Double(scoreAnimationData[index].position.y) - scoreAnimationData[index].ballDiameter / 2 + Double(strSize.height) / 2
        let center = CGPoint(x: scoreAnimationData[index].position.x + strSize.width / 2, y: scoreAnimationData[index].position.y + strSize.height / 2)
        let radius = CGFloat(scoreAnimationData[index].ballDiameter / 2)
        if colorCount == 1 {
            let arc = UIBezierPath(ovalIn: CGRect(x: pointX, y: pointY, width: scoreAnimationData[index].ballDiameter, height: scoreAnimationData[index].ballDiameter))
            UIColor(hex: colors[0]).set()
            arc.stroke()
            arc.fill()
        } else if colorCount == 2 {
            let arc1 = UIBezierPath()
            arc1.addArc(withCenter: center, radius: radius, startAngle: CGFloat.pi / 2, endAngle: 3 * CGFloat.pi / 2, clockwise: true)
            arc1.close()
            UIColor(hex: colors[0]).set()
            arc1.fill()

            let arc2 = UIBezierPath()
            arc2.addArc(withCenter: center, radius: radius, startAngle: 3 * CGFloat.pi / 2, endAngle: 5 * CGFloat.pi / 2, clockwise: true)
            arc2.close()
            UIColor(hex: colors[1]).set()
            arc2.fill()
        } else {
            let arc1 = UIBezierPath()
            arc1.addArc(withCenter: center, radius: radius, startAngle: CGFloat.pi / 6, endAngle: 5 * CGFloat.pi / 6, clockwise: true)
            arc1.addLine(to: center)
            arc1.close()
            UIColor(hex: colors[0]).set()
            arc1.fill()

            let arc2 = UIBezierPath()
            arc2.addArc(withCenter: center, radius: radius, startAngle: 5 * CGFloat.pi / 6, endAngle: 3 * CGFloat.pi / 2, clockwise: true)
            arc2.addLine(to: center)
            arc2.close()
            UIColor(hex: colors[1]).set()
            arc2.fill()

            let arc3 = UIBezierPath()
            arc3.addArc(withCenter: center, radius: radius, startAngle: 3 * CGFloat.pi / 2, endAngle: CGFloat.pi / 6, clockwise: true)
            arc3.addLine(to: center)
            arc3.close()
            UIColor(hex: colors[2]).set()
            arc3.fill()
        }

    }

    func drawScoreAnimation() {
        var count = 0
        for _ in scoreAnimationData {
            if abs(scoreAnimationData[count].position.x - mainScorePosition.x) < 10 && abs(scoreAnimationData[count].position.y - mainScorePosition.y) < 10 {
                displayScore += scoreAnimationData[count].score// = realScore
                removeScoreElement(scoreAnimationData[count])
                if displayScore > highScore { highScore = displayScore }
                setNeedsDisplay()
                continue
            }
            let scoreStr = "\(scoreAnimationData[count].score)"
            let finalStr: NSMutableAttributedString = NSMutableAttributedString(string: scoreStr)

            drawSmallBall(index: count, strSize: finalStr.size())

            finalStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.black, range: NSRange(0..<scoreStr.count))
            finalStr.draw(at: CGPoint(x: scoreAnimationData[count].position.x/*CGPoint(x: (scoreTime / travelTime) * Double(mainScorePosition.x - data.position.x) + Double(data.position.x)*/, y: scoreAnimationData[count].position.y/*(scoreTime / travelTime) * Double(mainScorePosition.y - data.position.y) + Double(position.y))*/))
            count += 1
        }
    }

    func calcAnimation() {
        var count = 0
        for _ in scoreAnimationData {
            scoreAnimationData[count].position.x -= CGFloat(scoreAnimationData[count].deltaX)
            scoreAnimationData[count].position.y -= CGFloat(scoreAnimationData[count].deltaY)
            count += 1
        }
    }

    @objc func animateScore() {
        //scoreTime += increment
        /*if scoreTime > travelTime {
            animateScoreTimer?.invalidate()
            animateScoreTimer = nil

            displayScore = realScore
            if displayScore > highScore { highScore = displayScore }
            //resetScoreAnimationData()
        }*/
        calcAnimation()
        setNeedsDisplay()
    }

    func getCurrentViewController() -> UIViewController? {
        if let rootController = UIApplication.shared.keyWindow?.rootViewController {
            var currentController: UIViewController! = rootController
            while( currentController.presentedViewController != nil ) {
                currentController = currentController.presentedViewController
            }
            return currentController
        }
        return nil
    }

    func presentGameOver() {
        /*let transition: CATransition = CATransition()
        transition.duration = 0.75
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        transition.type = CATransitionType.fade*/

        let currentController = (getCurrentViewController() as! UINavigationController).topViewController!
        //print(currentController.navigationController)
        //currentController.navigationController!.view.layer.add(transition, forKey: nil)

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "GameOverViewController") as! GameOverViewController
        vc.modalPresentationStyle = UIModalPresentationStyle.popover
        vc.highScore = highScore
        vc.score = displayScore
        vc.FONT_H = FONT_H
        vc.delegate = self
        if let popoverPresentationController =  vc.popoverPresentationController {
            popoverPresentationController.delegate = self
            popoverPresentationController.sourceView  = currentController.view
            popoverPresentationController.sourceRect  = CGRect.init(x: currentController.view.frame.midX, y: currentController.view.frame.midY, width: 0, height: 0)
            popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
        }
        currentController.present(vc, animated: false, completion: {
            vc.fadeIn()
        })
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
                if ((belowColor & balls[i].color) > 0) || ((rightColor & balls[i].color) > 0) { return false }
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

    /*func updatePositionScoreArrays(_ index: Int) {
        positionsInUse[index] = true
        scores[index] = balls[index].score
    }*/

    func beginAnimation() {
        animateScoreTimer = Timer.scheduledTimer(timeInterval: timerSpeed, target: self, selector: #selector(animateScore), userInfo: nil, repeats: true)
    }

    func calcScore(_ ballScore: Int) {
        realScore += ballScore
    }

    func appendToAnimationArray(idx: Int, score: Int, color: Int) {
        let distX = Double(startingPositions[idx].x - mainScorePosition.x)
        let distY = Double(startingPositions[idx].y - mainScorePosition.y)
        let distance = sqrt(pow(distX, 2) + pow(distY, 2))
        scoreAnimationData.append(ScoreData(score: score, point: startingPositions[idx], delta: ((deltaLength / distance) * (distX), (deltaLength / distance) * distY), color: color))//(timerSpeed / travelTime) * (Double(startingPositions[idx].x) - Double(mainScorePosition.x)), (timerSpeed / travelTime) * (Double(startingPositions[idx].y) - Double(mainScorePosition.y))), color: color))
    }

    @objc func onSwipeLeft() {
        showBallTimer?.invalidate()
        showBallTimer = nil

        var index = (ROWS - 1) * COLUMNS
        var rightIndex = ROWS * COLUMNS - 1
        var counter = 0

        func shiftBalls() {
            while (rightIndex + counter) < (index + COLUMNS - 1) {
                balls[rightIndex + counter].color = balls[rightIndex + counter + 1].color
                balls[rightIndex + counter].score = balls[rightIndex + counter + 1].score
                balls[rightIndex + counter + 1].color = 0
                balls[rightIndex + counter + 1].score = 0
                counter += 1
            }
        }

        for _ in 0...ROWS - 1 {
            while rightIndex > index {
                //find the rightmost ball in the row that has non-white color
                while (balls[rightIndex].color == 0) && (rightIndex > index) { rightIndex -= 1 }
                //if there is only one ball on the very left, or there are none in the row, move on to the next row
                if rightIndex == index { break }
                if balls[rightIndex - 1].color == 0 {
                    //if the ball on the left is empty, move all balls left one space
                    //start by shifting current ball onto the left one
                    counter = -1
                    shiftBalls()
                } else if balls[rightIndex - 1].color == balls[rightIndex].color {
                    //if the ball on the left has the same color as this one, combine the two and put it on the left square
                    //Only add the smaller ball score to the total
                    if balls[rightIndex].score < balls[rightIndex - 1].score {
                        calcScore(rightIndex)
                        appendToAnimationArray(idx: rightIndex, score: balls[rightIndex].score, color: balls[rightIndex].color)
                    } else {
                        calcScore(rightIndex - 1)
                        appendToAnimationArray(idx: rightIndex - 1, score: balls[rightIndex - 1].score, color: balls[rightIndex - 1].color)
                    }
                    balls[rightIndex - 1].score += balls[rightIndex].score
                    balls[rightIndex].score = 0
                    balls[rightIndex].color = 0
                    //start by shifting the one on the right to the current one
                    counter = 0
                    shiftBalls()
                } else {
                    mergeMultiColor(idx1: rightIndex, idx2: rightIndex - 1, defaultIdx: rightIndex - 1)
                }
                rightIndex -= 1
            }

            rightIndex -= 1
            index -= COLUMNS
        }
        addRandomBall()
        setNeedsDisplay()
    }

    @objc func onSwipeRight() {
        showBallTimer?.invalidate()
        showBallTimer = nil

        var index = COLUMNS - 1
        var leftIndex = 0
        var counter = 0

        func shiftBalls() {
            while (leftIndex - counter) > (index - (COLUMNS - 1)) {
                balls[leftIndex - counter].color = balls[leftIndex - counter - 1].color
                balls[leftIndex - counter].score = balls[leftIndex - counter - 1].score
                balls[leftIndex - counter - 1].color = 0
                balls[leftIndex - counter - 1].score = 0
                counter += 1
            }
        }

        for _ in 0...ROWS - 1 {
            while leftIndex < index {
                //find the leftmost ball in the row that has non-white color
                while (balls[leftIndex].color == 0) && (leftIndex < index) { leftIndex += 1 }
                //if there is only one ball on the very right, or there are none in the row, move on to the next row
                if leftIndex == index { break }
                if balls[leftIndex + 1].color == 0 {
                    //if the ball on the right is empty, move all balls right one space
                    //start by moving the current ball onto the one on the right
                    counter = -1
                    shiftBalls()
                } else if balls[leftIndex + 1].color == balls[leftIndex].color {
                    //if the ball on the right has the same color as this one, combine the two and put it on the right square
                    //Only add the smaller ball score to the total
                    if balls[leftIndex].score < balls[leftIndex + 1].score {
                        calcScore(leftIndex)
                        appendToAnimationArray(idx: leftIndex, score: balls[leftIndex].score, color: balls[leftIndex].color)
                    } else {
                        calcScore(leftIndex + 1)
                        appendToAnimationArray(idx: leftIndex + 1, score: balls[leftIndex + 1].score, color: balls[leftIndex + 1].color)
                    }
                    balls[leftIndex + 1].score += balls[leftIndex].score
                    balls[leftIndex].score = 0
                    balls[leftIndex].color = 0
                    //start shifting by moving the left ball onto this one
                    counter = 0
                    shiftBalls()
                } else {
                    mergeMultiColor(idx1: leftIndex, idx2: leftIndex + 1, defaultIdx: leftIndex + 1)
                }
                leftIndex += 1
            }

            leftIndex += 1
            index += COLUMNS
        }
        addRandomBall()
        setNeedsDisplay()
    }

    @objc func onSwipeTop() {
        showBallTimer?.invalidate()
        showBallTimer = nil

        var index = 0
        var bottomIndex = COLUMNS * (ROWS - 1)
        var counter = 0

        func shiftBalls() {
            while (bottomIndex + counter * COLUMNS) < (index + COLUMNS * (ROWS - 1)) {
                balls[bottomIndex + counter * COLUMNS].color = balls[bottomIndex + counter * COLUMNS + COLUMNS].color
                balls[bottomIndex + counter * COLUMNS].score = balls[bottomIndex + counter * COLUMNS + COLUMNS].score
                balls[bottomIndex + counter * COLUMNS + COLUMNS].color = 0
                balls[bottomIndex + counter * COLUMNS + COLUMNS].score = 0
                counter += 1
            }
        }

        for _ in 0...COLUMNS - 1 {
            while bottomIndex > index {
                //find the lowest ball in the row that has non-white color
                while (balls[bottomIndex].color == 0) && (bottomIndex > index) { bottomIndex -= COLUMNS }
                //if there is only one ball on the very top, or there are none in the column, move on to the next column
                if bottomIndex == index { break }
                if balls[bottomIndex - COLUMNS].color == 0 {
                    //if the ball on the top is empty, move all balls up one space
                    //start by shifting current ball onto the top one
                    counter = -1
                    shiftBalls()
                } else if balls[bottomIndex - COLUMNS].color == balls[bottomIndex].color {
                    //if the ball on the left has the same color as this one, combine the two and put it on the left square
                    //Only add the smaller ball score to the total
                    if balls[bottomIndex].score < balls[bottomIndex - COLUMNS].score {
                        calcScore(bottomIndex)
                        appendToAnimationArray(idx: bottomIndex, score: balls[bottomIndex].score, color: balls[bottomIndex].color)
                    } else {
                        calcScore(bottomIndex - COLUMNS)
                        appendToAnimationArray(idx: bottomIndex - COLUMNS, score: balls[bottomIndex - COLUMNS].score, color: balls[bottomIndex - COLUMNS].color)
                    }
                    balls[bottomIndex - COLUMNS].score += balls[bottomIndex].score
                    balls[bottomIndex].score = 0
                    balls[bottomIndex].color = 0
                    //start by shifting the one on the bottom to the current one
                    counter = 0
                    shiftBalls()
                } else {
                    mergeMultiColor(idx1: bottomIndex, idx2: bottomIndex - COLUMNS, defaultIdx: bottomIndex - COLUMNS)
                }
                bottomIndex -= COLUMNS
            }

            index += 1
            bottomIndex = index + COLUMNS * (ROWS - 1)
        }
        addRandomBall()
        setNeedsDisplay()
    }

    @objc func onSwipeBottom() {
        showBallTimer?.invalidate()
        showBallTimer = nil

        var index = COLUMNS * (ROWS - 1)
        var topIndex = 0
        var counter = 0

        func shiftBalls() {
            while (topIndex - counter * COLUMNS) > (index - COLUMNS * (ROWS - 1)) {
                balls[topIndex - counter * COLUMNS].color = balls[topIndex - counter * COLUMNS - COLUMNS].color
                balls[topIndex - counter * COLUMNS].score = balls[topIndex - counter * COLUMNS - COLUMNS].score
                balls[topIndex - counter * COLUMNS - COLUMNS].color = 0
                balls[topIndex - counter * COLUMNS - COLUMNS].score = 0
                counter += 1
            }
        }

        for _ in 0...COLUMNS - 1 {
            while topIndex < index {
                //find the leftmost ball in the row that has non-white color
                while (balls[topIndex].color == 0) && (topIndex < index) { topIndex += COLUMNS }
                //if there is only one ball on the very right, or there are none in the row, move on to the next row
                if topIndex == index { break }
                if balls[topIndex + COLUMNS].color == 0 {
                    //if the ball on the right is empty, move all balls right one space
                    //start by moving the current ball onto the one on the right
                    counter = -1
                    shiftBalls()
                } else if balls[topIndex + COLUMNS].color == balls[topIndex].color {
                    //if the ball on the right has the same color as this one, combine the two and put it on the right square
                    //Only add the smaller ball score to the total
                    if balls[topIndex].score < balls[topIndex + COLUMNS].score {
                        calcScore(topIndex)
                        appendToAnimationArray(idx: topIndex, score: balls[topIndex].score, color: balls[topIndex].color)
                    } else {
                        calcScore(topIndex + COLUMNS)
                        appendToAnimationArray(idx: topIndex + COLUMNS, score: balls[topIndex + COLUMNS].score, color: balls[topIndex + COLUMNS].color)
                    }
                    balls[topIndex + COLUMNS].score += balls[topIndex].score
                    balls[topIndex].score = 0
                    balls[topIndex].color = 0
                    //start shifting by moving the left ball onto this one
                    counter = 0
                    shiftBalls()
                } else {
                    mergeMultiColor(idx1: topIndex, idx2: topIndex + COLUMNS, defaultIdx: topIndex + COLUMNS)
                }
                topIndex += COLUMNS
            }

            index += 1
            topIndex = index - COLUMNS * (ROWS - 1)
        }
        addRandomBall()
        setNeedsDisplay()
    }

    func isSingleColor(_ color_code: Int) -> Bool {
        return numOfColors(color_code) == 1
    }

    func mergeMultiColor(idx1: Int, idx2: Int, defaultIdx: Int) {
        var score = 0
        if isSingleColor(balls[idx1].color) {
            if ((balls[idx1].color & balls[idx2].color) == balls[idx1].color) {
                score = balls[idx2].score / numOfColors(balls[idx2].color)
                if score >= balls[idx1].score {
                    if defaultIdx == idx1 {
                        calcScore(balls[idx1].score)
                        appendToAnimationArray(idx: idx1, score: balls[idx1].score, color: balls[idx1].color)
                    } else {
                        calcScore(score)
                        appendToAnimationArray(idx: idx2, score: score, color: balls[idx2].color)
                    }
                } else {
                    calcScore(score)
                    appendToAnimationArray(idx: idx2, score: score, color: balls[idx2].color)
                }
                balls[idx1].score += score
                balls[idx2].score -= score
                balls[idx2].color ^= balls[idx1].color
            }
        } else if isSingleColor(balls[idx2].color) {
            if ((balls[idx2].color & balls[idx1].color) == balls[idx2].color) {
                score = balls[idx1].score / numOfColors(balls[idx1].color)
                //Only add the smaller score to the total
                if score >= balls[idx2].score {
                    if defaultIdx == idx2 {
                        calcScore(balls[idx2].score)
                        appendToAnimationArray(idx: idx2, score: balls[idx2].score, color: balls[idx2].color)
                    } else {
                        calcScore(score)
                        appendToAnimationArray(idx: idx1, score: score, color: balls[idx2].color)
                    }
                } else {
                    calcScore(score)
                    appendToAnimationArray(idx: idx1, score: score, color: balls[idx2].color)
                }
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
        mW = Double(self.frame.width)
        mH = Double(self.frame.height)
    }

    func drawGrid() {
        x_stride = Double((mW/* - 2 * X_OFF*/) / Double(COLUMNS))
        y_stride = x_stride//Double((mH/* - 2 * Y_OFF*/) / Double(ROWS))

        var x: Double = 0//X_OFF
        var y: Double = mH//Y_OFF

        let path = UIBezierPath()

        for _ in 0...ROWS {
            path.move(to: CGPoint(x: 0/*Y_OFF*/, y: y))
            path.addLine(to: CGPoint(x: mW/* - X_OFF*/, y: y))
            y -= y_stride
        }

        for _ in 0...COLUMNS {
            path.move(to: CGPoint(x: x, y: mH/*Y_OFF*/))
            path.addLine(to: CGPoint(x: x, y: mH -  5 * y_stride/* - Y_OFF*/))
            x += x_stride
        }

        path.close()
        UIColor.black.set()
        path.stroke()
    }

    let PADDING: Double = 5
    func drawBall(x: Double, y: Double, score: Int, color_code: Int, alpha: UInt32) {
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
            NSAttributedString.Key.font : UIFont.systemFont(ofSize: CGFloat(FONT_H / 2)),
            NSAttributedString.Key.foregroundColor : UIColor.white
        ]

        let center = CGPoint(x: xx + xx_stride / 2, y: yy + yy_stride / 2)
        let radius = CGFloat(xx_stride / 2)
        if colors == 1 {
            var arc = UIBezierPath()
            arc = UIBezierPath(ovalIn: CGRect(x: xx, y: yy, width: xx_stride, height: yy_stride))
            UIColor(hex: color[0]).set()
            arc.stroke()
            arc.fill()

            let text_width = Double(String(score).size(withAttributes: textAttributes).width)
            String(score).draw(at: CGPoint(x: xx + xx_stride / 2 - text_width / 2, y: yy + yy_stride / 2 - FONT_H / 4), withAttributes: textAttributes)
        } else if (colors == 2) {
            let arc1 = UIBezierPath()
            arc1.addArc(withCenter: center, radius: radius, startAngle: CGFloat.pi / 2, endAngle: 3 * CGFloat.pi / 2, clockwise: true)
            arc1.close()
            UIColor(hex: color[0]).set()
            arc1.fill()

            let arc2 = UIBezierPath()
            arc2.addArc(withCenter: center, radius: radius, startAngle: 3 * CGFloat.pi / 2, endAngle: 5 * CGFloat.pi / 2, clockwise: true)
            arc2.close()
            UIColor(hex: color[1]).set()
            arc2.fill()
        } else {
            let arc1 = UIBezierPath()
            arc1.addArc(withCenter: center, radius: radius, startAngle: CGFloat.pi / 6, endAngle: 5 * CGFloat.pi / 6, clockwise: true)
            arc1.addLine(to: center)
            arc1.close()
            UIColor(hex: color[0]).set()
            arc1.fill()

            let arc2 = UIBezierPath()
            arc2.addArc(withCenter: center, radius: radius, startAngle: 5 * CGFloat.pi / 6, endAngle: 3 * CGFloat.pi / 2, clockwise: true)
            arc2.addLine(to: center)
            arc2.close()
            UIColor(hex: color[1]).set()
            arc2.fill()

            let arc3 = UIBezierPath()
            arc3.addArc(withCenter: center, radius: radius, startAngle: 3 * CGFloat.pi / 2, endAngle: CGFloat.pi / 6, clockwise: true)
            arc3.addLine(to: center)
            arc3.close()
            UIColor(hex: color[2]).set()
            arc3.fill()
        }
    }

    func drawBalls() {
        var alpha: UInt32 = 0xff000000
        for ii in 0...((ROWS * COLUMNS) - 1) {
            alpha = 0xC0000000

            let iiDivideColumns = (Double(ii) / Double(COLUMNS)).rounded(.towardZero)
            let x = Double(ii).truncatingRemainder(dividingBy: Double(COLUMNS)) * x_stride
            let y = mH - Double(ROWS) * y_stride + (iiDivideColumns.truncatingRemainder(dividingBy: Double(ROWS)) * y_stride)
            startingPositions[ii] = CGPoint(x: x, y: y)

            if balls[ii].color == 0 { continue }
            if showNewBallInProgress && (newBallCount > 0) {
                for jj in 0...newBallCount - 1 {
                    if newBallIndex[jj] == ii {
                        alpha = showNewBallAlpha << 24
                        break
                    }
                }
            }
            drawBall(x: x, y: y, score: balls[ii].score, color_code: balls[ii].color, alpha: alpha)
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
        if showNewBallAlpha > 0xC0 {
            showNewBallAlpha = 0xC0
            showBallTimer?.invalidate()
            showBallTimer = nil
            showNewBallInProgress = false
        }
        setNeedsDisplay()
    }

    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return false
    }

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
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
