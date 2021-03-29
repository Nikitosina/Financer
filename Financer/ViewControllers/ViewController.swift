//
//  ViewController.swift
//  Financer
//
//  Created by Никита Раташнюк on 27.02.2021.
//

import UIKit

protocol FavouriteDelegate {
    func modifyFavourites(stock: Stock)
}

protocol SuggestDelegate {
    func modifySearchBar(s: String)
}

class ViewController: UIViewController, FavouriteDelegate, SuggestDelegate {
    
    @IBOutlet var searchView: UIView!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var suggestionsView: UIView!
    @IBOutlet var stocksButton: UIButton!
    @IBOutlet var favouriteButton: UIButton!
    @IBOutlet var stocksTable: UITableView!
    @IBOutlet var popularRequestsCollection: UICollectionView!
    @IBOutlet var historyCollection: UICollectionView!
    var favouriteViewMode = false
    var searchViewMode = false
    var stockList = [Stock]()
    var searchStockList = [Stock]()
    var filteredFavouritesList = [Stock]()
    let popularTickers = ["Apple", "Microsoft", "Tesla", "Amazon", "Facebook", "Google", "Nokia", "Abbvie", "AT&T", "Qualcomm"]
    var historyTickers: [String]!
    var showMore = false
    private var workItem: DispatchWorkItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        overrideUserInterfaceStyle = .light
        navigationController?.navigationBar.isHidden = true

        suggestionsView.isHidden = true
        
        searchBar.delegate = self
        searchBar.searchTextField.font = UIFont(name: "Montserrat Bold", size: 16.0)
        searchBar.searchTextField.backgroundColor = .white
        searchBar.searchTextField.background = .none
        searchBar.setLeftImage(UIImage(named: "search_icon")!)
        searchBar.placeholder = "Find company or ticker"
        
        searchView.layer.cornerRadius = 30
        searchView.layer.borderWidth = 2
        
        stocksTable.dataSource = self
        stocksTable.rowHeight = 100
        stocksTable.separatorStyle = UITableViewCell.SeparatorStyle.none
        stocksTable.keyboardDismissMode = .onDrag
        
        popularRequestsCollection.dataSource = self
        popularRequestsCollection.delegate = self
        historyCollection.dataSource = self
        historyCollection.delegate = self
        historyTickers = getAllHistoryTickers()
        
        // let initialStockList = getTrendingStocks(limit: 10)
        // print(search(by: "apple"))
        let initialStockList = ["AAPL", "MSFT", "TSLA", "AMZN", "ABBV", "FB", "YNDX", "KO"]
        let initialFavourites = getAllFavourites()
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
    
        for ticker in initialStockList {
            queue.addOperation {
                if let stock = loadStockDataFromURL(ticker: ticker) {
                    self.stockList.append(stock)
                    if initialFavourites.contains(ticker) { favStockList.append(stock) }
                    DispatchQueue.main.async {
                        self.stocksTable.reloadData()
                    }
                } else {
                    print("Did not find any information for ticker \(ticker)")
                }
            }
        }
        
        queue.addBarrierBlock {
            DispatchQueue.main.async {
                self.stocksTable.reloadData()
            }
        }
        
        DispatchQueue.global().async {
            for ticker in initialFavourites {
                if !initialStockList.contains(ticker) {
                    if let stock = loadStockDataFromURL(ticker: ticker) {
                        favStockList.append(stock)
                        DispatchQueue.main.async {
                            self.stocksTable.reloadData()
                        }
                    } else {
                        print("Did not find any information for ticker \(ticker)")
                    }
                }
            }
            favStockList.sort(by: { $0.ticker < $1.ticker })
        }
        
        // print(stockList[0].currency)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        suggestionsView.isHidden = true
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let cell = sender as? StocksTableCell {
            let _ = self.stocksTable.indexPath(for: cell)!.row
            if segue.identifier == "toStockCard" {
                let vc = segue.destination as! StockCardVC
                vc.stock = cell.stock
                vc.delegate = self
            }
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchBar.endEditing(true)
    }
    
    // adds to favourites if the stock is not there and removes if it is
    func modifyFavourites(stock: Stock) {
        if var allFavourites = UserDefaults.standard.object(forKey: "fav") as? [String] {
            if allFavourites.contains(stock.ticker) {
                allFavourites.remove(at: allFavourites.firstIndex(of: stock.ticker)!)
                favStockList.remove(at: favStockList.firstIndex(where: { $0.ticker == stock.ticker })!)
            } else {
                allFavourites.append(stock.ticker)
                favStockList.append(stock)
            }
            
            favStockList.sort(by: { $0.ticker < $1.ticker })
            UserDefaults.standard.setValue(allFavourites, forKey: "fav")
        } else {
            UserDefaults.standard.setValue([stock.ticker], forKey: "fav")
            favStockList.append(stock)
        }
        
        self.stocksTable.reloadData()
    }
    
    func filterFav(with text: String) {
        
        filteredFavouritesList = favStockList.filter { $0.companyName.lowercased().contains(text.lowercased()) }
        
        if filteredFavouritesList.count == 0 {
            stocksTable.showMessage("Nothing Found")
        }
        
    }
    
    func modifySearchBar(s: String) {
        searchBar.text = s
        searchBarSearchButtonClicked(searchBar)
    }
    
