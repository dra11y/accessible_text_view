//
//  ClassDumpUtility.swift
//  bottom_tabs_ios
//
//  Created by Grushka, Tom on 9/26/22.
//

// Fail in production builds to remind us to remove invocations.
#if DEBUG

    import ObjectiveC

    struct ClassDumpUtility {
        static func dumpClass(klass: AnyClass, ancestors: Bool = true) {
            print(NSStringFromClass(klass))
            print("==============================\nMETHODS:")
            var methodCount: UInt32 = 0
            let methodList = class_copyMethodList(klass, &methodCount)
            for i in 0 ..< Int(methodCount) {
                let unwrapped = methodList![i]
                let name = NSStringFromSelector(method_getName(unwrapped))
                print(name)
            }

            print("==============================\nPROPS")
            var propCount: UInt32 = 0
            let propList = class_copyPropertyList(klass, &propCount)
            for i in 0 ..< Int(propCount) {
                let unwrapped = propList![i]
                guard
                    let name = NSString(utf8String: property_getName(unwrapped))
                else { continue }
                print(name)
            }

            print("==============================\nIVARS")
            var ivarCount: UInt32 = 0
            let ivarList = class_copyIvarList(klass, &ivarCount)
            for i in 0 ..< Int(ivarCount) {
                let unwrapped = ivarList![i]
                guard
                    let ivar = ivar_getName(unwrapped),
                    let name = NSString(utf8String: ivar)
                else { continue }
                print(name)
            }

            if
                ancestors,
                let superKlass = class_getSuperclass(klass),
                superKlass != klass
            {
                dumpClass(klass: superKlass, ancestors: ancestors)
            }
        }

        static func dumpClass(string: String) {
            guard
                let klass = NSClassFromString(string)
            else { fatalError("Cannot get class: \(string)") }
            dumpClass(klass: klass)
        }

        static func dump(_ object: AnyObject) {
            guard
                let klass = object_getClass(object)
            else { fatalError("Cannot get class from object: \(object)") }
            dumpClass(klass: klass)
        }
    }

#endif
