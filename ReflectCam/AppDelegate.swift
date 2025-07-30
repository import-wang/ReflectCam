import Cocoa
import AVFoundation

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var window: NSWindow!
    var viewController: ViewController!
    var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 创建状态栏项目
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "camera.circle", accessibilityDescription: "摄像头")
            button.action = #selector(toggleCamera)
            button.target = self
        }
        
        // 创建状态栏菜单
        let menu = NSMenu()
        
        let showItem = NSMenuItem(title: "显示摄像头", action: #selector(showCamera), keyEquivalent: "")
        showItem.target = self
        menu.addItem(showItem)
        
        let hideItem = NSMenuItem(title: "关闭摄像头", action: #selector(stopCamera), keyEquivalent: "")
        hideItem.target = self
        menu.addItem(hideItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 添加窗口大小调整菜单
        let sizeSubmenu = NSMenu()
        
        let size200Item = NSMenuItem(title: "小 (200x200)", action: #selector(setWindowSize200), keyEquivalent: "")
        size200Item.target = self
        sizeSubmenu.addItem(size200Item)
        
        let size300Item = NSMenuItem(title: "中 (300x300)", action: #selector(setWindowSize300), keyEquivalent: "")
        size300Item.target = self
        size300Item.state = .on  // 默认选中
        sizeSubmenu.addItem(size300Item)
        
        let size400Item = NSMenuItem(title: "大 (400x400)", action: #selector(setWindowSize400), keyEquivalent: "")
        size400Item.target = self
        sizeSubmenu.addItem(size400Item)
        
        let size500Item = NSMenuItem(title: "超大 (500x500)", action: #selector(setWindowSize500), keyEquivalent: "")
        size500Item.target = self
        sizeSubmenu.addItem(size500Item)
        
        let sizeMenuItem = NSMenuItem(title: "窗口大小", action: nil, keyEquivalent: "")
        sizeMenuItem.submenu = sizeSubmenu
        menu.addItem(sizeMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 添加镜像反转选项
        let mirrorItem = NSMenuItem(title: "镜像反转", action: #selector(toggleMirror), keyEquivalent: "")
        mirrorItem.target = self
        menu.addItem(mirrorItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        statusItem.menu = menu
        
        // 创建圆形窗口
        createCameraWindow()
    }
    
    func createCameraWindow() {
        // 创建无边框圆形窗口
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 300),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        window.hasShadow = false
        window.center()
        
        // 设置窗口可移动但不可调整大小
        window.isMovable = true
        window.isMovableByWindowBackground = true
        
        // 设置窗口始终在最上层
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // 创建视图控制器
        viewController = ViewController()
        window.contentViewController = viewController
        
        // 显示窗口
        window.makeKeyAndOrderFront(nil)
    }
    
    @objc func toggleCamera() {
        if window.isVisible {
            hideCamera()
        } else {
            showCamera()
        }
    }
    
    @objc func showCamera() {
        if window == nil {
            createCameraWindow()
        }
        window.makeKeyAndOrderFront(nil)
        viewController.startCamera()
    }
    
    @objc func hideCamera() {
        window?.orderOut(nil)
    }
    
    @objc func stopCamera() {
        viewController.stopCamera()
    }
    
    @objc func toggleMirror() {
        viewController.toggleMirror()
    }
    

    
    @objc func setWindowSize200() {
        setWindowSize(200)
        updateSizeMenuSelection(200)
    }
    
    @objc func setWindowSize300() {
        setWindowSize(300)
        updateSizeMenuSelection(300)
    }
    
    @objc func setWindowSize400() {
        setWindowSize(400)
        updateSizeMenuSelection(400)
    }
    
    @objc func setWindowSize500() {
        setWindowSize(500)
        updateSizeMenuSelection(500)
    }
    
    func setWindowSize(_ size: CGFloat) {
        guard let window = window else { return }
        
        let currentFrame = window.frame
        let newSize = NSSize(width: size, height: size)
        
        // 计算新的位置，保持窗口居中
        let newOrigin = NSPoint(
            x: currentFrame.origin.x + (currentFrame.size.width - size) / 2,
            y: currentFrame.origin.y + (currentFrame.size.height - size) / 2
        )
        
        let newFrame = NSRect(origin: newOrigin, size: newSize)
        window.setFrame(newFrame, display: true, animate: true)
    }
    
    func updateSizeMenuSelection(_ selectedSize: CGFloat) {
        guard let menu = statusItem.menu else { return }
        
        // 找到窗口大小菜单项
        for item in menu.items {
            if item.title == "窗口大小", let submenu = item.submenu {
                // 清除所有选中状态
                for subItem in submenu.items {
                    subItem.state = .off
                }
                
                // 设置当前选中项
                let targetTitle: String
                switch selectedSize {
                case 200: targetTitle = "小 (200x200)"
                case 300: targetTitle = "中 (300x300)"
                case 400: targetTitle = "大 (400x400)"
                case 500: targetTitle = "超大 (500x500)"
                default: targetTitle = "中 (300x300)"
                }
                
                for subItem in submenu.items {
                    if subItem.title == targetTitle {
                        subItem.state = .on
                        break
                    }
                }
                break
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}