//
//  ViewController.swift
//  SearchGithubUser
//
//  Created by Byunsangjin on 15/02/2019.
//  Copyright © 2019 Byunsangjin. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxAlamofire
import RxKingfisher
import Kingfisher
import Alamofire

class SearchGithubUserViewController: UIViewController {
    
    // MARK:- Outlets
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    
    
    // MARK:- Constants
    let disposeBag : DisposeBag = DisposeBag()
    let stringURL = "https://api.github.com/search/users?q="
    
    
    // MARK:- Variables
    var page = "1" // 페이지 번호
    var perPage = "20" // 페이지 당 데이터 개수
    
    
    var inputText: Observable<String> {
        return searchBar.rx.text
            .orEmpty
            .filter { query in
                return query.characters.count > 2
            }
            .debounce(0.5, scheduler: MainScheduler.instance) // 0.5초 이후에 요청을 보냄
            .distinctUntilChanged() // 같은 값을 입력하는것을 막아줌
    }
    
    var reposOb: Observable<[RepoModel]> {
        return inputText
            .map { query in
                var apiUrl = URLComponents(string: self.stringURL)!
                apiUrl.query = "q=\(query)&per_page=\(self.perPage)&page=\(self.page)"
                return try URLRequest(url: apiUrl.url!, method: .get, headers: ["Authorization":"token 431f6bf5d6343def98044514b051c7c6fb2a317b"])
            }
            .flatMapLatest { request in
                return URLSession.shared.rx.json(request: request)
                    .catchErrorJustReturn([])
            }
            .map { json -> [RepoModel] in
                guard let json = json as? [String: Any],
                    let items = json["items"] as? [[String: Any]]  else {
                        return []
                }
                return items.compactMap(RepoModel.init)
        }
    }
    
    var users = [UserModel]()
    var repos = [RepoModel]()
    
    var repoNumDic = Dictionary<String, Int>()
    
    // MARK:- Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bindUI()
    }
    
    
    
    func bindUI() {
        reposOb
//            .subscribeOn(ConcurrentDispatchQueueScheduler.init(qos: .default))
            .subscribe(onNext: { repos in
                print("subcribe")
                self.repos.removeAll()
                self.users.removeAll()
                
                self.repos = repos
                self.getUserData(repos: repos) {
                    self.tableView.reloadData()
                }
            }).disposed(by: disposeBag)
    }
    
    
    
    func getUserData(repos: [RepoModel], complete: (() -> Void)? = nil) {
        let headers: HTTPHeaders = [
            "Authorization" : "token 431f6bf5d6343def98044514b051c7c6fb2a317b"
        ]
        let jsonDecoder = JSONDecoder()
        var count = repos.count
        
        for repo in repos {
            let url = repo.url
            let name = repo.name
            
            Alamofire.request(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers).responseData { response in
                
                count -= 1
                
                let user = try! jsonDecoder.decode(UserModel.self, from: response.data!)
                
                self.users.append(user)
                self.repoNumDic[name] = user.publicRepos
                
                if count == 0 { complete?() }
            }
        }
    }
}



// MARK: - TableView + extension
extension SearchGithubUserViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell") as! UserCell
        cell.userNameLabel.text = self.repos[indexPath.row].name
        
        let url = URL(string: self.repos[indexPath.row].avatarURL)
        cell.userImageView.kf.setImage(with: url)
        
        let numberOfRepos = String(self.repoNumDic[repos[indexPath.row].name]!)
        cell.userReposNumLabel.text = "Number of Repos : \(numberOfRepos)"
        
        return cell
    }}

