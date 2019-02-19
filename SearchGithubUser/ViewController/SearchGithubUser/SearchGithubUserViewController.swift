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
import Kingfisher
import Alamofire

class SearchGithubUserViewController: UIViewController {
    
    // MARK:- Outlets
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var indicator: UIActivityIndicatorView!
    
    
    // MARK:- Constants
    let stringURL = "https://api.github.com/search/users" // Github 유저 검색 API
    let token = "input github token" // Github 인증 토큰
    
    // MARK:- Variables
    var disposeBag : DisposeBag = DisposeBag()
    
    var page = "1" // 페이지 번호
    var perPage = "20" // 페이지 당 데이터 개수
    
    var userDetails = [UserDetailModel]()
    var searchUsers = [SearchUserModel]()
    
    var repoNumDic = Dictionary<String, Int>()
    
    // 텍스트 input Observable
    var inputText: Observable<String> {
        return searchBar.rx.text
            .orEmpty
            .filter { query in
                return query.count > 2
            }
            .debounce(1, scheduler: MainScheduler.instance) // 1초 이후에 요청을 보냄
            .distinctUntilChanged() // 같은 값을 입력하는것을 막아줌
    }
    
    // 쿼리문을 날려 JSON데이터를 받아 처리하는 Observable
    var reposOb: Observable<[SearchUserModel]> {
        return inputText
            .map { query in
                var apiUrl = URLComponents(string: self.stringURL)!
                apiUrl.query = "q=\(query)&per_page=\(self.perPage)&page=\(self.page)"
                
                let url = apiUrl.url!
                let headers = ["Authorization":"token \(self.token)"]
                
                self.indicator.startAnimating() // Request 보낼 때 인디케이터 시작
                
                return try URLRequest(url: url, method: .get, headers: headers)
            }
            .flatMapLatest { request in
                return URLSession.shared.rx.json(request: request)
                    .catchErrorJustReturn([])
            }
            .map { json -> [SearchUserModel] in
                guard let json = json as? [String: Any],
                    let items = json["items"] as? [[String: Any]]  else {
                        return []
                }
                return items.compactMap(SearchUserModel.init)
        }
    }
    
    
    
    // MARK:- Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bindUI()
    }
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        self.disposeBag = DisposeBag()
    }
    
    
    
    func bindUI() {
        reposOb
            .subscribeOn(ConcurrentDispatchQueueScheduler.init(qos: .default))
            .subscribe(onNext: { searchUsers in
                self.userDetails.removeAll()
                self.searchUsers.removeAll()
                
                self.searchUsers = searchUsers
                self.getUserData(searchUsers: searchUsers) {
                    self.tableView.reloadData()
                }
            }).disposed(by: disposeBag)
    }
    
    
    
    func getUserData(searchUsers: [SearchUserModel], complete: (() -> Void)? = nil) {
        let headers: HTTPHeaders = [
            "Authorization" : "token \(self.token)"
        ]
        let jsonDecoder = JSONDecoder()
        var count = searchUsers.count
        
        for repo in searchUsers {
            let url = repo.url
            let name = repo.name
            
            Alamofire.request(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers).responseData { response in
                
                print("Alamofire \(repo.name)")
                count -= 1
                
                let user = try! jsonDecoder.decode(UserDetailModel.self, from: response.data!)
                
                self.userDetails.append(user)
                self.repoNumDic[name] = user.publicRepos
                
                if count == 0 {
                    complete?()
                    self.indicator.stopAnimating()
                }
            }
        }
    }
}



// MARK: - TableView + extension
extension SearchGithubUserViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.userDetails.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell") as! UserCell
        let url = URL(string: self.searchUsers[indexPath.row].avatarURL) // 이미지 url
        let numberOfRepos = String(self.repoNumDic[searchUsers[indexPath.row].name]!)
        
        // cell binding
        cell.userNameLabel.text = self.searchUsers[indexPath.row].name
        cell.userImageView.kf.setImage(with: url)
        cell.userReposNumLabel.text = "Number of Repos : \(numberOfRepos)"
        
        return cell
    }
}



extension SearchGithubUserViewController: UITableViewDelegate {
    // 테이블뷰를 스크롤 했을 때 키보드 숨기기
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.searchBar.endEditing(true)
    }
}
