//
//  Utils.swift
//  First Attempt
//
//  Created by Daniel Aragon on 5/1/20.
//  Copyright © 2020 Daniel Aragon. All rights reserved.
//
import Foundation
import ARKit
import RealityKit

enum Axis {
    case x, y, z
    var matrix: SIMD3<Float> {
        switch self {
        case .x: return [1, 0, 0]
        case .y: return [0, 1, 0]
        case .z: return [0, 0, 1]
        }
    }
}

enum Filter: Int {
    case placings, towers, creeps
    var group: CollisionGroup {
        return CollisionGroup(rawValue: UInt32(rawValue))
    }
}

extension String {
    func camelCaseToSnakeCase() -> String {
        let acronymPattern = "([A-Z]+)([A-Z][a-z]|[0-9])"
        let normalPattern = "([a-z0-9])([A-Z])"
        return self.processCamalCaseRegex(pattern: acronymPattern)?
            .processCamalCaseRegex(pattern: normalPattern)?.lowercased() ?? self.lowercased()
    }
    
    fileprivate func processCamalCaseRegex(pattern: String) -> String? {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)
        return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2")
    }
}

extension Optional {
    var isNil: Bool {
        self == nil
    }
}

extension AnimationPlaybackController {
    func isPlaybackController(output: Scene.Publisher<AnimationEvents.PlaybackCompleted>.Output) -> Bool {
        return self == output.playbackController
    }
}

extension Entity {
    func embeddedModel(at position: SIMD3<Float>) -> ModelBundle {
        let model = ModelEntity()
        let entity = self.clone(recursive: true)
        model.addChild(entity)
        model.position = position
        return ModelBundle(model: model, entity: entity)
    }
    
    func angle(targetPosition: SIMD3<Float>) -> simd_quatf {
        let ca = targetPosition.x - position.x
        let co = targetPosition.z - position.z
        var angle = atan(ca/co)
        if targetPosition.z < position.z {
            angle = angle + .pi
        }
        return simd_quatf(angle: angle, axis: Axis.y.matrix)
    }
}

extension StringProtocol {
    var firstUppercased: String { return prefix(1).uppercased() + dropFirst() }
}

extension float4x4 {
    /// Returns the translation components of the matrix
    func toTranslation() -> SIMD3<Float> {
      return [self[3,0], self[3,1], self[3,2]]
    }
    /// Returns a quaternion representing the
    /// rotation component of the matrix
    func toQuaternion() -> simd_quatf {
        return simd_quatf(self)
    }
}

extension UUID {
    /**
     - Tag: ToRandomColor
    Pseudo-randomly return one of several fixed standard colors, based on this UUID's first four bytes.
    */
    func toRandomColor() -> UIColor {
        var firstFourUUIDBytesAsUInt32: UInt32 = 0
        let data = withUnsafePointer(to: self) {
            return Data(bytes: $0, count: MemoryLayout.size(ofValue: self))
        }
        _ = withUnsafeMutableBytes(of: &firstFourUUIDBytesAsUInt32, { data.copyBytes(to: $0) })

        let colors: [UIColor] = [.red, .green, .blue, .yellow, .magenta, .cyan, .purple,
        .orange, .white]
        
        let randomNumber = Int(firstFourUUIDBytesAsUInt32) % colors.count
        return colors[randomNumber]
    }
}

class CardView: UIView {
    @IBInspectable var cornerRadius: CGFloat = 15
    @IBInspectable var borderWidth: CGFloat = 3
    @IBInspectable var borderColor: UIColor? = UIColor(named: "cellBorder")
    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = cornerRadius
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor?.cgColor
    }
}
