//
//  ApiManager.swift
//  NYTP_Task
//
//  Created by Barath K on 19/12/20.
//


import UIKit

enum APIURLType: String {
    
    case photos = "https://picsum.photos/"
    
    var baseUrl: String {
        return self.rawValue
    }
    
}

enum APIPath: String {
    
    case list = "list"

    func directURL(type: APIURLType) -> URL? {
        let urlPath = type.baseUrl + self.rawValue
        return URL(string: urlPath)
    }
    
    func extendedURL(type: APIURLType, attach path: String) -> URL? {
        let urlPath = type.baseUrl + self.rawValue + "/" + path
        return URL(string: urlPath)
    }
    
    func extendedURL(type: APIURLType, using parameters: [String:String]) -> URL? {
        let urlPath = parameters.reduce(type.baseUrl + self.rawValue) { (urlPath, parameter) -> String in
            return urlPath + "?" + parameter.key + "=" + parameter.value
        }
        return URL(string: urlPath)
    }
    
}

enum APIMethod: String {
    case get = "GET"
    case put = "PUT"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
}

enum APIHeaders {
    case withToken
    case withoutToken
    
    var authorization: [String:String] {
        switch self {
        case .withoutToken:
            return ["Content-Type": "application/json", "Accept": "application/json"]
        case .withToken:
            return ["Content-Type": "application/json", "Accept": "application/json", "token": ""]
        }
    }
}

struct APIRequest {
    
    var url: URL?
    var method: String
    var parameters: Data?
    var headers: [String:String]
    
    init(urlType: APIURLType, path: APIPath, method: APIMethod, headers: APIHeaders) {
        self.url = path.directURL(type: urlType)
        self.method = method.rawValue
        self.headers = headers.authorization
    }
    
    init(urlType: APIURLType, path: APIPath, attachLastPath lastPath: String, method: APIMethod, headers: APIHeaders) {
        self.url = path.extendedURL(type: urlType, attach: lastPath)
        self.method = method.rawValue
        self.headers = headers.authorization
    }
    
    init(urlType: APIURLType, path: APIPath, attachParameters parameters: [String:String], method: APIMethod, headers: APIHeaders) {
        self.url = path.extendedURL(type: urlType, using: parameters)
        self.method = method.rawValue
        self.headers = headers.authorization
    }
    
    init(urlType: APIURLType, path: APIPath, method: APIMethod, parameters: [String:Any], headers: APIHeaders) {
        self.url = path.directURL(type: urlType)
        self.method = method.rawValue
        self.parameters = try? JSONSerialization.data(withJSONObject: parameters, options: .sortedKeys)
        self.headers = headers.authorization
    }
    
    init<Encode: Encodable>(urlType: APIURLType, path: APIPath, method: APIMethod, parameters: Encode, headers: APIHeaders) {
        self.url = path.directURL(type: urlType)
        self.method = method.rawValue
        self.parameters = try? JSONEncoder().encode(parameters)
        self.headers = headers.authorization
    }
    
}

struct APIError: Error {
    let reason: String
    init(reason: String) {
        self.reason = reason
    }
}


struct APIDispatcher {
    
    static let instance = APIDispatcher()
    private init() {}
    
    func dispatch<Decode: Decodable>(request: APIRequest, response: Decode.Type, result: @escaping (Result<Decode, APIError>) -> ()) {
        self.connectToServer(with: request) { (resultant) in
            switch resultant {
            case .success(let data):
                do {
                    let decoded = try JSONDecoder().decode(response, from: data)
                    DispatchQueue.main.async {
                        result(.success(decoded))
                    }
                } catch {
                    let apiError = APIError(reason: error.localizedDescription)
                    DispatchQueue.main.async {
                        result(.failure(apiError))
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    result(.failure(error))
                }
            }
        }
    }
    
    func dispatch(request: APIRequest, result: @escaping (Result<Dictionary<String,Any>, APIError>) -> ()) {
        self.connectToServer(with: request) { (resultant) in
            switch resultant {
            case .success(let data):
                do {
                    if let serialized = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String,Any> {
                        DispatchQueue.main.async {
                            result(.success(serialized))
                        }
                    } else {
                        let apiError = APIError(reason: "No Data as Dictionary<String, Any>")
                        DispatchQueue.main.async {
                            result(.failure(apiError))
                        }
                    }
                } catch {
                    let error = APIError(reason: error.localizedDescription)
                    DispatchQueue.main.async {
                        result(.failure(error))
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    result(.failure(error))
                }
            }
        }
    }
    
    private func connectToServer(with request: APIRequest, result: @escaping (Result<Data, APIError>) -> ()) {
        
        guard let url = request.url else {
            let error = APIError(reason: "Invalid URL")
            result(.failure(error))
            return
        }
        
        var urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30)
        urlRequest.httpMethod = request.method
        urlRequest.httpBody = request.parameters
        urlRequest.allHTTPHeaderFields = request.headers
        
        let urlSessionConfiguration = URLSessionConfiguration.default
        urlSessionConfiguration.waitsForConnectivity = true
        urlSessionConfiguration.timeoutIntervalForRequest = 30
        urlSessionConfiguration.timeoutIntervalForResource = 60
        
        let urlSession = URLSession(configuration: urlSessionConfiguration)
        urlSession.dataTask(with: urlRequest) { (data, response, error) in
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                    var errorDescription = ""
                    if let httpResponse = response as? HTTPURLResponse {
                        errorDescription = ("Status Code: " + httpResponse.statusCode.description + "\n")
                    }
                    if let data = data, let errorResponse = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, Any> {
                        errorDescription += (errorResponse.compactMap({ (key, value) -> String in
                            return key + ": " + (value as? String ?? "")
                        })).joined(separator: "\n")
                    }
                    let apiError = APIError(reason: errorDescription)
                    result(.failure(apiError))
                    return
            }
            
            if let error = error {
                let apiError = APIError(reason: error.localizedDescription)
                result(.failure(apiError))
                return
            }
            if let data = data {
                if let serialized = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, Any>, serialized.contains(where: { $0.key == "error" }), let errorText = ((serialized["message"] as? String) ?? serialized["error"] as? String) {
                    let apiError = APIError(reason: errorText)
                    result(.failure(apiError))
                    return
                }
                result(.success(data))
            }
        }.resume()
        
    }
    
    
    
}
