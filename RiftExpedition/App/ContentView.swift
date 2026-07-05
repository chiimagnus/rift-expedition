import SpriteKit
import SwiftUI

struct ContentView: View {
    var body: some View {
        SpriteView(scene: GameScene.makeScene())
            .frame(minWidth: 960, minHeight: 540)
    }
}
