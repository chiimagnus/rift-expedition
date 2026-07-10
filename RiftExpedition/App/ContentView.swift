import Foundation
import SwiftUI

struct ContentView: View {
    @State private var viewModel: GameSessionViewModel

    init() {
        let viewModel = GameSessionViewModel()
#if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-uiState"), arguments.indices.contains(index + 1) {
            viewModel.configureDebugScreen(named: arguments[index + 1])
        }
#endif
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        GameRootView(viewModel: viewModel)
    }
}
