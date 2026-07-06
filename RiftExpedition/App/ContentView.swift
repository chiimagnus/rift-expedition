import SwiftUI

struct ContentView: View {
    @State private var viewModel = GameSessionViewModel()

    var body: some View {
        GameRootView(viewModel: viewModel)
    }
}
