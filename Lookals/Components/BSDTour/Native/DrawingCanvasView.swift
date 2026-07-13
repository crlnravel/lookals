//
//  DrawingCanvasView.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import PencilKit
import SwiftUI

struct DrawingCanvasView: UIViewRepresentable {
    @Binding var drawingData: Data?
    var isEnabled = true

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.delegate = context.coordinator
        canvasView.backgroundColor = .clear
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 6)
        canvasView.isOpaque = false
        canvasView.isUserInteractionEnabled = isEnabled
        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        canvasView.isUserInteractionEnabled = isEnabled

        guard let drawingData, drawingData != context.coordinator.currentDrawingData else {
            return
        }

        if let drawing = try? PKDrawing(data: drawingData) {
            context.coordinator.currentDrawingData = drawingData
            canvasView.drawing = drawing
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(drawingData: $drawingData)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawingData: Data?
        var currentDrawingData: Data?

        init(drawingData: Binding<Data?>) {
            self._drawingData = drawingData
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            let data = canvasView.drawing.dataRepresentation()
            currentDrawingData = data
            drawingData = data
        }
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var drawingData: Data?

        var body: some View {
            DrawingCanvasView(drawingData: $drawingData)
                .frame(width: 300, height: 420)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.primary, lineWidth: 1.5)
                }
                .padding()
                .background(Color(.systemGray5))
        }
    }

    return PreviewHost()
}
