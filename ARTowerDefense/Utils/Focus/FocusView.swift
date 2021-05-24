//
//  FocusEntity.swift
//  FocusEntity
//
//  Created by Max Cobb on 8/26/19.
//  Copyright © 2019 Max Cobb. All rights reserved.
//

import RealityKit
import ARKit
import Combine

public protocol HasFocusEntity: Entity {}

public extension HasFocusEntity {
  var focus: FocusEntityComponent {
    get { self.components[FocusEntityComponent.self] ?? .classic }
    set { self.components[FocusEntityComponent.self] = newValue }
  }
  var isOpen: Bool {
    get { self.focus.isOpen }
    set { self.focus.isOpen = newValue }
  }
  internal var segments: [FocusEntity.Segment] {
    get { self.focus.segments }
    set { self.focus.segments = newValue }
  }
  var allowedRaycast: ARRaycastQuery.Target {
    get { self.focus.allowedRaycast }
    set { self.focus.allowedRaycast = newValue }
  }
}

@objc public protocol FocusEntityDelegate {
  /// Called when the FocusEntity is now in world space
  @objc optional func toTrackingState()

  /// Called when the FocusEntity is tracking the camera
  @objc optional func toInitializingState()
}

/**
An `Entity` which is used to provide uses with visual cues about the status of ARKit world tracking.
*/
open class FocusEntity: Entity, HasAnchoring, HasFocusEntity {

  public enum FEError: Error {
    case noScene
  }

  private var myScene: Scene? {
    self.arView?.scene
  }

  internal weak var arView: ARView?

  /// For moving the FocusEntity to a whole new ARView
  /// - Parameter view: The destination `ARView`
  public func moveTo(view: ARView) {
    let wasUpdating = self.isAutoUpdating
    self.setAutoUpdate(to: false)
    self.arView = view
    view.scene.addAnchor(self)
    if wasUpdating {
      self.setAutoUpdate(to: true)
    }
  }

  /// Destroy this FocusEntity and its references to any ARViews
  /// Without calling this, your ARView could stay in memory.
  public func destroy() {
    self.setAutoUpdate(to: false)
    self.delegate = nil
    self.arView = nil
    for child in children {
      child.removeFromParent()
    }
    self.removeFromParent()
  }

  private var updateCancellable: Cancellable?
  public private(set) var isAutoUpdating: Bool = false

  public func setAutoUpdate(to autoUpdate: Bool) {
    guard autoUpdate != self.isAutoUpdating,
          !(autoUpdate && self.arView == nil) else {
      return
    }
    self.updateCancellable?.cancel()
    if autoUpdate {
      self.updateCancellable = self.myScene?.subscribe(
        to: SceneEvents.Update.self, self.updateFocusEntity
      )
    }
    self.isAutoUpdating = autoUpdate
  }
  public weak var delegate: FocusEntityDelegate?

  // MARK: - Types
  public enum State: Equatable {
    case initializing
    case tracking(raycastResult: ARRaycastResult, camera: ARCamera?)
  }

  // MARK: - Properties

  /// The most recent position of the focus square based on the current state.
  var lastPosition: SIMD3<Float>? {
    switch state {
    case .initializing: return nil
    case .tracking(let raycastResult, _): return raycastResult.worldTransform.translation
    }
  }

  fileprivate func entityOffPlane(_ raycastResult: ARRaycastResult, _ camera: ARCamera?) {
    self.onPlane = false
    displayOffPlane(for: raycastResult)
  }

  public var state: State = .initializing {
    didSet {
      guard state != oldValue else { return }

      switch state {
      case .initializing:
        if oldValue != .initializing {
          displayAsBillboard()
          self.delegate?.toInitializingState?()
        }
      case let .tracking(raycastResult, camera):
        let stateChanged = oldValue == .initializing
        if stateChanged && self.anchor != nil {
          self.anchoring = AnchoringComponent(.world(transform: Transform.identity.matrix))
        }
        if let planeAnchor = raycastResult.anchor as? ARPlaneAnchor {
          entityOnPlane(for: raycastResult, planeAnchor: planeAnchor)
          currentPlaneAnchor = planeAnchor
        } else {
          entityOffPlane(raycastResult, camera)
          currentPlaneAnchor = nil
        }
        if stateChanged {
          self.delegate?.toTrackingState?()
        }
      }
    }
  }

  public internal(set) var onPlane: Bool = false

