import SwiftUI
import AVFoundation
import AudioToolbox


struct QRScannerView: UIViewControllerRepresentable {
    var onFound: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    class Coordinator: NSObject, ScannerViewControllerDelegate {
        let parent: QRScannerView
        private var hasScanned = false

        init(parent: QRScannerView) {
            self.parent = parent
        }

        func didFind(code: String) {
            guard !hasScanned else { return }
            hasScanned = true
            print("📸 Código QR detectado: \(code)")
            DispatchQueue.main.async {
                self.parent.onFound(code)
            }
        }
    }
}


protocol ScannerViewControllerDelegate: AnyObject {
    func didFind(code: String)
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: ScannerViewControllerDelegate?
    private let captureSession = AVCaptureSession()

    private let logoImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "AppLogo1")) // Asegúrate de tener AppLogo1 en Assets
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let instructionLabel: PaddedLabel = {
        let label = PaddedLabel()
        label.text = "Escanea el código QR de la máquina para mostrarte como usarla."
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.numberOfLines = 2
        label.backgroundColor = UIColor.black.withAlphaComponent(0.5) // fondo difuminado
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let scanFrameView: UIView = {
        let view = UIView()
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 2
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let laserLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.8)
        view.layer.cornerRadius = 2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var laserTopConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSession()
        setupOverlay()
    }

    private func configureSession() {
        guard let videoDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoInput) else { return }

        captureSession.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()
        guard captureSession.canAddOutput(metadataOutput) else { return }

        captureSession.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.qr]

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.bounds
        view.layer.addSublayer(previewLayer)

        captureSession.startRunning()
    }

    private func setupOverlay() {
        view.addSubview(logoImageView)
        view.addSubview(instructionLabel)
        view.addSubview(scanFrameView)
        scanFrameView.addSubview(laserLine)

        // Constraints para overlay
        NSLayoutConstraint.activate([
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.heightAnchor.constraint(equalToConstant: 40),
            logoImageView.widthAnchor.constraint(equalToConstant: 160),

            instructionLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 20),
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),

            scanFrameView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanFrameView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            scanFrameView.widthAnchor.constraint(equalToConstant: 220),
            scanFrameView.heightAnchor.constraint(equalToConstant: 220),
        ])

        // Láser
        laserTopConstraint = laserLine.topAnchor.constraint(equalTo: scanFrameView.topAnchor)

        NSLayoutConstraint.activate([
            laserLine.leadingAnchor.constraint(equalTo: scanFrameView.leadingAnchor),
            laserLine.trailingAnchor.constraint(equalTo: scanFrameView.trailingAnchor),
            laserTopConstraint!,
            laserLine.heightAnchor.constraint(equalToConstant: 2)
        ])

        startLaserAnimation()
    }

    private func startLaserAnimation() {
        view.layoutIfNeeded()
        let fullHeight = scanFrameView.frame.height - 2

        laserTopConstraint?.constant = 0
        view.layoutIfNeeded()

        UIView.animate(withDuration: 1.5,
                       delay: 0,
                       options: [.repeat, .autoreverse],
                       animations: {
            self.laserTopConstraint?.constant = fullHeight
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              object.type == .qr,
              let stringValue = object.stringValue else { return }
        
        // Reproducir sonido
        playBeepSound()
        
        delegate?.didFind(code: stringValue)
    }
    
    private func playBeepSound() {
        AudioServicesPlaySystemSound(SystemSoundID(1107)) // sonido "confirmation"
    }
    
    class PaddedLabel: UILabel {
        var textInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)

        override func drawText(in rect: CGRect) {
            super.drawText(in: rect.inset(by: textInsets))
        }

        override var intrinsicContentSize: CGSize {
            let size = super.intrinsicContentSize
            return CGSize(width: size.width + textInsets.left + textInsets.right,
                          height: size.height + textInsets.top + textInsets.bottom)
        }
    }
}
