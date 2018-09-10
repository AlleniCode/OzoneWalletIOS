//
//  HTTPRequest.swift
//  SwitcheoSwift
//
//  Created by Rataphon Chitnorm on 8/16/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import Neoutils

public class Switcheo {
    
    var baseURL = "https://test-api.switcheo.network"
    public enum Net: String {
        case Test = "https://test-api.switcheo.network"
        case Main =  "https://api.switcheo.network"
    }
    
    var apiVersion = "/v2/"
    
    enum HTTPMethod: String {
        case GET
        case POST
    }
    
    public init?(net: Net) {
        self.baseURL = net.rawValue
    }
    
    public typealias JSONDictionary = [String:  Any]
    
    public enum SWTHResult<T> {
        case success(T)
        case failure(SWTHError)
    }
    
    public enum SWTHError: Error {
        case  invalidBodyRequest, invalidData, invalidRequest, noInternet, switcheoError, switcheoDataError, serverError
        
        var localizedDescription: String {
            switch self {
            case .invalidBodyRequest:
                return "Invalid body Request"
            case .invalidData:
                return "Invalid response data"
            case .invalidRequest:
                return "Invalid server request"
            case .noInternet:
                return "No Internet connection"
            case .switcheoError:
                return "Swticheo API error"
            case .switcheoDataError:
                return "Swticheo data error"
            case .serverError:
                return "Internal server error"
            }
        }
    }
    