  /// Indicates if the square is currently being animated.
  public internal(set) var isAnimating = false

  /// Indicates if the square is currently changing its alignment.
  public internal(set) var isChangingAlignment = false

  /// A camera anchor used for placing the focus entity in front of the camera.
  internal var cameraAnchor: AnchorEntity!

  /// The focus square's current alignment.
  internal var currentAlignment: ARPlaneAnchor.Alignment?

  /// The current plane anchor if the focus square is on a plane.
  public internal(set) var currentPlaneAnchor: ARPlaneAnchor?

  /// The focus square's most recent positions.
  internal var recentFocusEntityPositions: [SIMD3<Float>] = []

  /// The focus square's most recent alignments.
  internal var recentFocusEntityAlignments: [ARPlaneAnchor.Alignment] = []

  /// Previously visited plane anchors.
  internal var anchorsOfVisitedPlanes: Set<ARAnchor> = []

  /// The primary node that controls the position of other `FocusEntity` nodes.
  internal let positioningEntity = Entity()

  internal var fillPlane: ModelEntity?

  public var scaleEntityBasedOnDistance = true {
    didSet {
      if self.scaleEntityBasedOnDistance == false {
        self.scale = .one
      }
    }
  }

  // MARK: - Initialization

  public convenience init(on arView: ARView, style: FocusEntityComponent.Style) {
    self.init(on: arView, focus: FocusEntityComponent(style: style))
  }
  public required init(on arView: ARView, focus: FocusEntityComponent) {
    self.arView = arView
    super.init()
    self.focus = focus
    self.name = "FocusEntity"
    self.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
    self.positioningEntity.synchronization = nil
    self.addChild(self.positioningEntity)

    cameraAnchor = AnchorEntity(.camera)
    cameraAnchor.synchronization = nil
    synchronization = nil
    arView.scene.addAnchor(cameraAnchor)

    // Start the focus square as a billboard.
    displayAsBillboard()
    self.delegate?.toInitializingState?()
    arView.scene.addAnchor(self)
    self.setAutoUpdate(to: true)
    switch self.focus.style {
    case .colored(_, _, _, let mesh):
      let fillPlane = ModelEntity(mesh: mesh)
      self.positioningEntity.addChild(fillPlane)
      self.fillPlane = fillPlane
      self.coloredStateChanged()
    case .classic:
      guard let classicStyle = self.focus.classicStyle else {
        return
      }
      self.setupClassic(classicStyle)
    }
  }

  required public init() {
    fatalError("init() has not been implemented")
  }

  // MARK: - Appearance

  /// Hides the focus square.
  func hide() {
    self.isEnabled = false
//    runAction(.fadeOut(duration: 0.5), forKey: "hide")
  }

  /// Displays the focus square parallel to the camera plane.
  private func displayAsBillboard() {
    self.onPlane = false
    self.currentAlignment = .none
    stateChangedSetup()
  }

    /// Places the focus entity in front of the camera instead of on a plane.
    private func putInFrontOfCamera() {

      // Works better than arView.ray()
      let newPosition = cameraAnchor.convert(position: [0, 0, -1], to: nil)
      recentFocusEntityPositions.append(newPosition)
      updatePosition()
      // --//
      // Make focus entity face the camera with a smooth animation.
      var newRotation = arView?.cameraTransform.rotation ?? simd_quatf()
      newRotation *= simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
      performAlignmentAnimation(to: newRotation)
    }

  /// Called when a surface has been detected.
  private func displayOffPlane(for raycastResult: ARRaycastResult) {
    self.stateChangedSetup()
    let position = raycastResult.worldTransform.translation
    if self.currentAlignment != .none {
      // It is ready to move over to a new surface.
      recentFocusEntityPositions.append(position)
      performAlignmentAnimation(to: raycastResult.worldTransform.orientation)
    } else {
      putInFrontOfCamera()
    }
    updateTransform(raycastResult: raycastResult)
  }

  /// Called when a plane has been detected.
  private func entityOnPlane(
    for raycastResult: ARRaycastResult, planeAnchor: ARPlaneAnchor
  ) {
    self.onPlane = true
    self.stateChangedSetup(newPlane: !anchorsOfVisitedPlanes.contains(planeAnchor))
    anchorsOfVisitedPlanes.insert(planeAnchor)
    let position = raycastResult.worldTransform.translation
    if self.currentAlignment != .none {
      // It is ready to move over to a new surface.
      recentFocusEntityPositions.append(position)
    } else {
      putInFrontOfCamera()
    }
    updateTransform(raycastResult: raycastResult)
  }

