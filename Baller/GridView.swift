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
    let increment = 0.025
    let travelTime = 3.0
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

    let tests = [0, 0, 1, 0,
                 0, 0, 1, 0,
                 0, 0, 1, 0,
                 0, 0, 1, 0,
                 0, 0, 1, 0]

    var continueCombining = false

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
        init(score: Int, point: CGPoint, delta: (Double, Double)) {
            self.score = score
            self.position = point
            self.deltaX = delta.0
            self.deltaY = delta.1
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
        /*for i in 0...ROWS*COLUMNS - 1 {
            balls[i].color = tests[i]
            balls[i].score = numOfColors(balls[i].color)
        }*/
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

    func drawScoreAnimation() {
        var count = 0
        for _ in scoreAnimationData {
            if (round(scoreAnimationData[count].position.x) == round(mainScorePosition.x)) || (round(scoreAnimationData[count].position.y) == round(mainScorePosition.y)) {
                displayScore += scoreAnimationData[count].score// = realScore
                removeScoreElement(scoreAnimationData[count])
                if displayScore > highScore { highScore = displayScore }
                setNeedsDisplay()
                continue
            }
            let scoreStr = "+\(scoreAnimationData[count].score)"
            let finalStr: NSMutableAttributedString = NSMutableAttributedString(string: scoreStr)
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
        animateScoreTimer = Timer.scheduledTimer(timeInterval: increment, target: self, selector: #selector(animateScore), userInfo: nil, repeats: true)
    }

    func calcScore(_ ballScore: Int) {
        realScore += ballScore
    }

    func appendToAnimationArray(idx: Int, score: Int) {
        scoreAnimationData.append(ScoreData(score: score, point: startingPositions[idx], delta: ((increment / travelTime) * (Double(startingPositions[idx].x) - Double(mainScorePosition.x)), (increment / travelTime) * (Double(startingPositions[idx].y) - Double(mainScorePosition.y)))))
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
                        appendToAnimationArray(idx: rightIndex, score: balls[rightIndex].score)
                    } else {
                        calcScore(rightIndex - 1)
                        appendToAnimationArray(idx: rightIndex - 1, score: balls[rightIndex - 1].score)
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
        /*var index = 0
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

                        if !continueCombining {
                            let dataObj = ScoreData(score: balls[index + current].score, point: startingPositions[index + current], delta: ((increment / travelTime) * (Double(startingPositions[index + current].x) - Double(mainScorePosition.x)), (increment / travelTime) * (Double(startingPositions[index + current].y) - Double(mainScorePosition.y))))
                            scoreAnimationData.append(dataObj)
                            savedIndex = scoreAnimationData.firstIndex(of: dataObj)!
                            calcScore(balls[index + current].score)
                            continueCombining = true
                        } else {
                            calcScore(balls[index + last].score)
                            scoreAnimationData[savedIndex].score += balls[index + last].score
                        }
                        //updatePositionScoreArrays(index + current)
                        last += 1
                    //otherwise, merge the multicolor ball, and if the two balls have diff colors, they won't merge
                    } else {
                        mergeMultiColor(idx1: index + current, idx2: index + last)

                        current += 1
                        last = current + 1
                        continueCombining = false
                    }
                }
            }

            continueCombining = false
            index += COLUMNS
        }
        */
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
                        appendToAnimationArray(idx: leftIndex, score: balls[leftIndex].score)
                    } else {
                        calcScore(leftIndex + 1)
                        appendToAnimationArray(idx: leftIndex + 1, score: balls[leftIndex + 1].score)
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
        /*var index = 0
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

                        if !continueCombining {
                            let dataObj = ScoreData(score: balls[index + current].score, point: startingPositions[index + current], delta: ((increment / travelTime) * (Double(startingPositions[index + current].x) - Double(mainScorePosition.x)), (increment / travelTime) * (Double(startingPositions[index + current].y) - Double(mainScorePosition.y))))
                            scoreAnimationData.append(dataObj)
                            savedIndex = scoreAnimationData.firstIndex(of: dataObj)!
                            calcScore(balls[index + current].score)
                            continueCombining = true
                        } else {
                            calcScore(balls[index + last].score)
                            scoreAnimationData[savedIndex].score += balls[index + last].score
                        }
                        //updatePositionScoreArrays(index + current)
                        last -= 1
                    } else {
                        mergeMultiColor(idx1: index + current, idx2: index + last, defaultIdx: index + current)

                        current -= 1
                        last = current - 1
                        continueCombining = false
                    }
                }
            }

            continueCombining = false
            index += COLUMNS
        }*/

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
                        appendToAnimationArray(idx: bottomIndex, score: balls[bottomIndex].score)
                    } else {
                        calcScore(bottomIndex - COLUMNS)
                        appendToAnimationArray(idx: bottomIndex - COLUMNS, score: balls[bottomIndex - COLUMNS].score)
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
        /*var index = 0
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

                        if !continueCombining {
                            let dataObj = ScoreData(score: balls[index + current * COLUMNS].score, point: startingPositions[index + current * COLUMNS], delta: ((increment / travelTime) * (Double(startingPositions[index + current * COLUMNS].x) - Double(mainScorePosition.x)), (increment / travelTime) * (Double(startingPositions[index + current * COLUMNS].y) - Double(mainScorePosition.y))))
                            scoreAnimationData.append(dataObj)
                            savedIndex = scoreAnimationData.firstIndex(of: dataObj)!
                            calcScore(balls[index + current * COLUMNS].score)
                            continueCombining = true
                        } else {
                            calcScore(balls[index + last * COLUMNS].score)
                            scoreAnimationData[savedIndex].score += balls[index + last * COLUMNS].score
                        }
                        //updatePositionScoreArrays(index + current * COLUMNS)
                        last += 1
                    } else {
                        mergeMultiColor(idx1: index + current * COLUMNS, idx2: index + last * COLUMNS, defaultIdx: index + current * COLUMNS)

                        current += 1
                        last = current + 1
                        continueCombining = false
                    }
                }
            }

            continueCombining = false
            index += 1
        }*/

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
                        appendToAnimationArray(idx: topIndex, score: balls[topIndex].score)
                    } else {
                        calcScore(topIndex + COLUMNS)
                        appendToAnimationArray(idx: topIndex + COLUMNS, score: balls[topIndex + COLUMNS].score)
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
        /*var index = 0
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

                        if !continueCombining {
                            let dataObj = ScoreData(score: balls[index + current * COLUMNS].score, point: startingPositions[index + current * COLUMNS], delta: ((increment / travelTime) * (Double(startingPositions[index + current * COLUMNS].x) - Double(mainScorePosition.x)), (increment / travelTime) * (Double(startingPositions[index + current * COLUMNS].y) - Double(mainScorePosition.y))))
                            scoreAnimationData.append(dataObj)
                            savedIndex = scoreAnimationData.firstIndex(of: dataObj)!
                            calcScore(balls[index + current * COLUMNS].score)
                            continueCombining = true
                        } else {
                            calcScore(balls[index + last * COLUMNS].score)
                            scoreAnimationData[savedIndex].score += balls[index + last * COLUMNS].score
                        }
                        //updatePositionScoreArrays(index + current * COLUMNS)
                        last -= 1
                    } else {
                        /*var idx = index + last
                        var savedIndex = idx
                        while idx < (index + current * (COLUMNS - 1)) {
                            if balls[idx + COLUMNS].color == 0 {
                                balls[idx + COLUMNS].color = balls[idx].color
                                balls[idx + COLUMNS].score = balls[idx].score
                                balls[idx].color = 0
                                balls[idx].score = 0
                            }
                            savedIndex = idx + COLUMNS
                            idx += COLUMNS
                        }*/
                        mergeMultiColor(idx1: index + current * COLUMNS, idx2: index + last * COLUMNS, defaultIdx: index + current * COLUMNS)

                        current -= 1
                        last = current - 1
                        continueCombining = false
                    }
                }
            }
            continueCombining = false
            index += 1
        }*/

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
                        appendToAnimationArray(idx: idx1, score: balls[idx1].score)
                    } else {
                        calcScore(score)
                        appendToAnimationArray(idx: idx2, score: score)
                    }
                } else {
                    calcScore(score)
                    appendToAnimationArray(idx: idx2, score: score)
                }
                /*if score > balls[idx1].score {
                    calcScore(balls[idx1].score)
                    appendToAnimationArray(idx: idx1)
                } else {
                    calcScore(score)
                    appendToAnimationArray(idx: idx2)
                }*/
                balls[idx1].score += score
                /*if !continueCombining {
                    calcScore(balls[idx1].score)
                    scoreAnimationData.append(ScoreData(score: balls[idx1].score, point: startingPositions[idx1], delta: ((increment / travelTime) * (Double(startingPositions[idx1].x) - Double(mainScorePosition.x)), (increment / travelTime) * (Double(startingPositions[idx1].y) - Double(mainScorePosition.y)))))
                } else {
                    calcScore(score)
                    scoreAnimationData[savedIndex].score += score
                }*/
                balls[idx2].score -= score
                balls[idx2].color ^= balls[idx1].color
                //scoreAnimationData.append(ScoreData(score: balls[idx1].score, point: startingPositions[idx1], delta: ((increment / travelTime) * (Double(startingPositions[idx1].x) - Double(mainScorePosition.x)), (increment / travelTime) * (Double(startingPositions[idx1].y) - Double(mainScorePosition.y)))))

                //updatePositionScoreArrays(idx1)
            }
        } else if isSingleColor(balls[idx2].color) {
            if ((balls[idx2].color & balls[idx1].color) == balls[idx2].color) {
                score = balls[idx1].score / numOfColors(balls[idx1].color)
                //Only add the smaller score to the total
                if score >= balls[idx2].score {
                    if defaultIdx == idx2 {
                        calcScore(balls[idx2].score)
                        appendToAnimationArray(idx: idx2, score: balls[idx2].score)
                    } else {
                        calcScore(score)
                        appendToAnimationArray(idx: idx1, score: score)
                    }
                } else {
                    calcScore(score)
                    appendToAnimationArray(idx: idx1, score: score)
                }
                /*if score > balls[idx2].score {
                    calcScore(balls[idx2].score)
                    appendToAnimationArray(idx: idx2)
                } else {
                    calcScore(score)
                    appendToAnimationArray(idx: idx1)
                }*/
                balls[idx2].score += score
                //calcScore(balls[idx2].score)
                balls[idx1].score -= score
                balls[idx1].color ^= balls[idx2].color

                //scoreAnimationData.append(ScoreData(score: balls[idx2].score, point: startingPositions[idx2], delta: ((increment / travelTime) * (Double(startingPositions[idx2].x) - Double(mainScorePosition.x)), (increment / travelTime) * (Double(startingPositions[idx2].y) - Double(mainScorePosition.y)))))
                //updatePositionScoreArrays(idx2)
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
            /*path = UIBezierPath(ovalIn: CGRect(x: xx, y: yy, width: xx_stride, height: yy_stride / 2))
            UIColor(hex: color[0]).set()
            path.stroke()
            path.fill()

            path = UIBezierPath(ovalIn: CGRect(x: xx, y: yy + yy_stride / 2, width: xx_stride, height: yy_stride / 2))
            UIColor(hex: color[1]).set()
            path.stroke()
            path.fill()*/
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
            /*
            path = UIBezierPath(ovalIn: CGRect(x: xx, y: yy, width: xx_stride, height: yy_stride / 3))
            UIColor(hex: color[0]).set()
            path.stroke()
            path.fill()

            path = UIBezierPath(ovalIn: CGRect(x: xx, y: yy + yy_stride / 3, width: xx_stride, height: yy_stride / 3))
            UIColor(hex: color[1]).set()
            path.stroke()
            path.fill()

            path = UIBezierPath(ovalIn: CGRect(x: xx, y: yy + yy_stride * 2 / 3, width: xx_stride, height: yy_stride / 3))
            UIColor(hex: color[2]).set()
            path.stroke()
            path.fill()
            */
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
