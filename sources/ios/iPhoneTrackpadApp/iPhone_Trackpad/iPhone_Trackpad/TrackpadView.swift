import SwiftUI

struct TrackpadView: View {
    @ObservedObject var viewModel: TrackpadViewModel

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.opacity(0.95).ignoresSafeArea()

                VStack {
                    HStack {
                        Button("設定") {}
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text(viewModel.state.rawValue)
                            Text("感度: \(viewModel.sensitivityPreset)")
                                .font(.caption)
                        }
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                    }
                    .padding()
                    Spacer()
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let ts = Int64(Date().timeIntervalSince1970 * 1000)
                        if value.translation == .zero {
                            viewModel.touchBegan(x: value.location.x, y: value.location.y, tsMs: ts)
                        } else {
                            viewModel.touchMoved(x: value.location.x, y: value.location.y, tsMs: ts)
                        }
                    }
                    .onEnded { value in
                        let ts = Int64(Date().timeIntervalSince1970 * 1000)
                        viewModel.touchEnded(x: value.location.x, y: value.location.y, tsMs: ts)
                    }
            )
            .onAppear {
                _ = geo.size
                viewModel.connect(host: "192.168.0.10", port: 8080)
            }
        }
    }
}