  /// Called whenever the state of the focus entity changes
  ///
  /// - Parameter newPlane: If the entity is directly on a plane, is it a new plane to track
  public func stateChanged(newPlane: Bool = false) {
    switch self.focus.style {
    case .colored:
      self.coloredStateChanged()
    case .classic:
      if self.onPlane {
        self.onPlaneAnimation(newPlane: newPlane)
      } else {
        self.offPlaneAniation()
      }
    }
  }

  private func stateChangedSetup(newPlane: Bool = false) {
    guard !isAnimating else { return }
    self.stateChanged(newPlane: newPlane)
  }

  public func updateFocusEntity(event: SceneEvents.Update? = nil) {
    // Perform hit testing only when ARKit tracking is in a good state.
    guard let camera = self.arView?.session.currentFrame?.camera,
      case .normal = camera.trackingState,
      let result = self.smartRaycast()
    else {
      // We should place the focus entity in front of the camera instead of on a plane.
      putInFrontOfCamera()
      self.state = .initializing
      return
    }

    self.state = .tracking(raycastResult: result, camera: camera)
  }
}

internal struct ClassicStyle {
  var color: Material.Color
}

/// When using colored style, first material of a mesh will be replaced with the chosen color
internal struct ColoredStyle {
  /// Color when tracking the surface of a known plane
  var onColor: MaterialColorParameter
  /// Color when tracking an estimated plane
  var offColor: MaterialColorParameter
  /// Color when no surface tracking is achieved
  var nonTrackingColor: MaterialColorParameter
  var mesh: MeshResource
}

public struct FocusEntityComponent: Component {
  public enum Style {
    case classic(color: Material.Color)
    case colored(
      onColor: MaterialColorParameter,
      offColor: MaterialColorParameter,
      nonTrackingColor: MaterialColorParameter,
      mesh: MeshResource = MeshResource.generatePlane(width: 0.1, depth: 0.1)
    )
  }

  let style: Style
  var classicStyle: ClassicStyle? {
    switch self.style {
    case .classic(let color):
      return ClassicStyle(color: color)
    default:
      return nil
    }
  }

  var coloredStyle: ColoredStyle? {
    switch self.style {
    case .colored(let onColor, let offColor, let nonTrackingColor, let mesh):
      return ColoredStyle(
        onColor: onColor, offColor: offColor,
        nonTrackingColor: nonTrackingColor, mesh: mesh
      )
    default:
      return nil
    }
  }

  /// Convenient presets
  public static let classic = FocusEntityComponent(style: .classic(color: #colorLiteral(red: 1, green: 0.8, blue: 0, alpha: 1)))
  public static let plane = FocusEntityComponent(
    style: .colored(
      onColor: .color(.green),
      offColor: .color(.orange),
      nonTrackingColor: .color(Material.Color.red.withAlphaComponent(0.2)),
      mesh: FocusEntityComponent.defaultPlane
    )
  )
  internal var isOpen = true
  internal var segments: [FocusEntity.Segment] = []
  public var allowedRaycast: ARRaycastQuery.Target = .estimatedPlane

  static var defaultPlane = MeshResource.generatePlane(
    width: 0.1, depth: 0.1
  )

  public init(style: Style) {
    self.style = style
    // If the device has LiDAR, then default behaviour is to only allow
    // existing detected planes
    if #available(iOS 13.4, *),
       ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
      self.allowedRaycast = .existingPlaneGeometry
    }
  }
}
internal extension FocusEntity {
  /*
  The focus square consists of eight segments as follows, which can be individually animated.

        s0  s1
        _   _
    s2 |     | s3

    s4 |     | s5
        -   -
        s6  s7
  */
  enum Corner {
    case topLeft // s0, s2
    case topRight // s1, s3
    case bottomRight // s5, s7
    case bottomLeft // s4, s6
  }

  enum Alignment {
    case horizontal // s0, s1, s6, s7
    case vertical // s2, s3, s4, s5
  }

  enum Direction {
    case up, down, left, right

    var reversed: Direction {
      switch self {
      case .up:   return .down
      case .down: return .up
      case .left:  return .right
      case .right: return .left
      }
    }
  }

  class Segment: Entity, HasModel {

    // MARK: - Configuration & Initialization

