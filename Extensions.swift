import Foundation
import UIKit

extension NSObject {
    class var className: String {
        return String(describing: self)
    }

    var className: String {
        return type(of: self).className
    }
}

public struct SwiftyExtension<Base> {
    public let base: Base
}

public protocol SwiftyExtensionCompatible {
    associatedtype CompatibleType
    static var ss: SwiftyExtension<CompatibleType>.Type { get }
    var ss: SwiftyExtension<CompatibleType> { get }
}

public extension SwiftyExtensionCompatible {
    public static var ss: SwiftyExtension<Self>.Type {
        return SwiftyExtension<Self>.self
    }

    public var ss: SwiftyExtension<Self> {
        return SwiftyExtension(base: self)
    }
}

extension UIView: SwiftyExtensionCompatible {}
extension UIViewController: SwiftyExtensionCompatible {}
extension UIDevice: SwiftyExtensionCompatible {}
extension UserDefaults: SwiftyExtensionCompatible {}
extension UIImage: SwiftyExtensionCompatible {}

extension SwiftyExtension where Base == UIView {
    public static func instance(fromNibNamed nibName: String, withOwner ownerOrNil: Any?, options: [AnyHashable: Any]? = nil) -> UIView {
        let nib = UINib(nibName: nibName, bundle: nil)
        guard let view = nib.instantiate(withOwner: ownerOrNil, options: options).first as? UIView else {
            fatalError("Failed to load a UIView from \(nibName).xib")
        }
        return view
    }
}

extension SwiftyExtension where Base: UIView {
    public static func instance(withOwner ownerOrNil: Any?, options: [AnyHashable: Any]? = nil) -> Base {
        func instantiateHelper<T: UIView>(withOwner ownerOrNil: Any?, options: [AnyHashable: Any]? = nil) -> T {
            let nibName = T.className
            let nib = UINib(nibName: nibName, bundle: nil)
            guard let view = nib.instantiate(withOwner: ownerOrNil, options: options).first as? T else {
                fatalError("Failed to load xib file for \(nibName)")
            }
            return view
        }
        return instantiateHelper(withOwner: ownerOrNil, options: options)
    }

    @discardableResult
    public func addShadow(color: CGColor, offset: CGSize, opacity: Float, radius: CGFloat) -> Base {
        base.layer.shadowColor = color
        base.layer.shadowOffset = offset
        base.layer.shadowOpacity = opacity
        base.layer.shadowRadius = radius
        return base
    }

    public func addSubviewWithPinningEdges(_ view: UIView, insets: UIEdgeInsets = .zero) {
        base.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.ss.pinToSuperView(withInsets: insets)
    }

    public enum Edge {
        case top, bottom, leading, trailing
    }

    @discardableResult
    public func pinEdgeToSuperView(_ edge: Edge, inset: CGFloat = 0) -> NSLayoutConstraint {
        assert(!base.translatesAutoresizingMaskIntoConstraints)
        guard let superView = base.superview else {
            assertionFailure("view does not have a superview.")
            return NSLayoutConstraint()
        }
        let constraint: NSLayoutConstraint
        switch edge {
        case .top:
            constraint = base.topAnchor.constraint(equalTo: superView.topAnchor, constant: inset)
        case .bottom:
            constraint = base.bottomAnchor.constraint(equalTo: superView.bottomAnchor, constant: -inset)
        case .leading:
            constraint = base.leadingAnchor.constraint(equalTo: superView.leadingAnchor, constant: inset)
        case .trailing:
            constraint = base.trailingAnchor.constraint(equalTo: superView.trailingAnchor, constant: -inset)
        }
        constraint.isActive = true
        return constraint
    }

