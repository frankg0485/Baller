//
//  SwipeHandler.swift
//  Baller
//
//  Created by Frank Gao on 4/27/19.
//  Copyright © 2019 Frank Gao. All rights reserved.
//

import Foundation

class SwipeHandler {
    private static func calcScore(_ ballScore: Int) {
        realScore += ballScore
    }

    private static func appendToAnimationArray(idx: Int, score: Int, color: Int) {
        let distX = Double(startingPositions[idx].x - mainScorePosition.x)
        let distY = Double(startingPositions[idx].y - mainScorePosition.y)
        let distance = sqrt(pow(distX, 2) + pow(distY, 2))

        scoreAnimationData.append(ScoreData(score: score, point: startingPositions[idx], delta: ((deltaLength / distance) * distX, (deltaLength / distance) * distY), color: color))
    }

    private static func mergeMultiColor(idx1: Int, idx2: Int, defaultIdx: Int) {
        var score = 0
        if GridView.isSingleColor(balls[idx1].color) {
            if ((balls[idx1].color & balls[idx2].color) == balls[idx1].color) {
                score = balls[idx2].score / GridView.numOfColors(balls[idx2].color)
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
        } else if GridView.isSingleColor(balls[idx2].color) {
            if ((balls[idx2].color & balls[idx1].color) == balls[idx2].color) {
                score = balls[idx1].score / GridView.numOfColors(balls[idx1].color)
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

    static func swipeLeft() {
        //starts from the bottom row
        var leftIndex = (ROWS - 1) * COLUMNS
        var rightIndex = ROWS * COLUMNS - 1
        var counter = 0

        func shiftBalls() {
            while (rightIndex + counter) < (leftIndex + COLUMNS - 1) {
                balls[rightIndex + counter].color = balls[rightIndex + counter + 1].color
                balls[rightIndex + counter].score = balls[rightIndex + counter + 1].score
                balls[rightIndex + counter].type = balls[rightIndex + counter + 1].type
                balls[rightIndex + counter].numberOfSwipes = balls[rightIndex + counter + 1].numberOfSwipes
                GridView.clearBall(rightIndex + counter + 1)
                counter += 1
            }
        }

        for _ in 0...ROWS - 1 {
            while rightIndex > leftIndex {
                //find the rightmost ball in the row that has non-white color
                while GridView.checkWhiteBall(rightIndex) && (rightIndex > leftIndex) { rightIndex -= 1 }
                //if there is only one ball on the very left, or there are none in the row, move on to the next row
                if rightIndex == leftIndex { break }
                if GridView.checkWhiteBall(rightIndex - 1) {
                    //if the ball on the left is empty, move all balls left one space
                    //start by shifting current ball onto the left one
                    counter = -1
                    shiftBalls()
                } else if balls[rightIndex - 1].color == balls[rightIndex].color {
                    //if the ball on the left has the same color as this one, combine the two and put it on the left square
                    //Only add the smaller ball score to the total
                    if balls[rightIndex - 1].type == .NORMAL && balls[rightIndex].type == .NORMAL {
                        if balls[rightIndex].score < balls[rightIndex - 1].score {
                            calcScore(rightIndex)
                            appendToAnimationArray(idx: rightIndex, score: balls[rightIndex].score, color: balls[rightIndex].color)
                        } else {
                            calcScore(rightIndex - 1)
                            appendToAnimationArray(idx: rightIndex - 1, score: balls[rightIndex - 1].score, color: balls[rightIndex - 1].color)
                        }
                        balls[rightIndex - 1].score += balls[rightIndex].score
                        GridView.clearBall(rightIndex)
                        //start by shifting the one on the right to the current one
                        counter = 0
                        shiftBalls()
                    }
                } else {
                    switch balls[rightIndex].type {
                    case .NORMAL:
                        mergeMultiColor(idx1: rightIndex, idx2: rightIndex - 1, defaultIdx: rightIndex - 1)
                    case .ROCK:
                        break
                    }
                }
                rightIndex -= 1
            }

            rightIndex -= 1
            leftIndex -= COLUMNS
        }
    }

    static func swipeRight() {
        var rightIndex = COLUMNS - 1
        var leftIndex = 0
        var counter = 0

        func shiftBalls() {
            while (leftIndex - counter) > (rightIndex - (COLUMNS - 1)) {
                balls[leftIndex - counter].color = balls[leftIndex - counter - 1].color
                balls[leftIndex - counter].score = balls[leftIndex - counter - 1].score
                balls[leftIndex - counter].type = balls[leftIndex - counter - 1].type
                balls[leftIndex - counter].numberOfSwipes = balls[leftIndex - counter - 1].numberOfSwipes
                GridView.clearBall(leftIndex - counter - 1)
                counter += 1
            }
        }

        for _ in 0...ROWS - 1 {
            while leftIndex < rightIndex {
                //find the leftmost ball in the row that has non-white color
                while GridView.checkWhiteBall(leftIndex) && (leftIndex < rightIndex) { leftIndex += 1 }
                //if there is only one ball on the very right, or there are none in the row, move on to the next row
                if leftIndex == rightIndex { break }
                if GridView.checkWhiteBall(leftIndex + 1) {
                    //if the ball on the right is empty, move all balls right one space
                    //start by moving the current ball onto the one on the right
                    counter = -1
                    shiftBalls()
                } else if balls[leftIndex + 1].color == balls[leftIndex].color {
                    //if the ball on the right has the same color as this one, combine the two and put it on the right square
                    //Only add the smaller ball score to the total
                    if balls[leftIndex + 1].type == .NORMAL && balls[leftIndex].type == .NORMAL {
                        if balls[leftIndex].score < balls[leftIndex + 1].score {
                            calcScore(leftIndex)
                            appendToAnimationArray(idx: leftIndex, score: balls[leftIndex].score, color: balls[leftIndex].color)
                        } else {
                            calcScore(leftIndex + 1)
                            appendToAnimationArray(idx: leftIndex + 1, score: balls[leftIndex + 1].score, color: balls[leftIndex + 1].color)
                        }
                        balls[leftIndex + 1].score += balls[leftIndex].score
                        GridView.clearBall(leftIndex)
                        //start shifting by moving the left ball onto this one
                        counter = 0
                        shiftBalls()
                    }
                } else {
                    switch balls[leftIndex].type {
                    case .NORMAL:
                        mergeMultiColor(idx1: leftIndex, idx2: leftIndex + 1, defaultIdx: leftIndex + 1)
                    case .ROCK:
                        break
                    }
                }
                leftIndex += 1
            }

            leftIndex += 1
            rightIndex += COLUMNS
        }
    }

    static func swipeTop() {
        var topIndex = 0
        var bottomIndex = COLUMNS * (ROWS - 1)
        var counter = 0

        func shiftBalls() {
            while (bottomIndex + counter * COLUMNS) < (topIndex + COLUMNS * (ROWS - 1)) {
                balls[bottomIndex + counter * COLUMNS].color = balls[bottomIndex + counter * COLUMNS + COLUMNS].color
                balls[bottomIndex + counter * COLUMNS].score = balls[bottomIndex + counter * COLUMNS + COLUMNS].score
                balls[bottomIndex + counter * COLUMNS].type = balls[bottomIndex + counter * COLUMNS + COLUMNS].type
                balls[bottomIndex + counter * COLUMNS].numberOfSwipes = balls[bottomIndex + counter * COLUMNS + COLUMNS].numberOfSwipes
                GridView.clearBall(bottomIndex + counter * COLUMNS + COLUMNS)
                counter += 1
            }
        }

        for _ in 0...COLUMNS - 1 {
            while bottomIndex > topIndex {
                //find the lowest ball in the row that has non-white color
                while GridView.checkWhiteBall(bottomIndex) && (bottomIndex > topIndex) { bottomIndex -= COLUMNS }
                //if there is only one ball on the very top, or there are none in the column, move on to the next column
                if bottomIndex == topIndex { break }
                if GridView.checkWhiteBall(bottomIndex - COLUMNS) {
                    //if the ball on the top is empty, move all balls up one space
                    //start by shifting current ball onto the top one
                    counter = -1
                    shiftBalls()
                } else if balls[bottomIndex - COLUMNS].color == balls[bottomIndex].color {
                    //if the ball on the top has the same color as this one, combine the two and put it on the top square
                    //Only add the smaller ball score to the total
                    if balls[bottomIndex - COLUMNS].type == .NORMAL && balls[bottomIndex].type == .NORMAL {
                        if balls[bottomIndex].score < balls[bottomIndex - COLUMNS].score {
                            calcScore(bottomIndex)
                            appendToAnimationArray(idx: bottomIndex, score: balls[bottomIndex].score, color: balls[bottomIndex].color)
                        } else {
                            calcScore(bottomIndex - COLUMNS)
                            appendToAnimationArray(idx: bottomIndex - COLUMNS, score: balls[bottomIndex - COLUMNS].score, color: balls[bottomIndex - COLUMNS].color)
                        }
                        balls[bottomIndex - COLUMNS].score += balls[bottomIndex].score
                        GridView.clearBall(bottomIndex)
                        //start by shifting the one on the bottom to the current one
                        counter = 0
                        shiftBalls()
                    }
                } else {
                    switch balls[bottomIndex].type {
                    case .NORMAL:
                        mergeMultiColor(idx1: bottomIndex, idx2: bottomIndex - COLUMNS, defaultIdx: bottomIndex - COLUMNS)
                    case .ROCK:
                        break
                    }
                }
                bottomIndex -= COLUMNS
            }

            topIndex += 1
            bottomIndex = topIndex + COLUMNS * (ROWS - 1)
        }
    }

    static func swipeBottom() {
        var bottomIndex = COLUMNS * (ROWS - 1)
        var topIndex = 0
        var counter = 0

        func shiftBalls() {
            while (topIndex - counter * COLUMNS) > (bottomIndex - COLUMNS * (ROWS - 1)) {
                balls[topIndex - counter * COLUMNS].color = balls[topIndex - counter * COLUMNS - COLUMNS].color
                balls[topIndex - counter * COLUMNS].score = balls[topIndex - counter * COLUMNS - COLUMNS].score
                balls[topIndex - counter * COLUMNS].type = balls[topIndex - counter * COLUMNS - COLUMNS].type
                balls[topIndex - counter * COLUMNS].numberOfSwipes = balls[topIndex - counter * COLUMNS - COLUMNS].numberOfSwipes
                GridView.clearBall(topIndex - counter * COLUMNS - COLUMNS)
                counter += 1
            }
        }

        for _ in 0...COLUMNS - 1 {
            while topIndex < bottomIndex {
                //find the topmost ball in the row that has non-white color
                while GridView.checkWhiteBall(topIndex) && (topIndex < bottomIndex) { topIndex += COLUMNS }
                //if there is only one ball on the very top, or there are none in the column, move on to the next column
                if topIndex == bottomIndex { break }
                if GridView.checkWhiteBall(topIndex + COLUMNS) {
                    //if the ball on the bottom is empty, move all balls down one space
                    //start by moving the current ball onto the one on the bottom
                    counter = -1
                    shiftBalls()
                } else if balls[topIndex + COLUMNS].color == balls[topIndex].color {
                    //if the ball on the bottom has the same color as this one, combine the two and put it on the bottom square
                    //Only add the smaller ball score to the total
                    if balls[topIndex + COLUMNS].type == .NORMAL && balls[topIndex].type == .NORMAL {
                        if balls[topIndex].score < balls[topIndex + COLUMNS].score {
                            calcScore(topIndex)
                            appendToAnimationArray(idx: topIndex, score: balls[topIndex].score, color: balls[topIndex].color)
                        } else {
                            calcScore(topIndex + COLUMNS)
                            appendToAnimationArray(idx: topIndex + COLUMNS, score: balls[topIndex + COLUMNS].score, color: balls[topIndex + COLUMNS].color)
                        }
                        balls[topIndex + COLUMNS].score += balls[topIndex].score
                        GridView.clearBall(topIndex)
                        //start shifting by moving the top ball onto this one
                        counter = 0
                        shiftBalls()
                    }
                } else {
                    switch balls[topIndex].type {
                    case .NORMAL:
                        mergeMultiColor(idx1: topIndex, idx2: topIndex + COLUMNS, defaultIdx: topIndex + COLUMNS)
                    case .ROCK:
                        break
                    }
                }
                topIndex += COLUMNS
            }

            bottomIndex += 1
            topIndex = bottomIndex - COLUMNS * (ROWS - 1)
        }
    }
}
