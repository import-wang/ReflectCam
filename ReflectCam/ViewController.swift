import Cocoa
import AVFoundation

class ViewController: NSViewController {
    
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var cameraDevice: AVCaptureDevice?
    var circularView: NSView!
    var shadowView: NSView!
    private var isMirrored: Bool = false
    

    
    override func loadView() {
        // 创建主视图
        view = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 300))
        view.wantsLayer = true
        view.layer = CALayer()
        view.layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCircularView()

        setupCamera()
    }
    
    func setupCircularView() {
        // 创建圆形视图容器
        let circularSize: CGFloat = 250
        let x = (view.bounds.width - circularSize) / 2
        let y = (view.bounds.height - circularSize) / 2
        
        circularView = NSView(frame: CGRect(x: x, y: y, width: circularSize, height: circularSize))
        circularView.wantsLayer = true
        circularView.layer?.masksToBounds = true
        circularView.layer?.cornerRadius = circularSize / 2
        circularView.layer?.backgroundColor = NSColor.black.cgColor
        
        view.addSubview(circularView)
    }
    

    
    func updateCircularLayout() {
        let viewSize = view.bounds.size
        let circularSize: CGFloat = min(viewSize.width, viewSize.height) - 50
        let x = (viewSize.width - circularSize) / 2
        let y = (viewSize.height - circularSize) / 2
        
        // 更新圆形视图
        circularView.frame = CGRect(x: x, y: y, width: circularSize, height: circularSize)
        circularView.layer?.cornerRadius = circularSize / 2
    }
    

    

    

    
    override func viewDidAppear() {
        super.viewDidAppear()
        // 确保窗口在最上层
        view.window?.level = .floating
        view.window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }
    

    
    private func setupCamera() {
        // 请求摄像头权限
        requestCameraPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.configureCaptureSession()
                } else {
                    self?.showPermissionAlert()
                }
            }
        }
    }
    
    func startCamera() {
        guard let captureSession = captureSession else { return }
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.startRunning()
            }
        }
        // 显示圆形视图
        DispatchQueue.main.async {
            self.circularView.isHidden = false
        }
    }
    
    func stopCamera() {
        guard let captureSession = captureSession else { return }
        if captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.stopRunning()
            }
        }
        // 隐藏圆形视图
        DispatchQueue.main.async {
            self.circularView.isHidden = true
        }
    }
    
    private func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(granted)
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    private func configureCaptureSession() {
        captureSession = AVCaptureSession()
        
        // 尝试使用最高质量的预设
        if captureSession?.canSetSessionPreset(.hd1920x1080) == true {
            captureSession?.sessionPreset = .hd1920x1080
            print("✅ 使用1080p高清质量")
        } else if captureSession?.canSetSessionPreset(.hd1280x720) == true {
            captureSession?.sessionPreset = .hd1280x720
            print("✅ 使用720p高清质量")
        } else {
            captureSession?.sessionPreset = .high
            print("✅ 使用标准高质量")
        }
        
        guard let captureSession = captureSession else {
            print("无法创建捕获会话")
            return
        }
        
        // 获取最佳摄像头设备
        var camera: AVCaptureDevice?
        
        // 在macOS上选择最佳可用摄像头
        if let wideCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            camera = wideCamera
            print("✅ 使用广角前置摄像头")
        } else {
            camera = AVCaptureDevice.default(for: .video)
            print("⚠️ 使用默认摄像头")
        }
        
        guard let selectedCamera = camera else {
            print("无法获取摄像头设备")
            return
        }
        
        cameraDevice = selectedCamera
        
        do {
            // 配置摄像头设备以获得最佳质量
            try selectedCamera.lockForConfiguration()
            
            // 设置最佳帧率
            if let format = selectedCamera.activeFormat.videoSupportedFrameRateRanges.first {
                let targetFrameRate = min(60.0, format.maxFrameRate)
                selectedCamera.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(targetFrameRate))
                selectedCamera.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(targetFrameRate))
                print("✅ 设置帧率为 \(targetFrameRate) fps")
            }
            
            // 启用自动对焦（如果支持）
            if selectedCamera.isFocusModeSupported(.continuousAutoFocus) {
                selectedCamera.focusMode = .continuousAutoFocus
                print("✅ 启用连续自动对焦")
            }
            
            // 启用自动曝光（如果支持）
            if selectedCamera.isExposureModeSupported(.continuousAutoExposure) {
                selectedCamera.exposureMode = .continuousAutoExposure
                print("✅ 启用连续自动曝光")
            }
            
            // 启用自动白平衡（如果支持）
            if selectedCamera.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                selectedCamera.whiteBalanceMode = .continuousAutoWhiteBalance
                print("✅ 启用连续自动白平衡")
            }
            
            // 注意：低光增强在macOS上不可用，跳过此设置
            print("ℹ️ 低光增强在macOS上不可用")
            
            selectedCamera.unlockForConfiguration()
            
            // 创建输入
            let input = try AVCaptureDeviceInput(device: selectedCamera)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            } else {
                print("无法添加摄像头输入")
                return
            }
            
        } catch {
            print("配置摄像头设备时出错: \(error.localizedDescription)")
            
            // 如果配置失败，使用基本设置
            do {
                let input = try AVCaptureDeviceInput(device: selectedCamera)
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                }
            } catch {
                print("创建摄像头输入时出错: \(error.localizedDescription)")
                return
            }
        }
        
        // 创建预览层
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        guard let previewLayer = videoPreviewLayer else {
            print("无法创建预览层")
            return
        }
        
        // 配置预览层以获得最佳质量
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = circularView.bounds
        
        // 启用高质量渲染
        if #available(macOS 10.15, *) {
            previewLayer.contentsGravity = .resizeAspectFill
        }
        
        // 优化图层性能
        previewLayer.shouldRasterize = false  // 避免光栅化以保持清晰度
        previewLayer.rasterizationScale = NSScreen.main?.backingScaleFactor ?? 2.0
        
        // 添加预览层到视图
        circularView.layer?.addSublayer(previewLayer)
        
        print("✅ 预览层配置完成，使用高质量渲染")
        
        // 开始捕获
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
    }
    
    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "需要摄像头权限"
        alert.informativeText = "请在系统偏好设置中允许此应用访问摄像头。"
        alert.addButton(withTitle: "打开系统偏好设置")
        alert.addButton(withTitle: "取消")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // 打开系统偏好设置
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        
        // 更新圆形布局
        updateCircularLayout()
        
        // 更新预览层大小
        videoPreviewLayer?.frame = circularView?.bounds ?? view.bounds
    }
    
    deinit {
        captureSession?.stopRunning()
    }
}

// MARK: - 窗口控制扩展
extension ViewController {
    
    func toggleAlwaysOnTop() {
        guard let window = view.window else { return }
        
        if window.level == .floating {
            window.level = .normal
        } else {
            window.level = .floating
        }
    }
    
    func toggleFullScreen() {
        view.window?.toggleFullScreen(nil)
    }
    
    func toggleMirror() {
        isMirrored.toggle()
        updateMirrorTransform()
    }
    
    private func updateMirrorTransform() {
        guard let previewLayer = videoPreviewLayer else { return }
        
        DispatchQueue.main.async {
            if self.isMirrored {
                // 水平镜像反转
                previewLayer.transform = CATransform3DMakeScale(-1, 1, 1)
            } else {
                // 恢复正常
                previewLayer.transform = CATransform3DIdentity
            }
        }
    }
    

}