    @discardableResult
    public func pinToSuperView(withInsets insets: UIEdgeInsets = .zero, excluding: [Edge] = []) -> [NSLayoutConstraint] {
        guard let _ = base.superview else {
            assertionFailure("view does not have a superview.")
            return []
        }

        let edgeInsets: [Edge: CGFloat] = [
            .top: insets.top,
            .bottom: insets.bottom,
            .leading: insets.left,
            .trailing: insets.right,
        ]

        return edgeInsets
            .filter { edge, _ in !excluding.contains(edge) }
            .map { edge, inset in pinEdgeToSuperView(edge, inset: inset) }
    }

    @discardableResult
    @available(iOS, deprecated: 11.0, message: "Use pinToSafeAreaEdgeOfSuperView")
    public func pinToSafeAreaEdgeOfSuperViewCompat(withInsets insets: UIEdgeInsets = .zero, excluding: [Edge] = []) -> [NSLayoutConstraint] {
        if #available(iOS 11, *) {
            let excludingSafeAreaEdge: [SafeAreaEdge] = excluding.map { edge in
                switch edge {
                case .top: return .safeTop
                case .bottom: return .safeBottom
                case .leading: return .safeLeading
                case .trailing: return .safeTrailing
                }
            }
            return pinToSafeAreaEdgeOfSuperView(withInsets: insets, excluding: excludingSafeAreaEdge)
        } else {
            return pinToSuperView(withInsets: insets, excluding: excluding)
        }
    }

    @available(iOS 11, *)
    public enum SafeAreaEdge {
        case safeTop, safeBottom, safeLeading, safeTrailing
    }

    @available(iOS 11, *)
    @discardableResult
    public func pinSafeAreaEdgeToSuperView(_ safeAreaEdge: SafeAreaEdge, inset: CGFloat = 0) -> NSLayoutConstraint {
        assert(!base.translatesAutoresizingMaskIntoConstraints)
        guard let superView = base.superview else {
            assertionFailure("view does not have a superview.")
            return NSLayoutConstraint()
        }
        let constraint: NSLayoutConstraint
        switch safeAreaEdge {
        case .safeTop:
            constraint = base.topAnchor.constraint(equalTo: superView.safeAreaLayoutGuide.topAnchor, constant: inset)
        case .safeBottom:
            constraint = base.bottomAnchor.constraint(equalTo: superView.safeAreaLayoutGuide.bottomAnchor, constant: -inset)
        case .safeLeading:
            constraint = base.leadingAnchor.constraint(equalTo: superView.safeAreaLayoutGuide.leadingAnchor, constant: inset)
        case .safeTrailing:
            constraint = base.trailingAnchor.constraint(equalTo: superView.safeAreaLayoutGuide.trailingAnchor, constant: -inset)
        }
        constraint.isActive = true
        return constraint
    }

    @available(iOS 11, *)
    @discardableResult
    public func pinToSafeAreaEdgeOfSuperView(withInsets insets: UIEdgeInsets = .zero, excluding: [SafeAreaEdge] = []) -> [NSLayoutConstraint] {
        guard let _ = base.superview else {
            assertionFailure("view does not have a superview.")
            return []
        }

        let safeEdgeInsets: [SafeAreaEdge: CGFloat] = [
            .safeTop: insets.top,
            .safeBottom: insets.bottom,
            .safeLeading: insets.left,
            .safeTrailing: insets.right,
        ]

        return safeEdgeInsets
            .filter { safeEdge, _ in !excluding.contains(safeEdge) }
            .map { safeEdge, inset in pinSafeAreaEdgeToSuperView(safeEdge, inset: inset) }
    }

    @discardableResult
    public func constrainSize(to size: CGSize) -> [NSLayoutConstraint] {
        let height = base.heightAnchor.constraint(equalToConstant: size.height)
        let width = base.widthAnchor.constraint(equalToConstant: size.width)
        height.isActive = true
        width.isActive = true
        return [width, height]
    }

    @discardableResult
    public func centerInSuperView() -> [NSLayoutConstraint] {
        guard let superView = base.superview else {
            assertionFailure("view does not have a superview.")
            return []
        }

        let x = base.centerXAnchor.constraint(equalTo: superView.centerXAnchor)
        let y = base.centerYAnchor.constraint(equalTo: superView.centerYAnchor)
        x.isActive = true
        y.isActive = true
        return [x, y]
    }
}