    /// Thickness of the focus square lines in m.
    static let thickness: Float = 0.018

    /// Length of the focus square lines in m.
    static let length: Float = 0.5  // segment length

    /// Side length of the focus square segments when it is open (w.r.t. to a 1x1 square).
    static let openLength: Float = 0.2

    let corner: Corner
    let alignment: Alignment
    let plane: ModelComponent

    init(name: String, corner: Corner, alignment: Alignment, color: Material.Color) {
      self.corner = corner
      self.alignment = alignment

      switch alignment {
      case .vertical:
        plane = ModelComponent(
          mesh: .generatePlane(width: 1, depth: 1),
          materials: [UnlitMaterial(color: color)]
        )
      case .horizontal:
        plane = ModelComponent(
          mesh: .generatePlane(width: 1, depth: 1),
          materials: [UnlitMaterial(color: color)]
        )
      }
      super.init()

      switch alignment {
      case .vertical:
        self.scale = [Segment.thickness, 1, Segment.length]
      case .horizontal:
        self.scale = [Segment.length, 1, Segment.thickness]
      }
//      self.orientation = .init(angle: .pi / 2, axis: [1, 0, 0])
      self.name = name

//      let material = plane.firstMaterial!
//      material.diffuse.contents = FocusSquare.primaryColor
//      material.isDoubleSided = true
//      material.ambient.contents = UIColor.black
//      material.lightingModel = .constant
//      material.emission.contents = FocusSquare.primaryColor
      model = plane
    }

    required init() {
      fatalError("init() has not been implemented")
    }

    // MARK: - Animating Open/Closed

    var openDirection: Direction {
      switch (corner, alignment) {
      case (.topLeft, .horizontal): return .left
      case (.topLeft, .vertical): return .up
      case (.topRight, .horizontal): return .right
      case (.topRight, .vertical): return .up
      case (.bottomLeft, .horizontal): return .left
      case (.bottomLeft, .vertical): return .down
      case (.bottomRight, .horizontal): return .right
      case (.bottomRight, .vertical): return .down
      }
    }

    func open() {
      if alignment == .horizontal {
        self.scale[0] = Segment.openLength
      } else {
        self.scale[2] = Segment.openLength
      }

      let offset = Segment.length / 2 - Segment.openLength / 2
      updatePosition(withOffset: Float(offset), for: openDirection)
    }

    func close() {
      let oldLength: Float
      if alignment == .horizontal {
        oldLength = self.scale[0]
        self.scale[0] = Segment.length
      } else {
        oldLength = self.scale[2]
        self.scale[2] = Segment.length
      }

      let offset = Segment.length / 2 - oldLength / 2
      updatePosition(withOffset: offset, for: openDirection.reversed)
    }

    private func updatePosition(withOffset offset: Float, for direction: Direction) {
      switch direction {
      case .left:     position.x -= offset
      case .right:    position.x += offset
      case .up:       position.z -= offset
      case .down:     position.z += offset
      }
    }

  }
}
public extension FocusEntity {

  internal func coloredStateChanged() {
    guard let coloredStyle = self.focus.coloredStyle else {
      return
    }
    var endColor: MaterialColorParameter
    if self.state == .initializing {
      endColor = coloredStyle.nonTrackingColor
    } else {
      endColor = self.onPlane ? coloredStyle.onColor : coloredStyle.offColor
    }
    if self.fillPlane?.model?.materials.count == 0 {
        self.fillPlane?.model?.materials = [SimpleMaterial()]
    }
    // Necessary for transparency.
    var modelMaterial = UnlitMaterial(color: .clear)
    modelMaterial.baseColor = endColor
    // Necessary for transparency.
    modelMaterial.tintColor = Material.Color.white.withAlphaComponent(0.995)
    self.fillPlane?.model?.materials[0] = modelMaterial
  }
}

internal extension FocusEntity {

  // MARK: - Configuration Properties

  /// Original size of the focus square in meters. Not currently customizable
  static let size: Float = 0.17

  /// Thickness of the focus square lines in meters. Not currently customizable
  static let thickness: Float = 0.018

  /// Scale factor for the focus square when it is closed, w.r.t. the original size.
  static let scaleForClosedSquare: Float = 0.97

  /// Side length of the focus square segments when it is open (w.r.t. to a 1x1 square).
//  static let sideLengthForOpenSegments: CGFloat = 0.2

  /// Duration of the open/close animation. Not currently used.
  static let animationDuration = 0.7

