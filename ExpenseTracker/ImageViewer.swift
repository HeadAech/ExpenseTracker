//
//  ImageViewer.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 30/08/2024.
//

import SwiftUI
import PhotosUI
//
//struct ImageViewer: View {
//    @Environment(\.dismiss) private var dismiss
//    @State var image: UIImage?
//    
//    //    @GestureState private var zoom = 1.0
//    //
//    //    @State private var isDragging:Bool = false
//    //    @State private var location:CGPoint?
//    
//    @State var screenW = 0.0
//    @State var scale = 1.0
//    @State var lastScale = 0.0
//    @State var offset: CGSize = .zero
//    @State var lastOffset: CGSize = .zero
//    
//    var body: some View {
//        NavigationStack{
//            GeometryReader{ geometry in
//                Image(uiImage: image!)
//                    .resizable()
//                    .scaleEffect(scale < 1 ? 1 : scale)
//                    .offset(offset)
//                    .scaledToFit()
//                    .gesture(
//                        MagnificationGesture(minimumScaleDelta: 0)
//                            .onChanged({ value in
//                                withAnimation(.interactiveSpring()) {
//                                    scale = handleScaleChange(value)
//                                }
//                            })
//                            .onEnded({ _ in
//                                lastScale = scale
//                            })
//                            .simultaneously(
//                                with: DragGesture(minimumDistance: 0)
//                                    .onChanged({ value in
//                                        withAnimation(.interactiveSpring()) {
//                                            offset = handleOffsetChange(value.translation)
//                                        }
//                                    })
//                                    .onEnded({ _ in
//                                        lastOffset = offset
//                                    })
//                                
//                            )
//                    )
//                //            .resizable()
//                //            .scaleEffect(zoom)
//                //            .scaledToFit()
//                //            .gesture(
//                //                MagnifyGesture()
//                //                    .updating($zoom) { value, gestureState, transaction in
//                //                        gestureState = value.magnification
//                //                    }
//                //            )
//                    .onAppear {
//                        screenW = geometry.size.width
//                    }
//            }
//            .toolbar {
//                ToolbarItem(placement: .cancellationAction) {
//                    Button {
//                        dismiss()
//                    } label: {
//                        Text("CANCEL_STRING")
//                    }
//                }
//            }
//            .navigationTitle("PREVIEW_STRING")
//            .navigationBarTitleDisplayMode(.inline)
//        }
//    }
//    private func handleScaleChange(_ zoom: CGFloat) -> CGFloat {
//        lastScale + zoom - (lastScale == 0 ? 0 : 1)
//    }
//    
//    private func handleOffsetChange(_ offset: CGSize) -> CGSize {
//        var newOffset: CGSize = .zero
//        
//        newOffset.width = offset.width + lastOffset.width
//        newOffset.height = offset.height + lastOffset.height
//        
//        return newOffset
//    }
//}

public struct ImageViewer: View {

    @Environment(\.dismiss) private var dismiss
    
    let image: Image

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1

    @State private var offset: CGPoint = .zero
    @State private var lastTranslation: CGSize = .zero
    
    @State private var anchor: UnitPoint = .center

    public init(image: Image) {
        self.image = image
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale, anchor: anchor)
                    .offset(x: offset.x, y: offset.y)
                    .gesture(makeDragGesture(size: proxy.size))
                    .gesture(makeMagnificationGesture(size: proxy.size))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
        }
        .overlay(alignment: .topTrailing) {
            closeButton
        }
    }
    
    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.headline)
        }
        .buttonStyle(.bordered)
        .clipShape(Circle())
        .padding()
    }

    private func makeMagnificationGesture(size: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                anchor = value.startAnchor
                
                let delta = value.magnification / lastScale
                lastScale = value.magnification

                // To minimize jittering
                if abs(1 - delta) > 0.01 {
                    scale *= delta
                }
            }
            .onEnded { _ in
                lastScale = 1
//                if scale < 1 {
//                    withAnimation {
//                        scale = 1
//                    }
//                }
//                adjustMaxOffset(size: size)
                withAnimation {
                    scale = 1
                }
            }
    }

    private func makeDragGesture(size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let diff = CGPoint(
                    x: value.translation.width - lastTranslation.width,
                    y: value.translation.height - lastTranslation.height
                )
                offset = .init(x: offset.x + diff.x, y: offset.y + diff.y)
                lastTranslation = value.translation
            }
            .onEnded { _ in
                adjustMaxOffset(size: size)
            }
    }

    private func adjustMaxOffset(size: CGSize) {
        let maxOffsetX = (size.width * (scale - 1)) / 2
        let maxOffsetY = (size.height * (scale - 1)) / 2

        var newOffsetX = offset.x
        var newOffsetY = offset.y

        if abs(newOffsetX) > maxOffsetX {
            newOffsetX = maxOffsetX * (abs(newOffsetX) / newOffsetX)
        }
        if abs(newOffsetY) > maxOffsetY {
            newOffsetY = maxOffsetY * (abs(newOffsetY) / newOffsetY)
        }

        let newOffset = CGPoint(x: newOffsetX, y: newOffsetY)
        if newOffset != offset {
            withAnimation {
                offset = newOffset
            }
        }
        self.lastTranslation = .zero
    }
}
//
//#Preview {
//    ImageViewer()
//}
