import GameController
import SwiftUI

let editor = EditorController.shared

final class EditorController: NSObject {

    static let shared = EditorController()

    let lock = NSLock()

    var focusedControl: ControlModel?

    var controls: [ControlModel] = []
    lazy var view: EditorView = EditorView()

    private func addControlToView(control: ControlModel) {
        controls.append(control)
        view.addSubview(control.button)
        updateFocus(button: control.button)
    }

    public func updateFocus(button: UIButton) {
        view.setNeedsFocusUpdate()
        view.updateFocusIfNeeded()
        for cntrl in controls {
            cntrl.focus(false)
        }

        if let mod = (button as? Element)?.model {
            mod.focus(true)
            focusedControl = mod
        }
    }

    public func switchMode() {
        lock.lock()
        if EditorController.shared.editorMode {
            Toast.showOver(msg: "Keymapping saved")
        } else {
            Toast.showOver(msg: "Click to start keymmaping edit")
        }

        if editorMode {
            KeymapHolder.shared.hide()
            saveButtons()
            view.removeFromSuperview()
            editorMode = false
            mode.show(false)
            focusedControl = nil
        } else {
            mode.show(true)
            editorMode = true
            showButtons()
            screen.window?.addSubview(view)
            view.becomeFirstResponder()
        }
        lock.unlock()
    }

    var editorMode: Bool {
        get { view.isUserInteractionEnabled }
        set { view.isUserInteractionEnabled = newValue}
    }

    public func setKeyCode(_ key: Int) {
        if editorMode {
            focusedControl?.setKeyCodes(keys: [key])
        }
    }

    public func removeControl() {
        controls = controls.filter { $0 !== focusedControl }
        focusedControl?.remove()
    }

    func showButtons() {
        for btn in settings.layout {
            if let ctrl = ControlModel.createControlFromData(data: btn) {
                addControlToView(control: ctrl)
            }
        }
    }

    func saveButtons() {
        var updatedLayout = [[CGFloat]]()
        for model in controls {
            updatedLayout.append(model.save())
        }
        settings.layout = updatedLayout
        controls = []
        view.subviews.forEach { $0.removeFromSuperview() }
    }

    @objc public func addJoystick(_ center: CGPoint) {
        if editorMode {
            addControlToView(control: JoystickModel(data: ControlData(keyCodes: [GCKeyCode.keyW.rawValue,
                                                                                 GCKeyCode.keyS.rawValue,
                                                                                 GCKeyCode.keyA.rawValue,
                                                                                 GCKeyCode.keyD.rawValue],
                                                                      size: 20,
                                                                      xCoord: center.x.relativeX,
                                                                      yCoord: center.y.relativeY)))
        }
    }

    @objc public func addButton(_ toPoint: CGPoint) {
        if editorMode {
            addControlToView(control: ButtonModel(data: ControlData(keyCodes: [-1],
                                                                    size: 5,
                                                                    xCoord: toPoint.x.relativeX,
                                                                    yCoord: toPoint.y.relativeY,
                                                                    parent: nil)))
        }
    }

    @objc public func addRMB(_ toPoint: CGPoint) {
        if editorMode {
            addControlToView(control: RMBModel(data: ControlData(keyCodes: [-2],
                                                                 size: 5,
                                                                 xCoord: toPoint.x.relativeX,
                                                                 yCoord: toPoint.y.relativeY,
                                                                 parent: nil)))
        }
    }

    @objc public func addLMB(_ toPoint: CGPoint) {
        if editorMode {
            addControlToView(control: LMBModel(data: ControlData(keyCodes: [-1],
                                                                 size: 5,
                                                                 xCoord: toPoint.x.relativeX,
                                                                 yCoord: toPoint.y.relativeY,
                                                                 parent: nil)))
        }
    }

    @objc public func addMMB(_ toPoint: CGPoint) {
        if editorMode {
            addControlToView(control: MMBModel(data: ControlData(keyCodes: [-3],
                                                                 size: 5,
                                                                 xCoord: toPoint.x.relativeX,
                                                                 yCoord: toPoint.y.relativeY,
                                                                 parent: nil)))
        }
    }

    @objc public func addMouseArea(_ center: CGPoint) {
        if editorMode {
            addControlToView(control: MouseAreaModel(data: ControlData(size: 25,
                                                                       xCoord: center.x.relativeX,
                                                                       yCoord: center.y.relativeY)))
        }
    }

    func updateEditorText(_ str: String) {
        view.label?.text = str
    }
}

extension UIResponder {
    public var parentViewController: UIViewController? {
        return next as? UIViewController ?? next?.parentViewController
    }
}

class EditorView: UIView {
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        if !isUserInteractionEnabled { return [self] }
        if let btn = editor.focusedControl?.button {
            return [btn]
        }
        return [self]
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        for control in editor.controls {
            control.update()
        }
    }

    init() {
        super.init(frame: .zero)
        self.frame = screen.screenRect
        self.isUserInteractionEnabled = false
        let single = UITapGestureRecognizer(target: self, action: #selector(self.doubleClick(sender:)))
        single.numberOfTapsRequired = 1
        self.addGestureRecognizer(single)
    }

    @objc func doubleClick(sender: UITapGestureRecognizer) {
        for cntrl in editor.controls {
            cntrl.focus(false)
        }
        KeymapHolder.shared.add(sender.location(in: self))
    }

    var label: UILabel?

    @objc func pressed(sender: UIButton!) {
        if !isUserInteractionEnabled { return }
        if let button = sender as? Element {
            if editor.focusedControl?.button == nil || editor.focusedControl?.button != button {
                editor.updateFocus(button: sender)
            }
        }
    }

    @objc func dragged(_ sender: UIPanGestureRecognizer) {
        if !isUserInteractionEnabled { return }
        if let ele = sender.view as? Element {
            if editor.focusedControl?.button == nil || editor.focusedControl?.button != ele {
                editor.updateFocus(button: ele)
            }
            let translation = sender.translation(in: self)
            editor.focusedControl?.move(deltaY: translation.y,
                                        deltaX: translation.x)
            sender.setTranslation(CGPoint.zero, in: self)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
