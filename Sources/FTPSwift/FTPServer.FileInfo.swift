//
//  FTPServer.RemoteFileInfo.swift
//  FTPEngine
//
//  Created by Ben Gottlieb on 8/18/24.
//

import Suite

extension FTPServer {
	public struct FileInfo: Codable, CustomStringConvertible {
		public let path: String
		public let name: String
		public let isDirectory: Bool
		public let size: Int64?
		public let modificationDate: Date?
		
		init?(_ dictionary: NSDictionary, directory: String) {
			guard let incomingName = dictionary["kCFFTPResourceName"] as? String,
					let incomingSize = dictionary["kCFFTPResourceSize"] as? Int64 else {
				return nil
			}

			let incomingIsDirectory = (dictionary["kCFFTPResourceType"] as? Int) == 4

			path = directory + "/" + incomingName
			name = incomingName
			isDirectory = incomingIsDirectory
			size = incomingIsDirectory ? nil : incomingSize
			modificationDate = dictionary["kCFFTPResourceModDate"] as? Date
		}
		
		public var description: String {
			"\(name)   \(isDirectory ? "D" : "-")  \(size?.formatted() ?? "")  \(modificationDate?.formatted() ?? "")"
		}
	}
}
