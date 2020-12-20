//
//  ViewModel.swift
//  NYTP_Task
//
//  Created by Barath K on 19/12/20.
//

import UIKit

protocol PhotosListProtocol {
    func didGetList(_ list: [Photo])
    func didGetError(_ error: APIError)
}

class ViewModel {
    
    private var photosListProtocol: PhotosListProtocol?
    var photos: [Photo] = []
    
    var isLandscape: Bool {
        return UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight
    }
    
    init(delegate: PhotosListProtocol) {
        self.photosListProtocol = delegate
    }
    
    func getPhotosList() {
        
        let apiRequest = APIRequest(urlType: .photos, path: .list, method: .get, headers: .withToken)
        APIDispatcher.instance.dispatch(request: apiRequest, response: [Photo].self) { (result) in
            switch result {
            case .success(let list):
                self.photos = list
                self.photosListProtocol?.didGetList(list)
            case .failure(let error):
                self.photosListProtocol?.didGetError(error)
            }
        }
        
    }
    
    func numberOfItemsInCell() -> Int {
        return self.photos.count
    }
    
}