  /// Color of the focus square fill. Not currently used.
//  static var fillColor = #colorLiteral(red: 1, green: 0.9254901961, blue: 0.4117647059, alpha: 1)

  /// Indicates whether the segments of the focus square are disconnected.
//  private var isOpen = true

  /// List of the segments in the focus square.

  // MARK: - Initialization

  func setupClassic(_ classicStyle: ClassicStyle) {
//    opacity = 0.0
    /*
    The focus square consists of eight segments as follows, which can be individually animated.

        s0  s1
        _   _
    s2 |     | s3

    s4 |     | s5
        -   -
        s6  s7
    */

    let segCorners: [(Corner, Alignment)] = [
      (.topLeft, .horizontal), (.topRight, .horizontal),
      (.topLeft, .vertical), (.topRight, .vertical),
      (.bottomLeft, .vertical), (.bottomRight, .vertical),
      (.bottomLeft, .horizontal), (.bottomRight, .horizontal)
    ]
    self.segments = segCorners.enumerated().map { (index, cornerAlign) -> Segment in
      Segment(
        name: "s\(index)",
        corner: cornerAlign.0,
        alignment: cornerAlign.1,
        color: classicStyle.color
      )
    }

    let sl: Float = 0.5  // segment length
    let c: Float = FocusEntity.thickness / 2 // correction to align lines perfectly
    segments[0].position += [-(sl / 2 - c), 0, -(sl - c)]
    segments[1].position += [sl / 2 - c, 0, -(sl - c)]
    segments[2].position += [-sl, 0, -sl / 2]
    segments[3].position += [sl, 0, -sl / 2]
    segments[4].position += [-sl, 0, sl / 2]
    segments[5].position += [sl, 0, sl / 2]
    segments[6].position += [-(sl / 2 - c), 0, sl - c]
    segments[7].position += [sl / 2 - c, 0, sl - c]

    for segment in segments {
      self.positioningEntity.addChild(segment)
      segment.open()
    }

//    self.positioningEntity.addChild(fillPlane)
    self.positioningEntity.scale = SIMD3<Float>(repeating: FocusEntity.size * FocusEntity.scaleForClosedSquare)

    // Always render focus square on top of other content.
//    self.displayNodeHierarchyOnTop(true)
  }

  // MARK: Animations

  func offPlaneAniation() {
    // Open animation
    guard !isOpen else {
      return
    }
    isOpen = true

    for segment in segments {
      segment.open()
    }
    positioningEntity.scale = .init(repeating: FocusEntity.size)
  }

  func onPlaneAnimation(newPlane: Bool = false) {
    guard isOpen else {
      return
    }
    self.isOpen = false

    // Close animation
    for segment in self.segments {
      segment.close()
    }

    if newPlane {
      // New plane animation not implemented
    }
  }

}

extension FocusEntity {

  // MARK: Helper Methods

  /// Update the position of the focus square.
  internal func updatePosition() {
    // Average using several most recent positions.
    recentFocusEntityPositions = Array(recentFocusEntityPositions.suffix(10))

    // Move to average of recent positions to avoid jitter.
    let average = recentFocusEntityPositions.reduce(
      SIMD3<Float>.zero, { $0 + $1 }
    ) / Float(recentFocusEntityPositions.count)
    self.position = average
  }

  /// Update the transform of the focus square to be aligned with the camera.
  internal func updateTransform(raycastResult: ARRaycastResult) {
    self.updatePosition()

    if state != .initializing {
      updateAlignment(for: raycastResult)
    }
  }

