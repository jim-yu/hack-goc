//
//  CameraViewController.swift
//  GoC
//
//  Created by Jim Yu on 2024-05-11.
//

import UIKit

class CameraViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    var imagePicker: UIImagePickerController!
    let activityIndicator = UIActivityIndicatorView(style: .large)  // Modern style for iOS 13 and later
    var capturedImage: UIImage?
    var originalImage: UIImage?
    var outputImageData: Data?
    var prompt: Data?
    var imageFetcher: ImageFetcher?;
    
    let outputImageUrl = "http://34.168.68.169:8188/view?filename=output.png&subfolder=&type=output"
    let originalUrl = "http://34.168.68.169:8188/view?filename=original.png&subfolder=&type=output"

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActivityIndicator()
        
        loadJsonDataFromFile(resourceName: "007_API-prompt") { jsonData in
            if let jsonData = jsonData {
                self.prompt = jsonData
            } else {
                print("Failed to load JSON data")
            }
        }
        
        loadImage(from: originalUrl) { data, error in
            if let data = data {
                self.originalImage = UIImage(data: data)
            } else if let error = error {
                print("Failed to load image: \(error)")
            }
        }
        
        loadImage(from: outputImageUrl) { data, error in
            if let data = data {
                self.outputImageData = data
            } else if let error = error {
                print("Failed to load data: \(error)")
            }
        }
    }

    func setupUI() {
        let takePhotoButton = UIButton(frame: CGRect(x: 20, y: self.view.frame.height - 100, width: self.view.frame.width - 40, height: 50))
        takePhotoButton.backgroundColor = .blue
        takePhotoButton.setTitle("Take your photo", for: .normal)
        takePhotoButton.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
        self.view.addSubview(takePhotoButton)

        let disclaimerLabel = UILabel(frame: CGRect(x: 20, y: 100, width: self.view.frame.width - 40, height: 100))
        disclaimerLabel.text = "Your image will not be saved anywhere, it is deleted as soon as you answer the upcoming question."
        disclaimerLabel.numberOfLines = 0
        disclaimerLabel.textAlignment = .center
        self.view.addSubview(disclaimerLabel)
        
        let infoButton = UIButton(type: .infoLight)
        infoButton.frame = CGRect(x: view.frame.width - 60, y: 40, width: 50, height: 50)
        infoButton.addTarget(self, action: #selector(showInfo), for: .touchUpInside)
        view.addSubview(infoButton)
    }
    
    @objc func showInfo() {
        let choiceACount = getChoiceACount()
        let choiceBCount = getChoiceBCount()
        
        let alert = UIAlertController(title: "Choices Count", message: "Choice A: \(choiceACount)\nChoice B: \(choiceBCount)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func setupActivityIndicator() {
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
    }

    @objc func takePhoto() {
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            
            dismiss(animated: true) {
                self.activityIndicator.startAnimating()
                print("resizeImage start: ", Date());
                self.capturedImage = resizeImage(image: image, targetWidth: 200) ?? image
                print("resizeImage end: ", Date());
                
                guard let imageData = convertImageToPNGData(image: self.capturedImage ?? image) else {
                    print("Failed to convert image to PNG")
                    return
                }
                
                print("convertImageToPNGData end: ", Date(), imageData.count/1024);
                
                uploadImage(data: imageData, completion: { success in
                    if success {
                        print("Image uploaded successfully: ", Date())
                    } else {
                        print("Failed to upload image")
                    }
                    let urlString = "http://34.168.68.169:8188/prompt"
                    if let url = URL(string: urlString), let prompt = self.prompt {
                        postJsonData(url: url, jsonData:prompt) { success, message in
                            print("Prompt trigger successfully: ", Date())
                            if ( success ) {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
                                    self.activityIndicator.stopAnimating()
                                    self.showComparisonScreen()
                                }
//                                self.imageFetcher?.startFetching()
                            }
                        }
                    }
                })
            }
        }
    }

    func showComparisonScreen() {
        let comparisonVC = ComparisonViewController()
        comparisonVC.originalImage = self.originalImage
        
        loadImage(from: outputImageUrl) { data, error in
            if let data = data {
                self.outputImageData = data
                comparisonVC.generatedImage = UIImage(data: data)
                loadImage(from: self.originalUrl) { data, error in
                    if let data = data {
                        self.originalImage = UIImage(data: data)
                        comparisonVC.originalImage = UIImage(data: data)
                        comparisonVC.modalPresentationStyle = .fullScreen // Optional: Choose the presentation style that fits the best
                        self.present(comparisonVC, animated: true, completion: nil)
                    } else if let error = error {
                        print("Failed to load image: \(error)")
                    }
                }
            }
        }
    }
}

