import SwiftUI

@main
struct iPhoneTrackpadApp: App {
    var body: some Scene {
        WindowGroup {
            TrackpadView(viewModel: TrackpadViewModel())
        }
    }
}
