//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

private struct ModeSelectorAndShootViewConstants {
    static let tooltipTopMargin: CGFloat = 13.5
    static let tooltipArrowHeight: CGFloat = 7
    static let tooltipArrowWidth: CGFloat = 15
    static let tooltipBubbleWidth: CGFloat = 18
    static let tooltipBubbleHeight: CGFloat = 12
    static let tooltipCornerRadius: CGFloat = 6
    static let tooltipTextFont: UIFont = KanvasCameraFonts.shared.modeSelectorTooltipFont
    static let selectorYCenterMargin: CGFloat = CameraConstants.optionButtonSize / 2
    static let shootButtonSize: CGFloat = ShootButtonView.buttonMaximumWidth
    static let shootButtonBottomMargin: CGFloat = 14
    static var shootButtonTopMargin: CGFloat {
        return ModeSelectorAndShootViewConstants.shootButtonBottomMargin + ModeSelectorAndShootViewConstants.shootButtonSize
    }
    static let mediaPickerButtonSize: CGFloat = 35
}

/// Protocol to handle mode selector container and capture button user actions
protocol ModeSelectorAndShootViewDelegate: ShootButtonViewDelegate, ModeButtonViewDelegate, MediaPickerButtonViewDelegate {
    /// Function called when the welcome tooltip is dismissed
    func didDismissWelcomeTooltip()
}

/// View that layouts mode selector container and capture button
/// Also communicates capture button interactions
final class ModeSelectorAndShootView: IgnoreTouchesView, EasyTipViewDelegate {

    /// exposed for other classes that need to know the sizing of the buttons
    static let shootButtonSize = ModeSelectorAndShootViewConstants.shootButtonSize
    static let shootButtonBottomMargin = ModeSelectorAndShootViewConstants.shootButtonBottomMargin
    static let shootButtonTopMargin = ModeSelectorAndShootViewConstants.shootButtonTopMargin

    weak var delegate: ModeSelectorAndShootViewDelegate? {
        didSet {
            shootButton.delegate = delegate
            modeSelectorButton.delegate = delegate
            mediaPickerButton.delegate = delegate
        }
    }

    private let settings: CameraSettings
    private let shootButton: ShootButtonView
    private let modeSelectorButton: ModeButtonView
    private let mediaPickerButton: MediaPickerButtonView
    private var tooltip: EasyTipView?
    let modeSelectorView: UIView
    
    
    /// Initializer for the mode selector view
    ///
    /// - Parameter settings: CameraSettings to determine the default and available modes
    init(settings: CameraSettings) {
        modeSelectorButton = ModeButtonView()
        shootButton = ShootButtonView(baseColor: KanvasCameraColors.shared.shootButtonBaseColor)
        mediaPickerButton = MediaPickerButtonView(settings: settings)
        modeSelectorView = UIView()
        self.settings = settings

        super.init(frame: .zero)
        backgroundColor = .clear
        tooltip = createTooltip()
        
        setUpButtons()
    }

    @available(*, unavailable, message: "use init(settings:) instead")
    override init(frame: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }

    @available(*, unavailable, message: "use init(settings:) instead")
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public interface
    
    /// generates a tap gesture on the shutter button
    ///
    /// - Parameter recognizer: the tap gesture recognizer
    func tapShootButton(recognizer: UITapGestureRecognizer) {
        shootButton.generateTap(recognizer: recognizer)
    }
    
    /// generates a longpress gesture on the shutter button
    ///
    /// - Parameter recognizer: the longpress gesture recognizer
    func longPressShootButton(recognizer: UILongPressGestureRecognizer) {
        shootButton.generateLongPress(recognizer: recognizer)
    }
    
    /// configures the UI to the correct mode
    ///
    /// - Parameter selectedMode: the mode to switch the UI to
    func setUpMode(_ selectedMode: CameraMode) {
        modeSelectorButton.setTitle(KanvasCameraStrings.name(for: selectedMode))
        shootButton.configureFor(trigger: triggerFor(selectedMode),
                                 image: KanvasCameraImages.image(for: selectedMode),
                                 timeLimit: KanvasCameraTimes.recordingTime(for: selectedMode, hold: false),
                                 holdTimeLimit: KanvasCameraTimes.recordingTime(for: selectedMode, hold: true))
    }

