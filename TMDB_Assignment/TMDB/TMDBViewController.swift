//
//  TMDBViewController.swift
//  TMDB_Assignment
//
//  Created by Mac Pro 15 on 2022/09/15.
//

import UIKit

import Alamofire
import Kingfisher
import SwiftyJSON

/*질문
 -. 이미지주소 앞부분은 TMDB 사이트 어디에 나와있는지? 구글 뒤져서 imageURL 부분 찾음...
 -. 배열로 받은 장르코드 어떻게 해당 장르로 문자변환하는지? 1. AF로 네트워크 통신 또 해야하는지? 2. 코드랑 장르랑 매칭은 어떻게 하는지?
 -. 캐스팅에서 영화코드는 어떻게 받아서 처리하는지?
 -. 테이블뷰에서 UiView 테두리색없이 둥근 모서리 처리 어떻게하는지?
 -. 과제예시에서 화면 상단에 써치바 아니라 네비게이션아이템인건지? 만약 서치바라면 예시처럼 커스텀이 되는지?(구글링에서는 예시처럼 된 커스텀 못찾음)
 -. 받아온 장르데이터를 어떻게 코드에 매칭시키는지? contain 사용? 장르코드 배열 중 첫번째 값이 장르데이터에 있으면 장르로 표시하려고 하는데 조건적용 못하겠음(= "\(genreArray[0].genre.values)"처럼). 네트워크요청함수사용해서 처리해야할 것같은데 셀재사용안하고 어떻게 매개변수랑 인덱스를 맞추는지?
 -. 만약 전체 페이지가 1억개인데 페이지네이션 처리안하면 어떻게 되는지? 페이지네이션 사용유무 차이 의미?
 */

class TMDBViewController: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var TMDBtableView: UITableView!
    
    var TMDBArray : [TMDBModel] = []
    var genreArray : [GenreModel] = []
    var castArray : [String] = []
    var startPage = 0
    var totalCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        TMDBtableView.delegate = self
        TMDBtableView.dataSource = self
        searchBar.delegate = self
        TMDBtableView.register(UINib(nibName: "TMDBTableViewCell", bundle: nil), forCellReuseIdentifier: TMDBTableViewCell.identifier)
        
        requestTMDB()
        requestGenre()
    }
    
    func requestTMDB() {
        let url = "\(EndPoint.TMDBURL)api_key=\(APIKey.TMDBAPIKey)"
        AF.request(url, method: .get).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                print("JSON: \(json)")
                
                self.totalCount = json["total_pages"].intValue
                
                for data in json["results"].arrayValue {
                    let id = data["id"].intValue //영화id
                    let poster_path = data["poster_path"].stringValue //포스터
                    let release_date = data["release_date"].stringValue //개봉일
                    let genre_ids = data["genre_ids"].arrayObject //장르
                    let vote_average = data["vote_average"].stringValue //평점
                    let title = data["title"].stringValue //제목
                    
                    self.TMDBArray.append(TMDBModel(movieId: id, movieImage: poster_path, releaseDate: release_date, genre: genre_ids!, rating: vote_average, movieName: title))
                }
                
                self.TMDBtableView.reloadData()
                print(self.TMDBArray[0])
                
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func requestGenre() { //장르 데이터 요청
        let url = "\(EndPoint.GenreURL)\(APIKey.TMDBAPIKey)&language=en-US"
        AF.request(url, method: .get).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                print("JSON: \(json)")
                
                for data in json["genres"].arrayValue {
                    let id = data["id"].intValue
                    let name = data["name"].stringValue
                    self.genreArray.append(GenreModel(genre: [id: name]))
                }
                self.TMDBtableView.reloadData()
                print(self.genreArray)
                //print(self.genreArray.contains { $0.genre == 14 })
                
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func searchBarAttribute() {
        
    }
    
}
extension TMDBViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TMDBArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TMDBTableViewCell.identifier, for: indexPath) as? TMDBTableViewCell else { return UITableViewCell() }
        
        cell.configureCell()
        
        //서버통신 시점에서 url변환하면 시간이 더 오래걸릴 수 있기 때문에 셀재사용할 때 url변환하는 것이 좋음
        let imageURL = "https://image.tmdb.org/t/p/w185"
        let url = URL(string: "\(imageURL)\(TMDBArray[indexPath.row].movieImage)")
        
        cell.movieImageView.kf.setImage(with: url)
        cell.releasedDateLabel.text = TMDBArray[indexPath.row].releaseDate
        cell.genreLabel.text = "\(genreArray[0].genre.values)"
        //cell.genreLabel.text = "\(TMDBArray[indexPath.row].genre)"
        cell.movieTitle.text = TMDBArray[indexPath.row].movieName
        
        let castUrl = "\(EndPoint.GenreURL)\(TMDBArray[indexPath.row].movieId)/credits?api_key=\(APIKey.TMDBAPIKey)&language=en-US"
        AF.request(castUrl, method: .get).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                print("JSON: \(json)")
                
                for data in json["cast"].arrayValue {
                    let name = data["name"].stringValue
                    self.castArray.append(name)
                }
                self.TMDBtableView.reloadData()
                
            case .failure(let error):
                print(error)
            }
            cell.movieCast.text = castArray[indexPath.row]
            cell.ratingNumberLabel.text = TMDBArray[indexPath.row].rating
            
            return cell
            
            
            //let castURL = "https://api.themoviedb.org/3/movie/\(movieID)/credits?api_key=\(APIKey.TMDBAPIKey)&language=en-US"
            
        }
        
        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return UIScreen.main.bounds.height / 2
        }
        
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            //
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            let sb = UIStoryboard(name: "Main", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: MovieDetailsViewController.identifier)
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
    }
}

extension TMDBViewController: UICollectionViewDataSourcePrefetching {
    //셀이 화면에 보이기 전에 미리 필요한 리소스를 다운받는 기능
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            //반복이미지가 총 이미지 갯수보다 많아져서 이미지반복되는 문제 처리
            if TMDBArray.count - 1 == indexPath.item && TMDBArray.count < totalCount {
                startPage += 5
            }
        }
        print("=======\(indexPaths)======")
    }
    //네트워크 통신 취소: 직접 메서드 구현해줘야 함
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        print("===취소====\(indexPaths)======")
    }
}

