//
//  ComparisonViewController.swift
//  GoC
//
//  Created by Jim Yu on 2024-05-11.
//

import UIKit

import UIKit

class ComparisonViewController: UIViewController {
    var originalImage: UIImage?
    var originalUIImageView: UIImageView?
    var generatedImage: UIImage? // This would typically be loaded from your backend
    var generatedUIImageView: UIImageView?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        addRefreshButton()
    }

    func setupUI() {
        let questionLabel = UILabel(frame: CGRect(x: 20, y: 50, width: self.view.frame.width - 40, height: 50))
        questionLabel.text = "Which image are you more likely to click on?"
        questionLabel.textAlignment = .center
        self.view.addSubview(questionLabel)
        
        var y:CGFloat = 0.0;
        
        if let original = originalImage {
            let ratio = original.size.width / (self.view.frame.width - 40);
            let height = original.size.height / ratio;
            originalUIImageView = UIImageView(frame: CGRect(x: 20, y: 120, width: self.view.frame.width - 40, height: height))
            originalUIImageView?.image = original
            if let imageView = originalUIImageView {
                self.view.addSubview(imageView)
            }
            
            let chooseAButton = UIButton(frame: CGRect(x: 20, y: 120 + height, width: self.view.frame.width - 40, height: 50))
            chooseAButton.backgroundColor = .red
            chooseAButton.setTitle("Choose A", for: .normal)
            chooseAButton.addTarget(self, action: #selector(handleChoiceA(_:)), for: .touchUpInside)
            self.view.addSubview(chooseAButton)
            y = 120 + height + 50
        }

        
        if let gen = generatedImage {
            let ratio = gen.size.width / (self.view.frame.width - 40);
            let height = gen.size.height / ratio;
            generatedUIImageView = UIImageView(frame: CGRect(x: 20, y: y + 20.0, width: self.view.frame.width - 40, height: height))
            generatedUIImageView?.image = gen
            if let imageView = generatedUIImageView {
                self.view.addSubview(imageView)
            }
            
            let chooseAButton = UIButton(frame: CGRect(x: 20, y: y + height + 20, width: self.view.frame.width - 40, height: 50))
            chooseAButton.backgroundColor = .red
            chooseAButton.setTitle("Choose B", for: .normal)
            chooseAButton.addTarget(self, action: #selector(handleChoiceB(_:)), for: .touchUpInside)
            self.view.addSubview(chooseAButton)
        }


        // Setup for generated image and button B similarly
    }

    @objc func handleChoiceA(_ sender: UIButton) {
        // Here you can handle the choice and perhaps make a network call or just dismiss
        incrementChoiceACounter()
        dismiss(animated: true, completion: nil)
    }
    
    @objc func handleChoiceB(_ sender: UIButton) {
        // Here you can handle the choice and perhaps make a network call or just dismiss
        incrementChoiceBCounter()
        dismiss(animated: true, completion: nil)
    }
    
    func addRefreshButton() {
        let refreshButton = UIButton(type: .system)
        refreshButton.setTitle("Refresh", for: .normal)
        refreshButton.addTarget(self, action: #selector(refreshButtonTapped), for: .touchUpInside)
        
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(refreshButton)

        NSLayoutConstraint.activate([
            refreshButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            refreshButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            refreshButton.heightAnchor.constraint(equalToConstant: 50),
            refreshButton.widthAnchor.constraint(equalToConstant: 200)
        ])
    }

    @objc func refreshButtonTapped() {
        reloadImage()
    }

    func reloadImage() {
        // Implement the logic to reload images
        // For example, you might want to fetch a new image from a server or regenerate an image
        print("Image reload triggered")
        let outputImageUrl = "http://34.168.68.169:8188/view?filename=output.png&subfolder=&type=output"
        let originalUrl = "http://34.168.68.169:8188/view?filename=original.png&subfolder=&type=output"

        loadImage(from: outputImageUrl) { data, error in
            if let data = data, let imageView = self.generatedUIImageView  {
                imageView.image = UIImage(data: data)
                imageView.layoutIfNeeded()
            }
        }
        
        loadImage(from: originalUrl) { data, error in
            if let data = data, let imageView = self.originalUIImageView  {
                imageView.image = UIImage(data: data)
                imageView.layoutIfNeeded()
            }
        }
    }
}

func incrementChoiceACounter() {
    let currentCount = UserDefaults.standard.integer(forKey: "ChoiceACount")
    UserDefaults.standard.set(currentCount + 1, forKey: "ChoiceACount")
}

func getChoiceACount() -> Int {
    return UserDefaults.standard.integer(forKey: "ChoiceACount")
}

func incrementChoiceBCounter() {
    let currentCount = UserDefaults.standard.integer(forKey: "ChoiceBCount")
    UserDefaults.standard.set(currentCount + 1, forKey: "ChoiceBCount")
}

func getChoiceBCount() -> Int {
    return UserDefaults.standard.integer(forKey: "ChoiceBCount")
}
