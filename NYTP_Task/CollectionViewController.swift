//
//  CollectionViewController.swift
//  NYTP_Task
//
//  Created by Barath K on 19/12/20.
//

import UIKit

class CollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, PhotosListProtocol {
    
    private var viewModel: ViewModel!
   
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel = ViewModel(delegate: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel.getPhotosList()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.collectionView.collectionViewLayout.invalidateLayout()
        self.collectionView.reloadData()
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.numberOfItemsInCell()
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! CollectionViewCell
        cell.imageId = self.viewModel.photos[indexPath.item].id
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = self.viewModel.isLandscape ? (collectionView.bounds.width - 24)/2 : collectionView.bounds.width - 16
        let cellHeight = cellWidth * 0.67
        return CGSize(width: cellWidth, height: cellHeight)
    }
        
    func didGetList(_ list: [Photo]) {
        self.collectionView.reloadData()
    }
    
    func didGetError(_ error: APIError) {
        self.showAlert(message: error.reason)
    }
    
    private func showAlert(message: String) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let okAlertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAlertAction)
        self.present(alertController, animated: true, completion: nil)
    }
}
