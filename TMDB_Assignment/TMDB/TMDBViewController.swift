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
 -. 장르코드 배열값에 접근하는 방법이 무엇인지? print(TMDBArray[indexPath.row].genre[0]) 하면 불일치 에러 발생 -> 해결: 네트워크 요청할때 데이터형식과 받을 때 데이터 형식을 일치시켜야함.(고차함수 map사용하여 배열값중 하나를 처음부터 int로 받기)
 -. 장르코드에 딕셔너리형태 데이터 어떻게 집어넣는지? "\(genreArray[TMDBArray[indexPath.row].genre[0].key])"처럼 장르데이터에 해당장르코드키값을 넣어야하는데 문법에서? 에러발생함. -> 해결: 장르코드 배열값에 접근방법과 동일
 -. String(format: "%.2f", TMDBArray[indexPath.row].rating) 적용하면 왜 0으로 뜨는지?
 -. 웹뷰화면으로 이동할 링크값이 왜 전달안되는지? 화면전환시 프로퍼티를 만들어 데이터를 전달하려 했으나 clipButtonClicked함수에서는 indexPath를 사용할 수 없어서 didSelectRowAt에서 프로퍼티에 데이터 전달했지만 webview에 전달된 데이터가 없음.
 */

class TMDBViewController: UIViewController, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var TMDBtableView: UITableView!
    
    var TMDBArray : [TMDBModel] = []
    var genreArray = [Int: String]()
    var startPage = 0
    var totalCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        TMDBtableView.delegate = self
        TMDBtableView.dataSource = self
        searchBar.delegate = self
        TMDBtableView.register(UINib(nibName: "TMDBTableViewCell", bundle: nil), forCellReuseIdentifier: TMDBTableViewCell.identifier)
        
        requestTMDB()
        
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
                    let genre_ids = data["genre_ids"].arrayValue.map { $0.intValue } //genre_ids배열에서 첫번째 배열값만 Int타입으로 요청
                    let vote_average = data["vote_average"].stringValue //평점
                    let title = data["title"].stringValue //제목
                    
                    self.TMDBArray.append(TMDBModel(movieId: id, movieImage: poster_path, releaseDate: release_date, genre: genre_ids, rating: vote_average, movieName: title))
                }
                
                
                self.requestGenre()
                //self.TMDBtableView.reloadData()
                
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
                //print("JSON: \(json)")
                
                for data in json["genres"].arrayValue {
                    let id = data["id"].intValue
                    let name = data["name"].stringValue
                    self.genreArray[id] = name
                    
                }
                self.TMDBtableView.reloadData()
                //print(self.genreArray)
                
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
        UserDefaults.standard.set("\(imageURL)\(TMDBArray[indexPath.row].movieImage)", forKey: "imageURL")
        
        cell.movieImageView.kf.setImage(with: url)
        
        //cell.ratingNumberLabel.text = String(format: "%.2f", TMDBArray[indexPath.row].rating)
        cell.ratingNumberLabel.text = TMDBArray[indexPath.row].rating
        cell.releasedDateLabel.text = TMDBArray[indexPath.row].releaseDate
        cell.genreLabel.text = "#\(genreArray[TMDBArray[indexPath.row].genre[0]]!)"
        cell.movieTitle.text = TMDBArray[indexPath.row].movieName
        cell.clipButton.tag = indexPath.row
        cell.clipButton.addTarget(self, action: #selector(clipButtonClicked(sender:)), for: .touchUpInside)
        
        cell.tag = indexPath.row
        print(cell.tag)

        return cell
    }
    
    /*clipButtonClicked(링크버튼눌렀을 때 데이터처리)
      #필요한데이터: 영화코드데이터
      #연산
      -.링크버튼을 누르면 영화코드데이터를 예고편화면으로 전달
      -.받은영화코드로 해당 예고편데이터를 네트워크요청해서 화면 띄우기
      #보여줄데이터: 영화예고편
     */
    
    @objc func clipButtonClicked(sender: UIButton) {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let sceneDelegate =  windowScene?.delegate as? SceneDelegate
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "WebViewController") as! WebViewController
        let navi = UINavigationController(rootViewController: vc)
        vc.movieID = TMDBArray[sender.tag].movieId //sender.tag사용하여 버튼에 태그를 설정하여 indexPath대신 sender.tag로 영화id 넘김
        sceneDelegate?.window?.rootViewController = navi
        sceneDelegate?.window?.makeKeyAndVisible()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UIScreen.main.bounds.height / 2
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: MovieDetailsViewController.identifier) as! MovieDetailsViewController
        //let webVc = sb.instantiateViewController(withIdentifier: "WebViewController") as! WebViewController
        vc.movieID = TMDBArray[indexPath.row].movieId
        vc.movieImage = TMDBArray[indexPath.row].movieImage
        //webVc.movieID = TMDBArray[indexPath.row].movieId
        print(TMDBArray[indexPath.row].movieImage)
        self.navigationController?.pushViewController(vc, animated: true)
        
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

