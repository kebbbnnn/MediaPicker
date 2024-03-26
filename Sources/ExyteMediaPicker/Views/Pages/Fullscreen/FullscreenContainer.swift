//
//  Created by Alex.M on 09.06.2022.
//

import Foundation
import SwiftUI

struct FullscreenContainer: View {

    @EnvironmentObject private var selectionService: SelectionService
    @Environment(\.mediaPickerTheme) private var theme

    @ObservedObject var keyboardHeightHelper = KeyboardHeightHelper.shared

    @Binding var isPresented: Bool
    @Binding var currentFullscreenMedia: Media?
    let assetMediaModels: [AssetMediaModel]
    @State var selection: AssetMediaModel.ID
    var selectionParamsHolder: SelectionParamsHolder
    var shouldDismiss: ()->()
    var onDone: SimpleClosure?

    @State var playButton: AnyView? = nil
    
    private var selectedMediaModel: AssetMediaModel? {
        assetMediaModels.first { $0.id == selection }
    }

    private var selectionServiceIndex: Int? {
        guard let selectedMediaModel = selectedMediaModel else {
            return nil
        }
        return selectionService.index(of: selectedMediaModel)
    }
    
    var body: some View {
        TabView(selection: $selection) {
            ForEach(assetMediaModels, id: \.id) { assetMediaModel in
                FullscreenCell(viewModel: FullscreenCellViewModel(mediaModel: assetMediaModel), playButtonType: .exportable({ playButton = $0 }))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tag(assetMediaModel.id)
                    .ignoresSafeArea()
                    .gesture((selectionParamsHolder.selectionLimit ?? 0) > 1 ? nil : DragGesture())
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background {
            theme.main.fullscreenPhotoBackground
                .ignoresSafeArea()
        }
        .overlay(alignment: .bottom) {
            controlsOverlay
        }
        .onAppear {
            if let selectedMediaModel {
                currentFullscreenMedia = Media(source: selectedMediaModel)
            }
        }
        .onDisappear {
            currentFullscreenMedia = nil
        }
        .onChange(of: selection) { newValue in
            if let selectedMediaModel {
                currentFullscreenMedia = Media(source: selectedMediaModel)
            }
        }
        .onTapGesture {
            if keyboardHeightHelper.keyboardDisplayed {
                dismissKeyboard()
            } else {
                if let selectedMediaModel = selectedMediaModel, selectedMediaModel.mediaType == .image {
                    selectionService.onSelect(assetMediaModel: selectedMediaModel)
                }
            }
        }
    }

    var controlsOverlay: some View {
        HStack {
            Button("Cancel") {
                isPresented = false
            }
            .padding([.horizontal, .bottom], 20)
            /*Image(systemName: "xmark")
                .resizable()
                .frame(width: 20, height: 20)
                .padding([.horizontal, .bottom], 20)
                .contentShape(Rectangle())
                .onTapGesture {
                    isPresented = false
                }*/

            Spacer()
            
            if let playButton {
                playButton
                    .padding([.horizontal, .bottom], 20)
            }
            
            Spacer()

            if let selectedMediaModel = selectedMediaModel {
                if selectionParamsHolder.selectionLimit == 1 {
                    Button("Choose") {
                        selectionService.onSelect(assetMediaModel: selectedMediaModel)
                        selectionService.removeAll(update: false)
                        shouldDismiss()
                        onDone?()
                    }
                    .padding([.horizontal, .bottom], 20)
                } else {
                    SelectIndicatorView(index: selectionServiceIndex, isFullscreen: true, canSelect: selectionService.canSelect(assetMediaModel: selectedMediaModel), selectionParamsHolder: selectionParamsHolder)
                        .padding([.horizontal, .bottom], 20)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectionService.onSelect(assetMediaModel: selectedMediaModel)
                        }
                }
            }
        }
        .padding(.vertical)
        .padding(.vertical)
        .foregroundStyle(theme.selection.fullscreenTint)
        .background(Color(uiColor: .black).opacity(0.6))
    }
}
