//
//  UIColor+Utils.swift
//  Balizinha
//
//  Created by Bobby Ren on 11/6/19.
//

public enum PannaUI {
    // https://nshipster.com/dark-mode/
    static let darkGreen = UIColor(red: 88/255.0, green: 122/255.0, blue: 103/255.0, alpha: 1)
    static let mediumGreen = UIColor(red: 118.0/255.0, green: 146.0/255.0, blue: 130.0/255.0, alpha: 1)
    static let lightGreen = UIColor(red: 163.0/255.0, green: 180.0/255.0, blue: 172.0/255.0, alpha: 1)
    static let darkRed = UIColor(red: 145.0/255.0, green: 81.0/255.0, blue: 72.0/255.0, alpha: 1)
    static let mediumRed = UIColor(red: 164.0/255.0, green: 113.0/255.0, blue: 10/255.0, alpha: 1)
    static let lightRed = UIColor(red: 192.0/255.0, green: 160.0/255.0, blue: 156.0/255.0, alpha: 1)
    static let darkGray = UIColor(red: 58.0/255.0, green: 58.0/255.0, blue: 60.0/255.0, alpha: 1)
    static let mediumGray = UIColor(red: 93.0/255.0, green: 94.0/255.0, blue: 96.0/255.0, alpha: 1)
    static let lightGray = UIColor(red: 148.0/255.0, green: 148.0/255.0, blue: 150.0/255.0, alpha: 1)
    static let darkBlue = UIColor(red: 37.0/255.0, green: 51.0/255.0, blue: 62.0/255.0, alpha: 1)
    static let mediumBlue = UIColor(red: 62.0/255.0, green: 82.0/255.0, blue: 101.0/255.0, alpha: 1)
    static let lightBlue = UIColor(red: 152.0/255.0, green: 170.0/255.0, blue: 188.0/255.0, alpha: 1)
    static let offWhite = UIColor(red: 217.0/255.0, green: 214.0/255.0, blue: 214.0/255.0, alpha: 1)
}

public extension PannaUI {
    static var navBarTint: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                if traitCollection.userInterfaceStyle == .dark {
                    return PannaUI.lightBlue
                } else {
                    return PannaUI.mediumBlue
                }
            }
        } else {
            return PannaUI.mediumBlue
        }
    }

    static var cellBorder: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                if traitCollection.userInterfaceStyle == .dark {
                    return PannaUI.lightGreen
                } else {
                    return PannaUI.darkGreen
                }
            }
        } else {
            return PannaUI.darkGreen
        }
    }
    
    static var cellText: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                if traitCollection.userInterfaceStyle == .dark {
                    return PannaUI.lightGreen
                } else {
                    return PannaUI.darkGreen
                }
            }
        } else {
            return PannaUI.darkGreen
        }
    }

    static var iconBackground: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                if traitCollection.userInterfaceStyle == .dark {
                    return PannaUI.lightGreen
                } else {
                    return PannaUI.darkGreen
                }
            }
        } else {
            return PannaUI.darkGreen
        }
    }

    static var tableHeaderBackground: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                if traitCollection.userInterfaceStyle == .dark {
                    return PannaUI.darkGray
                } else {
                    return PannaUI.mediumGray
                }
            }
        } else {
            return PannaUI.mediumGray
        }
    }
    
    static var tableHeaderText: UIColor {
        if #available(iOS 13, *) {
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                if traitCollection.userInterfaceStyle == .dark {
                    return PannaUI.mediumRed // TODO
                } else {
                    return PannaUI.offWhite
                }
            }
        } else {
            return PannaUI.offWhite
        }
    }
}
