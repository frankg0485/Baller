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

enum BallType {
    case NORMAL
    case ROCK
    case BOMB
}

struct Ball: Equatable {
    var color: Int
    var score: Int
    var type: BallType
    var numberOfSwipes: Int

    init(_ type: BallType) {
        self.score = 0
        self.color = 0
        self.type = type
        numberOfSwipes = 0
    }
}

struct ScoreData: Equatable {
    var score: Int
    var position: CGPoint
    var deltaX: Double
    var deltaY: Double
    lazy var ballDiameter: Double = {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return 25
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            return 75
        }
        return 0
    }()
    var color: Int

    init(score: Int, point: CGPoint, delta: (Double, Double), color: Int) {
        self.score = score
        self.position = point
        self.deltaX = delta.0
        self.deltaY = delta.1
        self.color = color
    }
}

let deltaLength = 4.0
let COLUMNS = 4
let ROWS = 5
var balls: [Ball] = []
var scoreAnimationData = [ScoreData]()
var realScore = 0
var numberOfMoves = 0
var startingPositions = [CGPoint]()
//This is set in drawScore()
var mainScorePosition = CGPoint(x: 0, y: 0)

class GridView: UIView, ModalHandler, UIPopoverPresentationControllerDelegate {
    var X_OFF: Double = 0
    let MAX_NEW_BALLS = 2
    let START_NUM = 4
    lazy var FONT_H: Double = {
        return Double(frame.width / 6)
    }()
    var x_stride: Double = 0
    var y_stride: Double = 0

    var mRadius: Double = 0
    var mCenterX: Double = 0
    var mCenterY: Double = 0
    var mW: Double = 0
    var mH: Double = 0

    var bombBallTimer: Timer? = nil
    var secondsUntilExplode = 10

    var animateScoreTimer: Timer? = nil
    var showBallTimer: Timer? = nil
    var scoreTime: Double = 0

    //This is set in the init
    var timerSpeed = 0.0

    var showNewBallAlpha: UInt32 = 0
    var showNewBallInProgress = false
    var newBallCount = 0

    var newBallIndex: [Int] = []
    var savedIndex = 0

    var displayScore = 0
    var highScore = SavedData.getHighScore()

    var once = false
    var redrawBalls = true

