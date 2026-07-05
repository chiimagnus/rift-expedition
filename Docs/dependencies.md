# Dependencies

## Allowed Runtime Dependencies

- Apple frameworks: SwiftUI, SpriteKit, GameplayKit, Foundation, CoreGraphics, AVFoundation, OSLog.
- SwiftPM package: SKTiled, fixed to commit `9ca740baffcfbeb296a1f5ebc57d0bc2f4bda1fe` from `https://github.com/mfessenden/SKTiled.git`.

## Disallowed For P1

- No ECS library.
- No A* or pathfinding library.
- No JSON Schema library.
- No geometry library.
- No networking, analytics, ads, store, or telemetry SDK.

`Packages/RiftCore` must stay pure Swift logic and must not import SwiftUI, SpriteKit, SKTiled, or OSLog.
