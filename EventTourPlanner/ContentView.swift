import SwiftUI

struct ContentView: View {
    let viewModel: EventListViewModel

    var body: some View {
        EventListView(viewModel: viewModel)
    }
}
