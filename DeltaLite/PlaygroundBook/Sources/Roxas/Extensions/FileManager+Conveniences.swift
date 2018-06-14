//
//  FileManager+Conveniences.swift
//  Book_Sources
//
//  Created by Riley Testut on 6/13/18.
//

import Foundation

extension FileManager
{
    func uniqueTemporaryURL() -> URL
    {
        let url = self.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        return url
    }
}