    func performSearch(for request: String) {
        var success = false
        suggestionsView.isHidden = true
        searchViewMode = true
        searchStockList = []
        stocksTable.showActivityIndicator()
        stocksTable.reloadData()
        
        if request.count != 0 {
            if (workItem != nil) {
                workItem!.cancel()
            }
            
            workItem = DispatchWorkItem {
                search(by: request, task: self.workItem!, completion: { data in
                    if let result = data {
                        self.searchStockList = result
                        self.stocksTable.eraseBG()
                        success = true
                    }
                    DispatchQueue.main.async {
                        if !success {
                            self.stocksTable.showMessage("Nothing Found")
                            self.searchStockList = []
                        }
                        self.stocksTable.reloadData()
                    }
                })
            }
            DispatchQueue.global(qos: .utility).async(execute: workItem!)
        }
    }
    
    @IBAction func onFavouritesClicked(_ sender: Any) {
        favouriteViewMode = true
        
        if searchViewMode {
            stocksTable.eraseBG()
            filterFav(with: searchBar.text!)
        }
        
        self.favouriteButton.setTitleColor(.black, for: .normal)
        self.favouriteButton.titleLabel!.font = UIFont(name: "Montserrat Bold", size: 30.0)
        self.stocksButton.setTitleColor(.secondaryLabel, for: .normal)
        self.stocksButton.titleLabel!.font = UIFont(name: "Montserrat Bold", size: 20.0)
        
        stocksTable.reloadData()
    }
    
    @IBAction func onStocksClicked(_ sender: Any) {
        favouriteViewMode = false
        
        if searchViewMode {
            if searchBar.text!.count == 0 { suggestionsView.isHidden = false }
            else { performSearch(for: searchBar.text!) }
        }
        
        self.stocksButton.setTitleColor(.black, for: .normal)
        self.stocksButton.titleLabel!.font = UIFont(name: "Montserrat Bold", size: 30.0)
        self.favouriteButton.setTitleColor(.secondaryLabel, for: .normal)
        self.favouriteButton.titleLabel!.font = UIFont(name: "Montserrat Bold", size: 20.0)
        
        stocksTable.reloadData()
    }
}

extension ViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if !favouriteViewMode { suggestionsView.isHidden = false }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // print(searchBar.text)
        stocksTable.eraseBG()
        
        if favouriteViewMode {
            searchViewMode = true
            if searchBar.text!.count == 0 { filteredFavouritesList = favStockList }
            else { filterFav(with: searchBar.text!) }
            stocksTable.reloadData()
            return
        }
        
        if searchBar.text!.count == 0 {
            suggestionsView.isHidden = false
        } else {
            suggestionsView.isHidden = true
            performSearch(for: searchBar.text!)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let request = searchBar.text {
            searchBar.endEditing(true)
            addToHistory(s: request)
            historyTickers = getAllHistoryTickers()
            historyCollection.reloadData()
            performSearch(for: request)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchViewMode = false
        searchBar.text = ""
        self.searchBar.endEditing(true)
        suggestionsView.isHidden = true
        stocksTable.reloadData()
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == historyCollection { return historyTickers.count }
        return popularTickers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath) as? SuggestionsCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.delegate = self
        
        if collectionView == popularRequestsCollection {
            cell.styleItem(text: popularTickers[indexPath.row])
        } else {
            cell.styleItem(text: historyTickers[indexPath.row])
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let _ = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath) as? SuggestionsCollectionViewCell else {
            return CGSize.zero
        }
        let font = UIFont(name: "Montserrat Bold", size: 16.0)
        let fontAttributes = [NSAttributedString.Key.font: font]
        
        var size: CGSize!
        if collectionView == popularRequestsCollection {
            size = popularTickers[indexPath.row].size(withAttributes: fontAttributes as [NSAttributedString.Key : Any])
        } else {
            size = historyTickers[indexPath.row].size(withAttributes: fontAttributes as [NSAttributedString.Key : Any])
        }
        
        size.width += 25
        size.height += 20
        return size
    }
    
}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if favouriteViewMode && searchViewMode { return filteredFavouritesList.count }
        else if favouriteViewMode { return favStockList.count }
        else if searchViewMode { return searchStockList.count }
        return stockList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let stockCell = tableView.dequeueReusableCell(withIdentifier: "stockCell", for: indexPath) as? StocksTableCell else {
            return UITableViewCell()
        }
        
        var stock: Stock!
        
        if favouriteViewMode && searchViewMode { stock = filteredFavouritesList[indexPath.row] }
        else if favouriteViewMode { stock = favStockList[indexPath.row] }
        else if searchViewMode { stock = searchStockList[indexPath.row] }
        else { stock = stockList[indexPath.row] }
        
        if indexPath.row % 2 == 0 {
            stockCell.backgroundColor = UIColor(hex: "#f0f4f7")
        }
        stockCell.layer.cornerRadius = 20
        
        stockCell.delegate = self
        stockCell.stock = stock
        
        if isFavourite(ticker: stock.ticker) {
            stockCell.favouriteButton.setImage(UIImage(named: "yellow_star"), for: .normal)
        } else {
            stockCell.favouriteButton.setImage(UIImage(named: "grey_star"), for: .normal)
        }
        
        stockCell.dayShiftLabel.textColor = stock.shiftColor()
        
        stockCell.tickerLabel.text = stock.ticker
        stockCell.companyNameLabel.text = stock.companyName
        stockCell.currentPriceLabel.text = stock.formatCurrentPrice()
        stockCell.dayShiftLabel.text = stock.formatShift()
        stockCell.companyImage.image = stock.icon
        
        return stockCell
    }
    
}

