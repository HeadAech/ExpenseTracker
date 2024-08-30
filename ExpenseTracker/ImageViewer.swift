//
//  ImageViewer.swift
//  ExpenseTracker
//
//  Created by Hubert Klonowski on 30/08/2024.
//

import SwiftUI
import PhotosUI

struct ImageViewer: View {
    
    @State var image: UIImage?
    
    //    @GestureState private var zoom = 1.0
    //
    //    @State private var isDragging:Bool = false
    //    @State private var location:CGPoint?
    
    @State var screenW = 0.0
    @State var scale = 1.0
    @State var lastScale = 0.0
    @State var offset: CGSize = .zero
    @State var lastOffset: CGSize = .zero
    
    var body: some View {
        NavigationStack{
            GeometryReader{ geometry in
                Image(uiImage: image!)
                    .resizable()
                    .scaleEffect(scale < 1 ? 1 : scale)
                    .offset(offset)
                    .scaledToFit()
                    .gesture(
                        MagnificationGesture(minimumScaleDelta: 0)
                            .onChanged({ value in
                                withAnimation(.interactiveSpring()) {
                                    scale = handleScaleChange(value)
                                }
                            })
                            .onEnded({ _ in
                                lastScale = scale
                            })
                            .simultaneously(
                                with: DragGesture(minimumDistance: 0)
                                    .onChanged({ value in
                                        withAnimation(.interactiveSpring()) {
                                            offset = handleOffsetChange(value.translation)
                                        }
                                    })
                                    .onEnded({ _ in
                                        lastOffset = offset
                                    })
                                
                            )
                    )
                //            .resizable()
                //            .scaleEffect(zoom)
                //            .scaledToFit()
                //            .gesture(
                //                MagnifyGesture()
                //                    .updating($zoom) { value, gestureState, transaction in
                //                        gestureState = value.magnification
                //                    }
                //            )
                    .onAppear {
                        screenW = geometry.size.width
                    }
            }
            
            .navigationTitle("Podgląd")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    private func handleScaleChange(_ zoom: CGFloat) -> CGFloat {
        lastScale + zoom - (lastScale == 0 ? 0 : 1)
    }
    
    private func handleOffsetChange(_ offset: CGSize) -> CGSize {
        var newOffset: CGSize = .zero
        
        newOffset.width = offset.width + lastOffset.width
        newOffset.height = offset.height + lastOffset.height
        
        return newOffset
    }
}

#Preview {
    ImageViewer()
}