extension SwiftyExtension where Base: UITableView {
    public func registerCell<T: UITableViewCell>(_ cellClass: T.Type, usingNib: Bool) {
        let className = T.className
        if usingNib {
            let nib = UINib(nibName: className, bundle: nil)
            base.register(nib, forCellReuseIdentifier: className)
        } else {
            base.register(T.self, forCellReuseIdentifier: className)
        }
    }

    public func dequeueCell<T: UITableViewCell>(for indexPath: IndexPath) -> T {
        let className = T.className
        guard let cell = base.dequeueReusableCell(withIdentifier: className, for: indexPath) as? T else {
            fatalError("Failed to dequeue cell of \(className)")
        }
        return cell
    }
}

extension SwiftyExtension where Base: UICollectionView {
    public func registerCell<T: UICollectionViewCell>(_ cellClass: T.Type, usingNib: Bool) {
        let className = T.className
        if usingNib {
            let nib = UINib(nibName: className, bundle: nil)
            base.register(nib, forCellWithReuseIdentifier: className)
        } else {
            base.register(T.self, forCellWithReuseIdentifier: className)
        }
    }

    public func dequeueCell<T: UICollectionViewCell>(for indexPath: IndexPath) -> T {
        let className = T.className
        guard let cell = base.dequeueReusableCell(withReuseIdentifier: className, for: indexPath) as? T else {
            fatalError("Failed to dequeue cell of \(className)")
        }
        return cell
    }
}

extension SwiftyExtension where Base: UIViewController {
    public static func instantiate(fromStoryboardNamed storyboardName: String) -> Base {
        func instantiateHelper<T: UIViewController>(storyboardName: String) -> T {
            let className = T.className
            let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
            guard let viewController = storyboard.instantiateViewController(withIdentifier: className) as? T else {
                fatalError("Failed to instantiate \(className) from \(storyboardName).storyboard")
            }
            return viewController
        }
        return instantiateHelper(storyboardName: storyboardName)
    }

    public static func instantiateInitial(fromStoryboardNamed storyboardName: String) -> Base {
        func instantiateHelper<T: UIViewController>(storyboardName: String) -> T {
            let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
            guard let viewController = storyboard.instantiateInitialViewController() as? T else {
                fatalError("Failed to instantiateInitialViewController from \(storyboardName).storyboard")
            }
            return viewController
        }
        return instantiateHelper(storyboardName: storyboardName)
    }
}

extension SwiftyExtension where Base == UIAlertController {
    public static func alert(title: String? = nil, message: String? = nil) -> AlertControllerHelper {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        return AlertControllerHelper(alertController: alertController)
    }

    public static func sheet(title: String? = nil, message: String? = nil) -> AlertControllerHelper {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        return AlertControllerHelper(alertController: alertController)
    }

    public static func info(presentIn viewController: UIViewController, title: String? = nil, message: String? = nil) {
        UIAlertController.ss.alert(title: title, message: message)
            .add(action: .ok)
            .present(in: viewController)
    }
}

public struct AlertControllerHelper {
    private let alertController: UIAlertController
    init(alertController: UIAlertController) {
        self.alertController = alertController
    }

    public enum AlertAction {
        case `default`(title: String, handler: ((UIAlertAction) -> Void)?)
        case cancel(title: String, handler: ((UIAlertAction) -> Void)?)
        case destructive(title: String, handler: ((UIAlertAction) -> Void)?)
        case ok
    }

    public func add(action: AlertAction) -> AlertControllerHelper {
        let alertAction: UIAlertAction
        switch action {
        case let .default(title, handler):
            alertAction = UIAlertAction(title: title, style: .default, handler: handler)
        case let .cancel(title, handler):
            alertAction = UIAlertAction(title: title, style: .cancel, handler: handler)
        case let .destructive(title, handler):
            alertAction = UIAlertAction(title: title, style: .destructive, handler: handler)
        case .ok:
            alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        }
        alertController.addAction(alertAction)
        return self
    }