func resizeImage(image: UIImage, targetWidth: CGFloat) -> UIImage? {
    let size = image.size
    
    print("Image size: ", size.width, size.height);

    let widthRatio = targetWidth / size.width
    let newHeight = size.height * widthRatio
    let newSize = CGSize(width: targetWidth, height: newHeight)

    let renderer = UIGraphicsImageRenderer(size: newSize)
    let resizedImage = renderer.image { _ in
        image.draw(in: CGRect(origin: .zero, size: newSize))
    }
    print("After image size: ", resizedImage.size.width, resizedImage.size.height);

    return resizedImage
}


func convertImageToPNGData(image: UIImage) -> Data? {
    let pngData = image.pngData()
    return pngData
}

// Revised uploadImage function to accept Data directly
func uploadImage(data: Data, completion: @escaping (Bool) -> Void) {
    guard let url = URL(string: "http://34.168.68.169:8188/upload/image") else {
        completion(false)
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    let boundary = "Boundary-\(UUID().uuidString)"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    
    var body = Data()
    body.appendString("--\(boundary)\r\n")
    body.appendString("Content-Disposition: form-data; name=\"image\"; filename=\"face.png\"\r\n")
    body.appendString("Content-Type: image/png\r\n\r\n")
    body.append(data)
    body.appendString("\r\n--\(boundary)--\r\n")

    let task = URLSession.shared.uploadTask(with: request, from: body) { data, response, error in
        if let error = error {
            print("Error: \(error)")
            completion(false)
            return
        }
        guard let response = response as? HTTPURLResponse,
              response.statusCode == 200 else {
            completion(false)
            return
        }
        completion(true)
    }
    task.resume()
}

extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}


func postJsonData(url: URL, jsonData: Data, completion: @escaping (Bool, String) -> Void) {
    // Create the request
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    // Perform the request
    let task = URLSession.shared.uploadTask(with: request, from: jsonData) { data, response, error in
        if let error = error {
            completion(false, "Request failed: \(error.localizedDescription)")
            return
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            completion(false, "Server error or invalid response")
            return
        }
        
        completion(true, "Data posted successfully")
    }
    task.resume()
}

func loadJsonDataFromFile(resourceName: String, completion: @escaping (Data?) -> Void) {
    guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
        print("JSON file not found")
        completion(nil)
        return
    }
    
    do {
        let data = try Data(contentsOf: url)
        completion(data)
    } catch {
        print("Error loading JSON data: \(error)")
        completion(nil)
    }
}


func loadImage(from urlString: String, completion: @escaping (Data?, Error?) -> Void) {
    guard let url = URL(string: urlString) else {
        completion(nil, NSError(domain: "InvalidURL", code: 1001, userInfo: nil))
        return
    }

    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            DispatchQueue.main.async {
                completion(nil, error)
            }
            return
        }

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let data = data else {
            DispatchQueue.main.async {
                completion(nil, NSError(domain: "InvalidImageData", code: 1002, userInfo: nil))
            }
            return
        }

        DispatchQueue.main.async {
            completion(data, nil)
        }
    }
    task.resume()
}


class ImageFetcher {
    private var currentImageData: Data?
    private var timer: Timer?
    private let urlString: String
    private let completion: (Data?) -> Void
    
    init(urlString: String, currentImageData: Data?, completion: @escaping (Data?) -> Void) {
        self.urlString = urlString
        self.currentImageData = currentImageData
        self.completion = completion
    }
    
    func startFetching() {
        timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(fetchImage), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .common) // Ensures the timer runs on the main run loop
    }
    
    func stopFetching() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func fetchImage() {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else {
                print("Failed to fetch image or error occurred: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // Check if the image data has changed
            if let currentImageData = self.currentImageData, currentImageData == data {
                print("Image has not changed.")
            } else {
                print("Image has changed or it's the first fetch.")
                DispatchQueue.main.async {
                    self.stopFetching();
                    self.completion(data)
                }
            }
        }
        task.resume()
    }
}