    func sendRequest<T>(ofType _: T.Type,_ endpointURL: String, method: HTTPMethod, data: JSONDictionary, completion: @escaping (SWTHResult<T>) -> Void){
        let url = URL(string: baseURL + apiVersion + endpointURL)!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("o3", forHTTPHeaderField: "User-Agent")
        request.httpMethod = method.rawValue
        request.cachePolicy = .reloadIgnoringLocalCacheData
        if data.count > 0 {
            guard let body = try? JSONSerialization.data(withJSONObject: data, options: JSONSerialization.WritingOptions.sortedKeys) else {
                completion(.failure(.invalidBodyRequest))
                return
            }
            request.httpBody = body
        }
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, err) in
            if err != nil {
                completion(.failure(.invalidRequest))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else  {
                    #if DEBUG
                        print(response as Any)
                        guard let errorUnwrapped = data,
                            let jsonError = (try? JSONSerialization.jsonObject(with: errorUnwrapped, options: [])) as? JSONDictionary else {
                                completion(.failure(.switcheoError))
                                return
                        }
                        print(endpointURL,jsonError,"________ERROR_________")
                    #endif
                    completion(.failure(.switcheoError))
                    return
            }
            
            
            guard let dataUnwrapped = data,
                let json = (try? JSONSerialization.jsonObject(with: dataUnwrapped, options: [])) as? T else {
                    completion(.failure(.switcheoDataError))
                    return
            }
            
            let result = SWTHResult.success(json)
            completion(result)
            
        }
        task.resume()
    }
    
    public  func tickersCandlesticks(request: RequestCandlesticks,
                                     completion: @escaping (SWTHResult<[Candlestick]>) -> Void){
        sendRequest(ofType:[JSONDictionary].self,
                    "tickers/candlesticks",
                    method: .GET,
                    data: request.dictionary,
                    completion: { (result) in
                        switch result {
                        case .failure(let error):
                            completion(.failure(error))
                        case .success(let response):
                            let decoder = JSONDecoder()
                            let responseData = try? JSONSerialization.data(withJSONObject: response, options: .prettyPrinted)
                            let result = try? decoder.decode([Candlestick].self, from: responseData!)
                            if (result == nil) {
                                completion(.failure(.invalidData))
                                return
                            }
                            let w = SWTHResult.success(result!)
                            completion(w)
                        }
        })
    }
    
    public func tickersLast24hours(completion: @escaping (SWTHResult<[Last24hour]>) -> Void){
        sendRequest(ofType: [JSONDictionary].self,
                    "tickers/last_24_hours",
                    method: .GET,
                    data: [:]) { (result) in
                        switch result {
                        case .failure(let error):
                            completion(.failure(error))
                        case .success(let response):
                            let decoder = JSONDecoder()
                            let responseData = try? JSONSerialization.data(withJSONObject: response, options: .prettyPrinted)
                            let result = try? decoder.decode([Last24hour].self, from: responseData!)
                            if (result == nil) {
                                completion(.failure(.invalidData))
                                return
                            }
                            let w = SWTHResult.success(result!)
                            completion(w)
                        }
        }
    }
    
    public func tickersLastPrice(symbols: [String], completion: @escaping (SWTHResult<JSONDictionary>) -> Void){
        sendRequest(ofType:JSONDictionary.self,
                    "tickers/last_price",
                    method: .GET,
                    data: ["symbols":symbols],
                    completion: completion)
    }
    
    public func offers(request: RequestOffer,
                       completion: @escaping (SWTHResult<[Offer]>) -> Void){
        
        sendRequest(ofType:[JSONDictionary].self,
                    "offers",
                    method: .GET,
                    data: request.dictionary,
                    completion: { (result) in
                        switch result {
                        case .failure(let error):
                            completion(.failure(error))
                        case .success(let response):
                            let decoder = JSONDecoder()
                            let responseData = try? JSONSerialization.data(withJSONObject: response, options: .prettyPrinted)
                            let result = try? decoder.decode([Offer].self, from: responseData!)
                            if (result == nil) {
                                completion(.failure(.invalidData))
                                return
                            }
                            let w = SWTHResult.success(result!)
                            completion(w)
                        }
        })
    }
    
    public func trades(request: RequestTrade,
                       completion: @escaping (SWTHResult<[Trade]>) -> Void){
        
        sendRequest(ofType:[JSONDictionary].self,
                    "trades",
                    method: .GET,
                    data: request.dictionary,
                    completion: { (result) in
                        switch result {
                        case .failure(let error):
                            completion(.failure(error))
                        case .success(let response):
                            let decoder = JSONDecoder()
                            let responseData = try? JSONSerialization.data(withJSONObject: response, options: .prettyPrinted)
                            let result = try? decoder.decode([Trade].self, from: responseData!)
                            if (result == nil) {
                                completion(.failure(.invalidData))
                                return
                            }
                            let w = SWTHResult.success(result!)
                            completion(w)
                        }
        })
    }
    
    public func balances(addresses: [String],contractHashs: [String],completion: @escaping (SWTHResult<JSONDictionary>) -> Void){
        let data = ["addresses": addresses, "contract_hashes": contractHashs] as JSONDictionary
        self.sendRequest(ofType:JSONDictionary.self,
                         "balances",
                         method: .GET,
                         data: data,
                         completion: completion)
    }
    
    public func contracts(completion: @escaping (SWTHResult<JSONDictionary>) -> Void){
        sendRequest(ofType:JSONDictionary.self,
                    "contracts",
                    method: .GET,
                    data: [:],
                    completion: completion)
    }
    
    public func exchangeTimestamp(completion: @escaping (SWTHResult<JSONDictionary>) -> Void){
        sendRequest(ofType:JSONDictionary.self,
                    "exchange/timestamp",
                    method: .GET,
                    data: [:],
                    completion: completion)
    }
    
    public func exchangePairs(bases :[String], completion: @escaping (SWTHResult<[String]>) -> Void){
        sendRequest(ofType: [String].self,
                    "exchange/pairs",
                    method: .GET,
                    data: ["bases":bases],
                    completion: completion)
    }
    
    public func exchangeTokens(completion: @escaping (SWTHResult<JSONDictionary>) -> Void){
        sendRequest(ofType: JSONDictionary.self,
                    "exchange/tokens",
                    method: .GET,
                    data: [:],
                    completion: completion)
    }
    
}