    public func present(in viewController: UIViewController) {
        if alertController.preferredStyle == .actionSheet {
            assert(alertController.popoverPresentationController?.sourceView != nil)
        }
        viewController.present(alertController, animated: true, completion: nil)
    }
}

extension SwiftyExtension where Base == UIDevice {
    public static var modelIdentifier: String {
        var size: Int = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
    }

    public static var isSimulator: Bool {
        return ["i386", "x86_64"].contains(modelIdentifier)
    }

    public static var isPhone: Bool {
        return modelIdentifier.hasPrefix("iPhone")
    }

    public static var osVersion: String {
        return "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
    }
}

public final class UserDefaultsKey<UserDefaultsValueType>: UserDefaultsKeys, RawRepresentable {
    public typealias RawValue = String
    private var _rawValue: RawValue

    public var rawValue: RawValue {
        return _rawValue
    }

    public convenience init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }

    public init(rawValue: RawValue) {
        _rawValue = rawValue
    }
}

public class UserDefaultsKeys {
}

extension SwiftyExtension where Base == UserDefaults {
    private static var standardUserDefaults: UserDefaults {
        return UserDefaults.standard
    }

    public static func removeObject<T>(for key: UserDefaultsKey<T>) {
        standardUserDefaults.removeObject(forKey: key.rawValue)
    }

    public static func get(for key: UserDefaultsKey<String>) -> String {
        return standardUserDefaults.string(forKey: key.rawValue) ?? ""
    }

    public static func get(for key: UserDefaultsKey<Int>) -> Int {
        return standardUserDefaults.integer(forKey: key.rawValue)
    }

    public static func get(for key: UserDefaultsKey<Float>) -> Float {
        return standardUserDefaults.float(forKey: key.rawValue)
    }

    public static func get(for key: UserDefaultsKey<Double>) -> Double {
        return standardUserDefaults.double(forKey: key.rawValue)
    }

    public static func get(for key: UserDefaultsKey<Bool>) -> Bool {
        return standardUserDefaults.bool(forKey: key.rawValue)
    }

    public static func get(for key: UserDefaultsKey<[String: Any]>) -> [String: Any] {
        return standardUserDefaults.dictionary(forKey: key.rawValue) ?? [:]
    }

    public static func set(_ value: String, for key: UserDefaultsKey<String>) {
        standardUserDefaults.set(value, forKey: key.rawValue)
    }

    public static func set(_ value: Int, for key: UserDefaultsKey<Int>) {
        standardUserDefaults.set(value, forKey: key.rawValue)
    }

    public static func set(_ value: Float, for key: UserDefaultsKey<Float>) {
        standardUserDefaults.set(value, forKey: key.rawValue)
    }

    public static func set(_ value: Double, for key: UserDefaultsKey<Double>) {
        standardUserDefaults.set(value, forKey: key.rawValue)
    }

    public static func set(_ value: Bool, for key: UserDefaultsKey<Bool>) {
        standardUserDefaults.set(value, forKey: key.rawValue)
    }

    public static func set(_ value: [String: Any], for key: UserDefaultsKey<[String: Any]>) {
        standardUserDefaults.set(value, forKey: key.rawValue)
    }
}

extension SwiftyExtension where Base == UIImage {
    public static func coloredImage(color: UIColor, size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        guard let context = UIGraphicsGetCurrentContext() else {
            assertionFailure("Cannot get context")
            return nil
        }
        context.setFillColor(color.cgColor)
        let rect = CGRect(origin: .zero, size: size)
        context.fill(rect)
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        UIGraphicsEndImageContext()
        return image
    }
}

extension UIView {
    @IBInspectable
    var iCornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }
}
