//
//  Map.swift
//  First Attempt
//
//  Created by Daniel Aragon on 5/22/20.
//  Copyright © 2020 Daniel Aragon. All rights reserved.
//

import Foundation
import RealityKit
import GameplayKit

enum StripOption: String, CaseIterable {
//    case refund
    case upgrade, sell, turret, launcher, barracks, rotateRight, rotateLeft, undo, start
    var key: String {
        return self.rawValue
    }
    var iconImage: UIImage {
        switch self {
        case .upgrade: return #imageLiteral(resourceName: "upgrade")
        case .sell: return #imageLiteral(resourceName: "coins")
        case .turret: return #imageLiteral(resourceName: "tower-turret")
        case .launcher: return #imageLiteral(resourceName: "tower-launcher")
        case .barracks: return #imageLiteral(resourceName: "tower-barracks")
        case .rotateRight: return #imageLiteral(resourceName: "clockwise-rotation")
        case .rotateLeft: return #imageLiteral(resourceName: "anticlockwise-rotation")
        case .undo: return #imageLiteral(resourceName: "cancel")
        case .start: return #imageLiteral(resourceName: "start")
        }
    }
}


enum MapLegend: CaseIterable {
    case neutral, goal, lowerPlacing, higherPlacing, spawn, lowerPath, higherPath, zipLineIn, zipLineOut
}

enum Lifepoints: String, CaseIterable {
    case full, half, low
    static func status(hp: Float) -> Lifepoints {
        switch hp {
        case (0.66...1.00): return .full
        case (0.33...0.65): return .half
        default: return .low
        }
        
    }
    
    var color: UIColor {
        switch self {
        case .full: return .green
        case .half: return .yellow
        case .low: return .red
        }
    }
    var key: String { self.rawValue }
}

enum Direction: CaseIterable {
    case up, down, left, right
    case upright, downright, downleft, upleft
    static var baseMoves: [Direction] {
        return [.up, .down, .left, .right]
    }
    
    var offset: Position {
        switch self {
        case .up: return (0, 1)
        case .down: return (0, -1)
        case .left: return (-1, 0)
        case .right: return (1, 0)
        case .upright: return (1, 1)
        case .downright: return (1, -1)
        case .downleft: return (-1, -1)
        case .upleft : return (-1, 1)
        }
    }
    var angle: Float {
        switch self {
        case .up: return 0
        case .upright: return 1*(.pi)/4
        case .right: return 2*(.pi)/4
        case .downright: return 3*(.pi)/4
        case .down: return 4*(.pi)/4
        case .downleft: return 5*(.pi)/4
        case .left: return 6*(.pi)/4
        case .upleft : return 7*(.pi)/4
        }
    }
    var orientation: simd_quatf {
        return simd_quatf(angle: self.angle, axis: [0, 1, 0])
    }
    func blendDirection(previous: Direction) -> Direction {
        switch (self, previous) {
        case (.up, .right), (.right, .up): return .upright
        case (.right, .down), (.down, .right): return .downright
        case (.down, .left), (.left, .down): return .downleft
        case (.left, .up), (.up, .left): return .upleft
        default: return previous
        }
    }
}

struct GameConfig: Codable {
    var missions: [MissionModel]
    var enciclopedia: Enciclopedia
}

struct Enciclopedia: Codable {
    var towers: [TowerEnciclopedia]
    var creeps: [CreepEnciclopedia]
}

struct TowerEnciclopedia: Codable {
    var image: String
    var type: String
    var damage: String
    var speed: String
    var range: String
    var description: String
}

struct CreepEnciclopedia: Codable {
    var image: String
    var type: String
    var speed: String
    var resistance: String
    var description: String
}

struct MissionModel: Codable {
    var difficulty: Int
    var waves: Int
    var maps: [MapModel]
}

typealias Position = (row: Int, column: Int)
typealias OrientedPosition = (position: Position, direction: Direction, mapLegend: MapLegend)
typealias OrientedCoordinate = (coordinate: SIMD3<Float>, angle: Float, position: Position, mapLegend: MapLegend)

struct MapModel: Codable {
    var matrix: [[Int]]
    var rows: Int
    var columns: Int
    var allPaths = [[OrientedPosition]]()
    var spawns = [Position]()
    var goals = [Position]()

    enum CodingKeys: String, CodingKey {
        case matrix
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        matrix = try values.decode([[Int]].self, forKey: .matrix)
        (rows, columns) = (self.matrix.count, self.matrix.first!.count)
        for (rowIndex, row) in matrix.enumerated() {
            for (columnIndex, column) in row.enumerated() {
                switch MapLegend.allCases[column] {
                case .goal: goals.append((rowIndex, columnIndex))
                case .spawn, .zipLineIn: spawns.append((rowIndex, columnIndex))
                default: break
                }
            }
        }
        for spawn in spawns {
            moveTo((spawn, .down, .spawn), path: [])
        }
    }
    mutating func moveTo(_ orientedPosition: OrientedPosition, path: [OrientedPosition]) {
        var path = path
        let current = orientedPosition.position
        path.append(orientedPosition)
        let mapType = MapLegend.allCases[matrix[current.row][current.column]]
        if [MapLegend.goal, .zipLineOut].contains(mapType) {
            allPaths.append(path.enumerated().map { index, move in
                var move = move
                if index + 1 < path.count {
                    move.direction = path[index + 1].direction.blendDirection(previous: move.direction)
                }
                return move
            })
            return
        } else {
            for direction in Direction.baseMoves {
                let position = Position(current.row + direction.offset.row, current.column + direction.offset.column)
                if position.row >= 0, position.row < rows,
                    position.column >= 0, position.column < columns,
                    !path.contains(where: { previous, _, _ in return (previous.row == position.row && previous.column == position.column) }),
                    [MapLegend.lowerPath, .higherPath, .goal, .zipLineOut].contains(MapLegend.allCases[matrix[position.row][position.column]]) {
                    moveTo((position, direction, MapLegend.allCases[matrix[position.row][position.column]]), path: path)
                } 
            }
        }
    }
    
    func creepPathsCoordinates(at position: Position, diameter: Float) -> [[OrientedCoordinate]] {
        let (rowDistance, columnDistance) = (Float(rows / 2) - diameter, Float(columns / 2) - diameter)
        let pathsPerSpawn = allPaths.filter { path in
            return position == path.first!.position
        }
        return pathsPerSpawn.map { path in
            return path.enumerated().map { (index, move) in
                let (row, column) = move.position
                let x = (Float(row) - rowDistance ) * 0.1
                var y: Float {
                    switch MapLegend.allCases[self.matrix[row][column]] {
                    case .higherPath, .higherPlacing: return 0.1
                    default: return 0.0
                    }
                }
                let z = (Float(column) - columnDistance) * 0.1
                return ([x, y, z], move.direction.angle, move.position, move.mapLegend)
            }
        }
    }
}
