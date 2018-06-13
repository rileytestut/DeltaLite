//
//  ViewController.swift
//  LiveViewTestApp
//
//  Created by Riley Testut on 6/12/18.
//

import UIKit
import MobileCoreServices

import PlaygroundSupport

import Book_Sources

class ViewController: UIViewController
{
}

private extension ViewController
{
    @IBAction func chooseGame()
    {
        let documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeItem as String], in: .import)
        documentPicker.delegate = self
        self.present(documentPicker, animated: true)
    }
    
    func play(_ game: Game)
    {
        do
        {
            let bookmark = try game.fileURL.bookmarkData()
            AppDelegate.liveView?.receive(.data(bookmark))
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
