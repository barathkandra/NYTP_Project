//
//  ImageDownloader.swift
//  NYTP_Task
//
//  Created by Barath K on 19/12/20.
//

import UIKit

extension UIImageView {
    
    func assignImage(from urlText: String) {
        
        if urlText.isEmpty {
            print("Image URL invalid -> \(urlText)")
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            let fileUrl = self.getFileUrl(urlText)
            if FileManager.default.fileExists(atPath: fileUrl.path), let image = UIImage(contentsOfFile: fileUrl.path) {
                DispatchQueue.main.async {
                    self.image = image
                }
                return
            }
            
            if let url = URL(string: urlText), let imageData = try? Data(contentsOf: url), let image = UIImage(data: imageData) {
                DispatchQueue.main.async {
                    self.image = image
                }
                self.saveImageInLocalDirectory(image: image, urlText: urlText)
            } else {
                print("Image Downloading Failed -> \(urlText)")
            }
        }
    }
    
    private func saveImageInLocalDirectory(image: UIImage, urlText: String) {
        let fileUrl = self.getFileUrl(urlText)
        
        guard let imageType = urlText.components(separatedBy: ".").last?.lowercased() else { return }
        guard let imageData = (imageType == "png") ? image.pngData() : image.jpegData(compressionQuality: 1) else { return }
        
        do {
            try imageData.write(to: fileUrl)
        } catch {
            print("Image Saving Failed -> \(urlText)")
        }
    }
    
    private func getFileUrl(_ urlText: String) -> URL {
        let documentsUrls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileName = NSString(string: urlText).lastPathComponent
        return documentsUrls.first!.appendingPathComponent(fileName)
    }
    
}
