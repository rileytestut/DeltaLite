//
//  ViewController.swift
//  LiveViewTestApp
//
//  Created by Riley Testut on 6/12/18.
//

import UIKit
import MobileCoreServices
import CoreImage

import PlaygroundSupport

import Book_Sources

class ViewController: UIViewController
{
    var game: Game?
}

private extension ViewController
{
    @IBAction func chooseGame()
    {
        let documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeItem as String], in: .import)
        documentPicker.delegate = self
        self.present(documentPicker, animated: true)
    }
    
    @IBAction func chooseNoFilter()
    {
        Settings.shared.gameFilter = nil
        
        if let game = self.game
        {
            self.play(game)
        }
    }
    
    @IBAction func chooseBlurFilter()
    {
        Settings.shared.gameFilter = .blur(radius: 5)
        
        if let game = self.game
        {
            self.play(game)
        }
    }
    
    @IBAction func chooseSepiaFilter()
    {
        Settings.shared.gameFilter = .sepia(intensity: 1)
        
        if let game = self.game
        {
            self.play(game)
        }
    }
    
    @IBAction func chooseInvertFilter()
    {
        Settings.shared.gameFilter = .invert
        
        if let game = self.game
        {
            self.play(game)
        }
    }
    
    @IBAction func chooseGrayscaleFilter()
    {
        Settings.shared.gameFilter = .grayscale(intensity: 1)
        
        if let game = self.game
        {
            self.play(game)
        }
    }
    
    @IBAction func chooseCustomFilter()
    {
        let ciFilter = CIFilter(name: "CICrystallize", withInputParameters: ["inputRadius": 5])!
        
        Settings.shared.gameFilter = .custom(ciFilter: ciFilter)
        
        if let game = self.game
        {
            self.play(game)
        }
    }
    
    func play(_ game: Game)
    {
        self.game = game
        
        do
        {
            let bookmark = try game.fileURL.bookmarkData()
            let settingsData = try PropertyListEncoder().encode(Settings.shared)
            AppDelegate.liveView?.receive(.dictionary(["game": .data(bookmark), "settings": .data(settingsData)]))
        }
        catch
        {
            print(error)
        }
    }
}

extension ViewController: UIDocumentPickerDelegate
{
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL])
    {
        guard let gameURL = urls.first else { return }
        
        let game = Game(fileURL: gameURL, type: .nes)
        self.play(game)
    }
}