    /// show or hide the mode button with an animation
    ///
    /// - Parameter show: true to show, false to hide
    func showModeButton(_ show: Bool) {
        let modeSelector = settings.horizontalModeSelector ? modeSelectorView : modeSelectorButton
        if show {
            showViews(shownViews: [modeSelector], hiddenViews: [], animated: true)
        }
        else {
            showViews(shownViews: [], hiddenViews: [modeSelector], animated: true)
        }
    }
    
    /// enables or disables the user interation on the shutter button
    ///
    /// - Parameter enabled: true to enable, false to disable
    func enableShootButtonUserInteraction(_ enabled: Bool) {
        shootButton.enableUserInteraction(enabled)
    }
    
    /// enables or disables the gesture recognizers in the shutter button
    ///
    /// - Parameter enabled: true to enable, false to disable
    func enableShootButtonGestureRecognizers(_ enabled: Bool) {
        shootButton.enableGestureRecognizers(enabled)
    }

    /// shows the tooltip below the mode selector
    func showTooltip() {
        let modeSelector = settings.horizontalModeSelector ? modeSelectorView : modeSelectorButton
        let targetView = settings.shutterButtonTooltip ? shootButton : modeSelector        
        
        if let tooltip = tooltip, !tooltip.isVisible() {
            tooltip.show(animated: true, forView: targetView, withinSuperview: self)
        }
    }
    
    /// dismisses the tooltip below the mode selector
    func dismissTooltip() {
        if let tooltip = tooltip, tooltip.isVisible() {
            tooltip.dismiss()
        }
    }
    
    /// shows or hides the inner circle used for the press effect
    ///
    /// - Parameter show: true to show, false to hide
    func showPressInnerCircle(_ show: Bool) {
        shootButton.showPressInnerCircle(show: show)
    }
    
    /// shows or hides the outer translucent circle used for the press effect
    ///
    /// - Parameter show: true to show, false to hide
    func showPressBackgroundCircle(_ show: Bool) {
        shootButton.showPressBackgroundCircle(show: show)
    }
    
    /// shows or hides the border of the shutter button
    ///
    /// - Parameter show: true to show, false to hide
    func showBorderView(_ show: Bool) {
        shootButton.showBorderView(show: show)
    }
    
    /// shows the trash icon opened
    func openTrash() {
        shootButton.openTrash()
    }
    
    /// shows the trash icon closed
    func closeTrash() {
        shootButton.closeTrash()
    }
    
    /// hides the trash icon
    func hideTrash() {
        shootButton.hideTrash()
    }

    func toggleMediaPickerButton(_ visible: Bool, animated: Bool = true) {
        mediaPickerButton.showButton(visible, animated: animated)
    }

    func setMediaPickerButtonThumbnail(_ image: UIImage) {
        mediaPickerButton.setThumbnail(image)
    }

    func resetMediaPickerButton() {
        mediaPickerButton.reset()
    }

    var thumbnailSize: CGSize {
        return CGSize(width: ModeSelectorAndShootViewConstants.mediaPickerButtonSize, height: ModeSelectorAndShootViewConstants.mediaPickerButtonSize)
    }

    // MARK: - UI Layout