    let tests = [0, 0, 0, 0,
                 0, 0, 0, 0,
                 0, 0, 0, 0,
                 0, 0, 0, 0,
                 1, 1, 1, 1]
    let PADDING: Double = 5

    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    //var aalpha = 0x00000000
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        // Drawing code
        drawScore(rect)
        setSizeVars()
        drawGrid()
        drawScoreAnimation()
        drawBalls()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        gridInit()
    }

    func modalDismissed() {
        gridInit()
        setNeedsDisplay()
    }

    func gridInit() {
        realScore = 0
        numberOfMoves = 0
        displayScore = 0
        once = false
        redrawBalls = true

        setSizeVars()
        setUpGestures()

        balls = Array(repeating: Ball(.NORMAL), count: ROWS * COLUMNS)
        newBallIndex = Array(repeating: 0, count: MAX_NEW_BALLS)
        scoreAnimationData = [ScoreData]()
        startingPositions = Array(repeating: CGPoint(x: 0, y: 0), count: ROWS * COLUMNS)

        timerSpeed = getTimerSpeed()
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
            balls[i].score = GridView.numOfColors(balls[i].color)
        }*/
    }

    func getTimerSpeed() -> Double {
        //765.1888655750291 -> iphone 6 distance between opposite corners
        return Double((0.01*765.1888655750291) / sqrt(pow(UIScreen.main.bounds.width, 2) + pow(UIScreen.main.bounds.height, 2)) * 2)
        //0.001 * 765.1888655750291 = x * (distance between screen corners)
    }

    func drawScore(_ rect: CGRect) {
        let fontSize = 40/1336 * frame.height
        /*let textAttributes = [
            NSAttributedStringKey.font : UIFont.systemFont(ofSize: CGFloat(FONT_H / 2)),
            NSAttributedStringKey.foregroundColor : UIColor.red
        ]*/
        let scoreStr: NSMutableAttributedString = NSMutableAttributedString(string: "SCORE: \(displayScore)")
        /*scoreStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: NSRange(0...1))
        scoreStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.green, range: NSRange(2...3))
        scoreStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.blue, range: NSRange(4...5))*/
        scoreStr.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: CGFloat(fontSize)), range: NSMakeRange(0, scoreStr.length))
        var halfLen = scoreStr.attributedSubstring(from: NSRange(location: 0, length: 6)).size().width / 2
        scoreStr.attributedSubstring(from: NSRange(location: 0, length: 6)).draw(at: CGPoint(x: rect.maxX / 3 - halfLen, y: 50))
        halfLen = scoreStr.attributedSubstring(from: NSRange(location: 7, length: scoreStr.length - 7)).size().width / 2
        mainScorePosition = CGPoint(x: rect.maxX / 3 - halfLen, y: 100)
        scoreStr.attributedSubstring(from: NSRange(location: 7, length: scoreStr.length - 7)).draw(at: mainScorePosition)

        let highScoreStr: NSMutableAttributedString = NSMutableAttributedString(string: "HIGH SCORE: \(highScore)")
        /*print(scoreStr, highScoreStr)
        highScoreStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: NSRange(0...2))
        highScoreStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.green, range: NSRange(3...6))
        highScoreStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.blue, range: NSRange(7...10))*/
        highScoreStr.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: CGFloat(fontSize)), range: NSMakeRange(0, highScoreStr.length))
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

    //TODO: remove elements later
    func drawScoreAnimation() {
        var count = -1
        var indexesToBeRemoved: [Int] = []
        for _ in scoreAnimationData {
            count += 1
            if abs(scoreAnimationData[count].position.x - mainScorePosition.x) < 20 && abs(scoreAnimationData[count].position.y - mainScorePosition.y) < 20 {
                displayScore += scoreAnimationData[count].score// = realScore
                if displayScore > highScore { highScore = displayScore }
                indexesToBeRemoved.append(count)
                //setNeedsDisplay()
                continue
            }
            let scoreStr = "\(scoreAnimationData[count].score)"
            let finalStr: NSMutableAttributedString = NSMutableAttributedString(string: scoreStr)
            finalStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.black, range: NSRange(0..<scoreStr.count))
            if UIDevice.current.userInterfaceIdiom == .phone {
                finalStr.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: UIFont.systemFontSize), range: NSRange(0..<scoreStr.count))
            } else if UIDevice.current.userInterfaceIdiom == .pad {
                finalStr.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: UIFont.systemFontSize * 2), range: NSRange(0..<scoreStr.count))
            }

            drawSmallBall(index: count, strSize: finalStr.size())

            finalStr.draw(at: CGPoint(x: scoreAnimationData[count].position.x, y: scoreAnimationData[count].position.y))
        }

        for index in indexesToBeRemoved.reversed() {
            scoreAnimationData.remove(at: index)
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
        if isGameOver() {
            if SavedData.getHighScore() < highScore { SavedData.setHighScore(score: highScore) }

            if !redrawBalls && scoreAnimationData.isEmpty {
                animateScoreTimer?.invalidate()
                animateScoreTimer = nil
                showBallTimer?.invalidate()
                showBallTimer = nil

                usleep(250000)
                presentGameOver()
            } else { redrawBalls = false }
        }
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
        vc.preferredContentSize = CGSize(width: 300/375 * frame.width, height: 400/667 * frame.height)
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
            if GridView.checkWhiteBall(i) {
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

            if GridView.isSingleColor(balls[i].color) {
                if ((belowColor & balls[i].color) > 0) || ((rightColor & balls[i].color) > 0) { return false }
            } else {
                for color in [belowColor, rightColor] {
                    if GridView.isSingleColor(color) {
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

    static func checkWhiteBall(_ index: Int) -> Bool { return balls[index].color == 0 && balls[index].type == .NORMAL }

    static func clearBall(_ index: Int) {
        balls[index].color = 0
        balls[index].score = 0
        balls[index].type = .NORMAL
        balls[index].numberOfSwipes = 0
    }

    func addRockBall(_ index: Int) {
        balls[index].type = .ROCK
        balls[index].color = 0
        balls[index].score = 0
    }

    func addBombBall(_ index: Int) {
        balls[index].type = .BOMB
        balls[index].color = 0
        balls[index].score = 0
        bombBallTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(animateBombBall), userInfo: nil, repeats: true)
    }

    func locateBombLocation() -> Int {
        for ii in 0..<(ROWS * COLUMNS) {
            if (balls[ii].type == .BOMB) {
                return ii
            }
        }
        return 0
    }

    func explodeBombBall(_ bombLocation: Int) {
        if ((bombLocation % 4 > 0 && bombLocation % 4 < 3) && (bombLocation > COLUMNS - 1 && bombLocation < ROWS * COLUMNS - COLUMNS)) {
            GridView.clearBall(bombLocation - COLUMNS - 1)
            GridView.clearBall(bombLocation - COLUMNS)
            GridView.clearBall(bombLocation - COLUMNS + 1)
            GridView.clearBall(bombLocation - COLUMNS + 3)
            GridView.clearBall(bombLocation + 1)
            GridView.clearBall(bombLocation + 3)
            GridView.clearBall(bombLocation + COLUMNS)
            GridView.clearBall(bombLocation + COLUMNS + 1)
        } else if (bombLocation % COLUMNS == 0) {
            GridView.clearBall(bombLocation - COLUMNS)
            GridView.clearBall(bombLocation - COLUMNS + 1)
            GridView.clearBall(bombLocation + 1)
            GridView.clearBall(bombLocation + COLUMNS)
            GridView.clearBall(bombLocation + COLUMNS + 1)
        } else if (bombLocation % COLUMNS == COLUMNS - 1) {
            GridView.clearBall(bombLocation - COLUMNS)
            GridView.clearBall(bombLocation - COLUMNS - 1)
            GridView.clearBall(bombLocation - 1)
            GridView.clearBall(bombLocation + COLUMNS - 1)
            GridView.clearBall(bombLocation + COLUMNS)
        } else if (bombLocation > 0 && bombLocation < COLUMNS - 1) {
            GridView.clearBall(bombLocation - 1)
            GridView.clearBall(bombLocation + 1)
            GridView.clearBall(bombLocation + COLUMNS - 1)
            GridView.clearBall(bombLocation + COLUMNS)
            GridView.clearBall(bombLocation + COLUMNS + 1)
        } else if (bombLocation > ROWS * (COLUMNS - 1) && bombLocation < ROWS * COLUMNS - 1) {
            GridView.clearBall(bombLocation - 1)
            GridView.clearBall(bombLocation - COLUMNS - 1)
            GridView.clearBall(bombLocation - COLUMNS)
            GridView.clearBall(bombLocation - COLUMNS + 1)
            GridView.clearBall(bombLocation + 1)
        } else if (bombLocation == 0) {
            GridView.clearBall(bombLocation + 1)
            GridView.clearBall(bombLocation + COLUMNS)
            GridView.clearBall(bombLocation + COLUMNS + 1)
        } else if (bombLocation == COLUMNS - 1) {
            GridView.clearBall(bombLocation - 1)
            GridView.clearBall(bombLocation + COLUMNS)
            GridView.clearBall(bombLocation + COLUMNS - 1)
        } else if (bombLocation == (ROWS * COLUMNS) - COLUMNS) {
            GridView.clearBall(bombLocation + 1)
            GridView.clearBall(bombLocation - COLUMNS)
            GridView.clearBall(bombLocation - COLUMNS + 1)
        } else if (bombLocation == ROWS * COLUMNS - 1) {
            GridView.clearBall(bombLocation - 1)
            GridView.clearBall(bombLocation - COLUMNS)
            GridView.clearBall(bombLocation - COLUMNS - 1)
        }
    }

    @objc func animateBombBall() {
        let index = locateBombLocation()

        secondsUntilExplode -= 1;
        if (secondsUntilExplode == 0) {
            secondsUntilExplode = 10
            explodeBombBall(index)
            GridView.clearBall(index)
            bombBallTimer?.invalidate()
            bombBallTimer = nil
        }
        setNeedsDisplay()
    }

    func incrementBallSwipes() {
        var x = 0
        for _ in balls {
            balls[x].numberOfSwipes += 1
            x += 1
        }
    }

    func checkRockBall() {
        var x = 0
        for _ in balls {
            if balls[x].type == .ROCK {
                if balls[x].numberOfSwipes == 15 {
                    GridView.clearBall(x)
                }
            }
            x += 1
        }
    }

    @objc func onSwipeLeft() {
        showBallTimer?.invalidate()
        showBallTimer = nil

        SwipeHandler.swipeLeft()
        numberOfMoves += 1

        incrementBallSwipes()
        checkRockBall()
        addRandomBall()
        setNeedsDisplay()
    }

    @objc func onSwipeRight() {
        showBallTimer?.invalidate()
        showBallTimer = nil

        SwipeHandler.swipeRight()
        numberOfMoves += 1

        incrementBallSwipes()
        checkRockBall()
        addRandomBall()
        setNeedsDisplay()
    }

    @objc func onSwipeTop() {
        showBallTimer?.invalidate()
        showBallTimer = nil

        SwipeHandler.swipeTop()
        numberOfMoves += 1

        incrementBallSwipes()
        checkRockBall()
        addRandomBall()
        setNeedsDisplay()
    }

    @objc func onSwipeBottom() {
        showBallTimer?.invalidate()
        showBallTimer = nil

        SwipeHandler.swipeBottom()
        numberOfMoves += 1

        incrementBallSwipes()
        checkRockBall()
        addRandomBall()
        setNeedsDisplay()
    }

    static func isSingleColor(_ color_code: Int) -> Bool {
        return GridView.numOfColors(color_code) == 1
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
        if UIDevice.current.userInterfaceIdiom == .phone {
            y_stride = Double((mH * 2/3) / Double(ROWS))//(mH * (428.75 / 647)) / Double(ROWS)
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            y_stride = Double((mH * 5/6) / Double(ROWS))
        }

        if x_stride > y_stride {
            x_stride = y_stride
            X_OFF = (mW - Double(COLUMNS) * y_stride) / 2
        } else {
            y_stride = x_stride
        }

        var x: Double = X_OFF
        var y: Double = mH - Double(ROWS) * y_stride - PADDING * 2//Y_OFF

        let path = UIBezierPath(rect: CGRect(x: x - PADDING, y: y - PADDING, width: mW - 2 * x + PADDING * 2, height: mH - y))
        path.close()
        UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1).set()
        path.fill()

        for _ in 0...ROWS - 1 {
            for _ in 0...COLUMNS - 1 {
                let path2 = UIBezierPath(rect: CGRect(x: x + PADDING, y: y + PADDING, width: x_stride - 2 * PADDING, height: y_stride - 2 * PADDING))
                path2.close()
                UIColor.white.set()
                path2.fill()
                x += x_stride
            }
            x = X_OFF
            y += y_stride
        }

        /*for _ in 0...ROWS {
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: mW - X_OFF, y: y))
            y -= y_stride
        }

        for _ in 0...COLUMNS {
            path.move(to: CGPoint(x: x, y: y/*Y_OFF*/))
            path.addLine(to: CGPoint(x: x, y: y - y_stride * Double(ROWS)))// * (218.75 / 647)))
            x += x_stride
        }*/
    }

    func drawBall(x: Double, y: Double, score: Int, color_code: Int, alpha: UInt32, type: BallType) {
        if color_code == 0  && type == .NORMAL { return }

        let xx = x + PADDING + 5
        let yy = y + PADDING + 5
        let xx_stride = x_stride - 2 * PADDING - 10
        let yy_stride = y_stride - 2 * PADDING - 10

        let center = CGPoint(x: xx + xx_stride / 2, y: yy + yy_stride / 2)
        let radius = CGFloat(xx_stride / 2)

        let textAttributes = [
            NSAttributedString.Key.font : UIFont.systemFont(ofSize: CGFloat(FONT_H / 2)),
            NSAttributedString.Key.foregroundColor : UIColor.white
        ]

        switch type {
        case .ROCK:
            var arc = UIBezierPath()
            arc = UIBezierPath(ovalIn: CGRect(x: xx, y: yy, width: xx_stride, height: yy_stride))
            UIColor.black.set()
            arc.stroke()
            arc.fill()
        case.NORMAL:
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
        case .BOMB:
            var arc = UIBezierPath()
            arc = UIBezierPath(ovalIn: CGRect(x: xx, y: yy, width: xx_stride, height: yy_stride))

            if secondsUntilExplode <= 3 {
                UIColor.red.set()
            } else {
                UIColor.yellow.set()
            }
            arc.stroke()
            arc.fill()

            let text_width = Double(String(secondsUntilExplode).size(withAttributes: textAttributes).width)
            String(secondsUntilExplode).draw(at: CGPoint(x: xx + xx_stride / 2 - text_width / 2, y: yy + yy_stride / 2 - FONT_H / 4), withAttributes: textAttributes)
        }
    }

    func drawBalls() {
        var alpha: UInt32 = 0xff000000
        for ii in 0...((ROWS * COLUMNS) - 1) {
            alpha = 0xC0000000

            let iiDivideColumns = (Double(ii) / Double(COLUMNS)).rounded(.towardZero)
            let x = Double(ii).truncatingRemainder(dividingBy: Double(COLUMNS)) * x_stride + X_OFF
            let y = mH - Double(ROWS) * y_stride + (iiDivideColumns.truncatingRemainder(dividingBy: Double(ROWS)) * y_stride) - PADDING * 2
            startingPositions[ii] = CGPoint(x: x, y: y)

            if GridView.checkWhiteBall(ii) { continue }
            if showNewBallInProgress && (newBallCount > 0) {
                for jj in 0...newBallCount - 1 {
                    if newBallIndex[jj] == ii {
                        alpha = showNewBallAlpha << 24
                        break
                    }
                }
            }
            drawBall(x: x, y: y, score: balls[ii].score, color_code: balls[ii].color, alpha: alpha, type: balls[ii].type)
        }
    }

    static func numOfColors(_ color_code: Int) -> Int {
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
            if GridView.checkWhiteBall(start) {
                balls[start].color = Int(arc4random_uniform(7) + 1)
                balls[start].score = GridView.numOfColors(balls[start].color)
                balls[start].numberOfSwipes = 0

                newBallIndex[count] = start

                count += 1
                if (count == MAX_NEW_BALLS) { break }
                else if (numberOfMoves % 20 == 0) {
                    addRockBall(start)
                    break
                } else if (numberOfMoves % 10 == 0) {
                    addBombBall(start)
                }
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
