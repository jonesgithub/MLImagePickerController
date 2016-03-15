//
//  MLImagePickerController.swift
//  MLImagePickerController
//
//  Created by zhanglei on 16/3/14.
//  Copyright © 2016年 zhanglei. All rights reserved.
//

import UIKit
import Photos

class MLImagePickerController:  UIViewController,
                                UICollectionViewDataSource,
                                UICollectionViewDelegate,
                                MLImagePickerAssetsCellDelegate,
                                UITableViewDataSource,
                                UITableViewDelegate
{
    
    var assets:NSMutableArray = []
    var collectionView:UICollectionView?
    let CELL_MARGIN:CGFloat = 2
    let CELL_ROW:CGFloat = 3
    let selectAssets:NSMutableArray = []
    let photoIdentifiers:NSMutableArray = []
    var groupTableView:UITableView?
    var groupSectionFetchResults:NSMutableArray = []
    var messageLbl:UILabel!
    
    func show(vc:UIViewController!){
        let imagePickerVc = MLImagePickerController()
        let navigationVc = UINavigationController(rootViewController: imagePickerVc)
        vc.presentViewController(navigationVc, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let options:PHFetchOptions = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result:PHFetchResult = PHAsset.fetchAssetsWithOptions(options)
        
        let imageManager:PHCachingImageManager = PHCachingImageManager()

        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .FastFormat
        requestOptions.networkAccessAllowed = true

        for (var i = 0; i < result.count; i++){
            let asset:PHAsset = result[i] as! PHAsset
            
            self.photoIdentifiers.addObject(asset.localIdentifier)
            imageManager.requestImageForAsset(asset, targetSize: CGSizeMake(100, 100), contentMode: .AspectFit, options: requestOptions) { (let image, let info:[NSObject : AnyObject]?) -> Void in
                
                if image != nil {
                    self.assets.addObject(image!)
                    self.collectionView?.reloadData()
                }
            }
            
        }
        
        self.view.backgroundColor = UIColor.whiteColor()
        self.setupNavigationBar()
        self.setupCollectionView()
    }
    
    func setupNavigationBar(){
        let btn = UIButton(type: .Custom)
        btn.titleLabel?.font = UIFont.systemFontOfSize(15)
        btn.setTitleColor(UIColor.grayColor(), forState: .Normal)
        btn.setTitle("所有图片", forState: .Normal)
        btn.addTarget(self, action: "tappenTitleView", forControlEvents: .TouchUpInside)
        self.navigationItem.titleView = btn
    }
    
    func setupCollectionView(){
        let width = (self.view.frame.size.width - CELL_MARGIN * CELL_ROW + 1) / CELL_ROW;
        
        let collectionViewFlowLayout = UICollectionViewFlowLayout()
        collectionViewFlowLayout.scrollDirection = .Vertical
        collectionViewFlowLayout.minimumInteritemSpacing = 0
        collectionViewFlowLayout.minimumLineSpacing = 2
        collectionViewFlowLayout.itemSize = CGSizeMake(width, width)
        
        let assetsCollectionView = UICollectionView(frame: CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height), collectionViewLayout: collectionViewFlowLayout)
        assetsCollectionView.registerNib(UINib(nibName: "MLImagePickerAssetsCell", bundle: nil), forCellWithReuseIdentifier: "MLImagePickerAssetsCell")
        assetsCollectionView.backgroundColor = UIColor.clearColor()
        assetsCollectionView.dataSource = self
        assetsCollectionView.delegate = self
        self.view.addSubview(assetsCollectionView)
        self.collectionView = assetsCollectionView
    }
    
    func setupGroupTableView(){
        if (self.groupTableView != nil){
            UIView.animateWithDuration(0.15, animations: { () -> Void in
                self.groupTableView?.alpha = (self.groupTableView?.alpha == 1.0) ? 0.0 : 1.0
            })
            
        }else{
            let groupTableView = UITableView(frame: CGRectMake(0, 64, self.view.frame.width, 300), style: .Plain)
            groupTableView.registerNib(UINib(nibName: "MLImagePickerGroupCell", bundle: nil), forCellReuseIdentifier: "MLImagePickerGroupCell")
            groupTableView.separatorStyle = .None
            groupTableView.alpha = 0.0
            groupTableView.dataSource = self
            groupTableView.delegate = self
            self.view.addSubview(groupTableView)
            self.groupTableView = groupTableView
            
            let options:PHFetchOptions = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            let allPhotos:PHFetchResult = PHAsset.fetchAssetsWithOptions(options)
            let smartAlbums:PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(.SmartAlbum, subtype: .AlbumRegular, options: nil)
            let userCollections:PHFetchResult = PHCollectionList.fetchTopLevelUserCollectionsWithOptions(nil)
            self.groupSectionFetchResults = [allPhotos, smartAlbums, userCollections]
            
            UIView.animateWithDuration(0.15, animations: { () -> Void in
                self.groupTableView?.alpha = (self.groupTableView?.alpha == 1.0) ? 0.0 : 1.0
            })
        }
    }
    
    func tappenTitleView(){
        self.setupGroupTableView()
    }
    
    // MARK: UICollectionViewDataSource
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (self.assets.count > 0) ? self.assets.count : 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell:MLImagePickerAssetsCell = collectionView.dequeueReusableCellWithReuseIdentifier("MLImagePickerAssetsCell", forIndexPath: indexPath) as! MLImagePickerAssetsCell
        
        cell.delegate = self
        cell.indexPath = indexPath
        cell.localIdentifier = self.photoIdentifiers[indexPath.item] as! String
        cell.selectButtonSelected = self.selectAssets.containsObject(cell.localIdentifier)
        cell.imageV.image = self.assets[indexPath.item] as? UIImage
        
        return cell
    }
    
    // MARK TableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.groupSectionFetchResults.count
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            let result:PHFetchResult = self.groupSectionFetchResults[section] as! PHFetchResult
            return result.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let fetchResult:PHFetchResult = self.groupSectionFetchResults[indexPath.section] as! PHFetchResult
        
        let cell:MLImagePickerGroupCell = tableView.dequeueReusableCellWithIdentifier("MLImagePickerGroupCell") as! MLImagePickerGroupCell
        if indexPath.section == 0 {
            cell.titleLbl.text = "所有相册"
            cell.assetCountLbl.text = "\(fetchResult.count)"
        }else{
            let collection:PHAssetCollection = fetchResult[indexPath.row] as! PHAssetCollection
            let result:PHFetchResult = PHAsset.fetchAssetsInAssetCollection(collection, options: nil)
            cell.titleLbl.text = collection.localizedTitle
            cell.assetCountLbl.text = "\(result.count)"
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        self.setupGroupTableView()
        
        var fetchResult:PHFetchResult = self.groupSectionFetchResults[indexPath.section] as! PHFetchResult
        if indexPath.section == 0 {

            let imageManager:PHCachingImageManager = PHCachingImageManager()
            let requestOptions = PHImageRequestOptions()
            requestOptions.deliveryMode = .FastFormat
            requestOptions.networkAccessAllowed = true

            self.photoIdentifiers.removeAllObjects()
            self.assets.removeAllObjects()
            self.showWatting()
            
            for (var i = 0; i < fetchResult.count; i++){
                let asset:PHAsset = fetchResult[i] as! PHAsset
                self.photoIdentifiers.addObject(asset.localIdentifier)
                imageManager.requestImageForAsset(asset, targetSize: CGSizeMake(100, 100), contentMode: .AspectFit, options: requestOptions) { (let image, let info:[NSObject : AnyObject]?) -> Void in
                    
                    if image != nil {
                        self.assets.addObject(image!)
                    }
                    
                    if self.assets.count == fetchResult.count {
                        self.hideWatting()
                        self.collectionView?.reloadData()
                    }
                }
            }
        }else{
            let collection:PHAssetCollection = fetchResult[indexPath.row] as! PHAssetCollection
            fetchResult = PHAsset.fetchAssetsInAssetCollection(collection, options: nil)
            
            let imageManager:PHCachingImageManager = PHCachingImageManager()
            let requestOptions = PHImageRequestOptions()
            requestOptions.deliveryMode = .FastFormat
            requestOptions.networkAccessAllowed = true
            
            self.photoIdentifiers.removeAllObjects()
            self.assets.removeAllObjects()
            self.showWatting()
            
            for (var i = 0; i < fetchResult.count; i++){
                let asset:PHAsset = fetchResult[i] as! PHAsset
                self.photoIdentifiers.addObject(asset.localIdentifier)
                imageManager.requestImageForAsset(asset, targetSize: CGSizeMake(100, 100), contentMode: .AspectFit, options: requestOptions) { (let image, let info:[NSObject : AnyObject]?) -> Void in
                    
                    if image != nil {
                        self.assets.addObject(image!)
                    }
                    
                    if self.assets.count == fetchResult.count {
                        self.hideWatting()
                        self.collectionView?.reloadData()
                    }
                }
            }
        }
        
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }
    
    func imagePickerSelectAssetsCellWithSelected(indexPath: NSIndexPath, selected: Bool) {
        let identifier = self.photoIdentifiers[indexPath.item]
        if selected == true {
            self.selectAssets.addObject(identifier)
        }else{
            self.selectAssets.removeObject(identifier)
        }
    }
    
    func showWatting(){
        self.collectionView!.userInteractionEnabled = false
        if self.messageLbl != nil {
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                self.messageLbl.alpha = 1.0
            })
        }else {
            let width:CGFloat = 100
            let height:CGFloat = 35
            let x:CGFloat = (self.view.frame.width - width) * 0.5
            let y:CGFloat = (self.view.frame.height - height) * 0.5
            let messageLbl:UILabel = UILabel(frame: CGRectMake(x,y,width,height))
            messageLbl.layer.masksToBounds = true
            messageLbl.layer.cornerRadius = 5.0
            messageLbl.textAlignment = .Center
            messageLbl.text = "加载中..."
            messageLbl.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
            messageLbl.textColor = UIColor.whiteColor()
            self.view.addSubview(messageLbl)
            self.messageLbl = messageLbl
        }
    }
    
    func hideWatting(){
        self.collectionView!.userInteractionEnabled = true
        UIView.animateWithDuration(0.25) { () -> Void in
            self.messageLbl.alpha = 0.0
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
    }
}
