//
//  ViewController.swift
//  ScanQRCodeDemo
//
//  Created by Leon on 12/27/19.
//  Copyright © 2019 Leon. All rights reserved.
//

import UIKit

import AVFoundation

class ViewController: UIViewController {

    // MARK: - Properties

    var session = AVCaptureSession()

    // MARK: - IBOutlets

    @IBOutlet weak var borderViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var borderViewHeightConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureDevice()
    }

    // MARK: - Configurations

    func configureDevice() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            print("没有开启相机权限")
            return
        }
        let screenBounds = UIScreen.main.bounds
        let output = AVCaptureMetadataOutput()
        output.setMetadataObjectsDelegate(self, queue: .main)
        session.addInput(input)
        session.addOutput(output)
        output.metadataObjectTypes = [.qr, .ean13, .ean8, .code128, .code39,
                                      .code93, .code39Mod43, .pdf417, .aztec,
                                      .upce, .interleaved2of5, .itf14, .dataMatrix]

        // 计算可探测区域
        let originWidth = borderViewHeightConstraint.constant
        let originX = (screenBounds.width - borderViewWidthConstraint.constant) / 2
        let originY = (screenBounds.height - borderViewHeightConstraint.constant) / 2
        let scanRect = CGRect(x: originX, y: originY, width: originWidth, height: originWidth)

        // 坐标转换规则
        // 设有效区域坐标: let validRect = CGRect(x, y, w, h)，预览图层的坐标: let preViewRect = CGRect(0, 0, W, H)
        // 那么感兴趣区域坐标: let rectOfInterest = CGRect(y / H, (W - (w + x)) / W, h / H, w / W)
        let destinationX = scanRect.origin.y / screenBounds.height
        let destinationY = (screenBounds.width - (scanRect.width + scanRect.origin.x)) / screenBounds.width
        let destinationWidth = scanRect.height / screenBounds.height
        let destinationHeight = scanRect.width / screenBounds.width

        output.rectOfInterest = CGRect(x: destinationX,
                                       y: destinationY,
                                       width: destinationWidth,
                                       height: destinationHeight)

        /// 输出预览 Layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = screenBounds
        view.layer.insertSublayer(previewLayer, at: 0)

        // 开启探测
        session.startRunning()
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension ViewController: AVCaptureMetadataOutputObjectsDelegate {

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) { // swiftlint:disable:this line_length
        /// 扫描数据
        guard
            let data = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
            let code = data.stringValue else { return }
        session.stopRunning()
        let controller = UIAlertController(title: "Code", message: code, preferredStyle: .alert)
        let continueAction = UIAlertAction(title: "继续扫描", style: .default) { _ in
            self.session.startRunning()
        }
        controller.addAction(continueAction)
        show(controller, sender: nil)
    }
}