  internal func updateAlignment(for raycastResult: ARRaycastResult) {

    var targetAlignment = raycastResult.worldTransform.orientation

    // Determine current alignment
    var alignment: ARPlaneAnchor.Alignment?
    if let planeAnchor = raycastResult.anchor as? ARPlaneAnchor {
      alignment = planeAnchor.alignment
      // Catching case when looking at ceiling
      if targetAlignment.act([0, 1, 0]).y < -0.9 {
        targetAlignment *= simd_quatf(angle: .pi, axis: [0, 1, 0])
      }
    } else if raycastResult.targetAlignment == .horizontal {
      alignment = .horizontal
    } else if raycastResult.targetAlignment == .vertical {
      alignment = .vertical
    }

    // add to list of recent alignments
    if alignment != nil {
      self.recentFocusEntityAlignments.append(alignment!)
    }

    // Average using several most recent alignments.
    self.recentFocusEntityAlignments = Array(self.recentFocusEntityAlignments.suffix(20))

    let alignCount = self.recentFocusEntityAlignments.count
    let horizontalHistory = recentFocusEntityAlignments.filter({ $0 == .horizontal }).count
    let verticalHistory = recentFocusEntityAlignments.filter({ $0 == .vertical }).count

    // Alignment is same as most of the history - change it
    if alignment == .horizontal && horizontalHistory > alignCount * 3/4 ||
      alignment == .vertical && verticalHistory > alignCount / 2 ||
      raycastResult.anchor is ARPlaneAnchor {
        if alignment != self.currentAlignment ||
          (alignment == .vertical && self.shouldContinueAlignAnim(to: targetAlignment)
        ) {
        isChangingAlignment = true
        self.currentAlignment = alignment
      }
    } else {
      // Alignment is different than most of the history - ignore it
      return
    }

    // Change the focus entity's alignment
    if isChangingAlignment {
      // Uses interpolation.
      // Needs to be called on every frame that the animation is desired, Not just the first frame.
      performAlignmentAnimation(to: targetAlignment)
    } else {
      orientation = targetAlignment
    }
  }

  internal func normalize(_ angle: Float, forMinimalRotationTo ref: Float) -> Float {
    // Normalize angle in steps of 90 degrees such that the rotation to the other angle is minimal
    var normalized = angle
    while abs(normalized - ref) > .pi / 4 {
      if angle > ref {
        normalized -= .pi / 2
      } else {
        normalized += .pi / 2
      }
    }
    return normalized
  }

  internal func getCamVector() -> (position: SIMD3<Float>, direciton: SIMD3<Float>)? {
    guard let camTransform = self.arView?.cameraTransform else {
      return nil
    }
    let camDirection = camTransform.matrix.columns.2
    return (camTransform.translation, -[camDirection.x, camDirection.y, camDirection.z])
  }

  /// - Parameters:
  /// - Returns: ARRaycastResult if an existing plane geometry or an estimated plane are found, otherwise nil.
  internal func smartRaycast() -> ARRaycastResult? {
    // Perform the hit test.
    guard let (camPos, camDir) = self.getCamVector() else {
      return nil
    }
    let rcQuery = ARRaycastQuery(
      origin: camPos, direction: camDir,
      allowing: self.allowedRaycast, alignment: .any
    )
    let results = self.arView?.session.raycast(rcQuery) ?? []

    // 1. Check for a result on an existing plane using geometry.
    if let existingPlaneUsingGeometryResult = results.first(
      where: { $0.target == .existingPlaneGeometry }
    ) {
      return existingPlaneUsingGeometryResult
    }

    // 2. As a fallback, check for a result on estimated planes.
    return results.first(where: { $0.target == .estimatedPlane })
  }

    /// Uses interpolation between orientations to create a smooth `easeOut` orientation adjustment animation.
  internal func performAlignmentAnimation(to newOrientation: simd_quatf) {
    // Interpolate between current and target orientations.
    orientation = simd_slerp(orientation, newOrientation, 0.15)
    // This length creates a normalized vector (of length 1) with all 3 components being equal.
    self.isChangingAlignment = self.shouldContinueAlignAnim(to: newOrientation)
  }

  func shouldContinueAlignAnim(to newOrientation: simd_quatf) -> Bool {
    let testVector = simd_float3(repeating: 1 / sqrtf(3))
    let point1 = orientation.act(testVector)
    let point2 = newOrientation.act(testVector)
    let vectorsDot = simd_dot(point1, point2)
    // Stop interpolating when the rotations are close enough to each other.
    return vectorsDot < 0.999
  }

  /**
  Reduce visual size change with distance by scaling up when close and down when far away.

  These adjustments result in a scale of 1.0x for a distance of 0.7 m or less
  (estimated distance when looking at a table), and a scale of 1.2x
  for a distance 1.5 m distance (estimated distance when looking at the floor).
  */
  internal func scaleBasedOnDistance(camera: ARCamera?) -> Float {
    guard let camera = camera else { return 1.0 }

    let distanceFromCamera = simd_length(self.convert(position: .zero, to: nil) - camera.transform.translation)
    if distanceFromCamera < 0.7 {
      return distanceFromCamera / 0.7
    } else {
      return 0.25 * distanceFromCamera + 0.825
    }
  }
}