    private func createTooltip() -> EasyTipView {
        var preferences = EasyTipView.Preferences()
        let text: String
        
        if settings.shutterButtonTooltip {
            preferences.drawing.foregroundColor = .black
            preferences.drawing.backgroundColorCollection = KanvasCameraColors.shared.backgroundColors
            preferences.drawing.arrowPosition = .top
            preferences.drawing.arrowWidth = 8.5
            preferences.drawing.arrowHeight = 6
            preferences.drawing.cornerRadius = 23
            preferences.drawing.font = UIFont.boldSystemFont(ofSize: 16)
            preferences.positioning.textHInset = 18
            preferences.positioning.textVInset = 14
            preferences.positioning.margin = 4
            text = NSLocalizedString("Tap and hold to record", comment: "Indicates to the user that they can tap and hold to record")
        }
        else {
            preferences.drawing.foregroundColor = .white
            preferences.drawing.backgroundColorCollection = KanvasCameraColors.shared.backgroundColors
            preferences.drawing.arrowPosition = .top
            preferences.drawing.arrowWidth = ModeSelectorAndShootViewConstants.tooltipArrowWidth
            preferences.drawing.arrowHeight = ModeSelectorAndShootViewConstants.tooltipArrowHeight
            preferences.drawing.cornerRadius = ModeSelectorAndShootViewConstants.tooltipCornerRadius
            preferences.drawing.font = ModeSelectorAndShootViewConstants.tooltipTextFont
            preferences.positioning.textHInset = ModeSelectorAndShootViewConstants.tooltipBubbleWidth
            preferences.positioning.textVInset = ModeSelectorAndShootViewConstants.tooltipBubbleHeight
            preferences.positioning.margin = ModeSelectorAndShootViewConstants.tooltipTopMargin
            text = NSLocalizedString("Tap to switch modes", comment: "Indicates to the user that they can tap a button to switch camera modes")
        }
        
        return EasyTipView(text: text, preferences: preferences, delegate: self)
    }
    
    private func setUpButtons() {
        if settings.horizontalModeSelector {
            setUpModeSelectorView()
        }
        else {
            setUpModeSelector()
        }

        setUpShootButton()
        setUpMediaPickerButton()
    }

    private func setUpModeSelector() {
        addSubview(modeSelectorButton)
        modeSelectorButton.accessibilityIdentifier = "Mode Options Selector Button"

        modeSelectorButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            modeSelectorButton.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor,
                                                        constant: ModeSelectorAndShootViewConstants.selectorYCenterMargin),
            modeSelectorButton.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),
        ])
    }
    
    private func setUpModeSelectorView() {
        addSubview(modeSelectorView)
        modeSelectorView.accessibilityIdentifier = "Mode Options Selector View"
        
        modeSelectorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            modeSelectorView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            modeSelectorView.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),
            modeSelectorView.heightAnchor.constraint(equalToConstant: OptionSelectorView.height),
            modeSelectorView.widthAnchor.constraint(equalTo: safeAreaLayoutGuide.widthAnchor, constant: -140),
        ])
    }

    private func setUpShootButton() {
        addSubview(shootButton)
        shootButton.accessibilityIdentifier = "Shoot Button"

        shootButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            shootButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -ModeSelectorAndShootViewConstants.shootButtonBottomMargin),
            shootButton.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),
            shootButton.heightAnchor.constraint(equalTo: shootButton.widthAnchor),
            shootButton.widthAnchor.constraint(equalToConstant: ModeSelectorAndShootViewConstants.shootButtonSize)
        ])
    }

    private func setUpMediaPickerButton() {
        addSubview(mediaPickerButton)
        mediaPickerButton.translatesAutoresizingMaskIntoConstraints = false
        let guide = UILayoutGuide()
        addLayoutGuide(guide)
        NSLayoutConstraint.activate([
            guide.topAnchor.constraint(equalTo: shootButton.topAnchor),
            guide.bottomAnchor.constraint(equalTo: shootButton.bottomAnchor),
            guide.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            guide.trailingAnchor.constraint(equalTo: shootButton.leadingAnchor),
        ])
        NSLayoutConstraint.activate([
            mediaPickerButton.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
            mediaPickerButton.centerYAnchor.constraint(equalTo: guide.centerYAnchor),
            mediaPickerButton.widthAnchor.constraint(equalToConstant: ModeSelectorAndShootViewConstants.mediaPickerButtonSize),
            mediaPickerButton.heightAnchor.constraint(equalTo: mediaPickerButton.widthAnchor),
        ])
    }

    // MARK: - EasyTipViewDelegate
    
    func easyTipViewDidDismiss(_ tipView: EasyTipView) {
        delegate?.didDismissWelcomeTooltip()
    }
    
    // MARK: - Triggers by mode
    
    private func triggerFor(_ mode: CameraMode) -> CaptureTrigger {
        switch mode.group {
            case .photo: return .tap
            case .gif: return .tapOrHold(animateCircle: true)
            case .video: return .tapOrHold(animateCircle: false)
        }
    }
}
