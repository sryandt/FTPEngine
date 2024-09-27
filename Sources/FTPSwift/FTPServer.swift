//
//  FTPServer.swift
//
//
//  Created by Ben Gottlieb on 8/17/24.
//

import Foundation
import FTPEngine
import Suite

public enum FTPServerError: Error {
	case busy, badListResultError, noData, noDestinationURL
}

public class FTPServer: NSObject, FTPRequestsManagerDelegate {
	var manager: FTPRequestsManager
	
	var listContinuation: CheckedContinuation<[FileInfo], Error>?
	var downloadContinuation: CheckedContinuation<Data, Error>?
	var uploadContinuation: CheckedContinuation<Void, Error>?

	var localDownloadDestination: URL?
	var localUploadSource: URL?
	var requestedDirectoryName = ""

	var downloadProgress: ((Double) -> Void)?
	var uploadProgress: ((Double) -> Void)?

	public init?(host: String, user: String, password: String) {
		guard let mgr = FTPRequestsManager(hostname: host, user: user, password: password) else { return nil }
		self.manager = mgr
		super.init()
		
		manager.delegate = self
	}

	public func deleteFile(at path: String) async throws {
		let _: Void = try await withCheckedThrowingContinuation { continuation in
			manager.addRequestForDeleteFile(atPath: path)
			manager.startProcessingRequests()
			continuation.resume()
		}
	}


	public func deleteFile(_ file: FileInfo) async throws {
		let _: Void = try await withCheckedThrowingContinuation { continuation in
			manager.addRequestForDeleteFile(atPath: file.path)
			manager.startProcessingRequests()
			continuation.resume()
		}
	}

	public func createDirectory(at path: String) async throws {
		let _: Void = try await withCheckedThrowingContinuation { continuation in
			manager.addRequestForCreateDirectory(atPath: path)
			manager.startProcessingRequests()
			continuation.resume()
		}
	}

	public func requestFileList(at path: String) async throws -> [FileInfo] {
		if listContinuation != nil { throw FTPServerError.busy }
		
		requestedDirectoryName = path
		return try await withCheckedThrowingContinuation { continuation in
			self.listContinuation = continuation
			
			manager.addRequestForListDirectory(atPath: path)
			manager.startProcessingRequests()
		}
	}
	
	public func requestFile(at path: String, progress: ((Double) -> Void)? = nil) async throws -> Data {
		if downloadContinuation != nil { throw FTPServerError.busy }
		
		self.downloadProgress = progress
		return try await withCheckedThrowingContinuation { continuation in
			self.downloadContinuation = continuation
			localDownloadDestination = URL.cache(named: UUID().uuidString).appendingPathExtension(path.pathExtension ?? "dat")
			
			manager.addRequestForDownloadFile(atRemotePath: path, toLocalPath: localDownloadDestination!.path)
			manager.startProcessingRequests()
		}
	}
	
	public func requestFile(_ file: FileInfo, progress: ((Double) -> Void)? = nil) async throws -> Data {
		try await requestFile(at: file.path, progress: progress)
	}
	
	public func uploadFile(_ data: Data, to path: String, progress: ((Double) -> Void)? = nil) async throws {
		if uploadContinuation != nil { throw FTPServerError.busy }
		
		self.uploadProgress = progress
		localUploadSource = URL.cache(named: UUID().uuidString).appendingPathExtension(path.pathExtension ?? "dat")
		try data.write(to: localUploadSource!)

		return try await withCheckedThrowingContinuation { continuation in
			self.uploadContinuation = continuation
			
			manager.addRequestForUploadFile(atLocalPath: localUploadSource!.path, toRemotePath: path)
			manager.startProcessingRequests()
		}
	}
	
	public func requestsManager(_ requestsManager: (any FTPRequestsManagerProtocol)!, didCompleteListingRequest request: (any FTPRequestProtocol)!, listingDetails: [Any]!) {
		
		if let dicts = listingDetails as? [NSDictionary] {
			listContinuation?.resume(returning: dicts.compactMap { FileInfo($0, directory: requestedDirectoryName) })
		} else {
			listContinuation?.resume(throwing: FTPServerError.badListResultError)
		}
		listContinuation = nil
	}
	
	public func requestsManager(_ requestsManager: (any FTPRequestsManagerProtocol)!, didCompletePercent percent: Float, forRequest request: (any FTPRequestProtocol)!) {
		
		if request is FTPDownloadRequest { downloadProgress?(Double(percent)) }
		if request is FTPUploadRequest { uploadProgress?(Double(percent)) }
	}
	
	public func requestsManager(_ requestsManager: (any FTPRequestsManagerProtocol)!, didCompleteDownloadRequest request: (any FTPDataExchangeRequestProtocol)!) {
		defer {
			downloadProgress = nil
		}

		do {
			guard let localDownloadDestination else {
				downloadContinuation?.resume(throwing: FTPServerError.noDestinationURL)
				downloadContinuation = nil
				return
			}
			let data = try Data(contentsOf: localDownloadDestination)
			downloadContinuation?.resume(returning: data)
		} catch {
			downloadContinuation?.resume(throwing: error)
		}
		downloadContinuation = nil
	}
	
	public func requestsManager(_ requestsManager: (any FTPRequestsManagerProtocol)!, didCompleteUploadRequest request: (any FTPDataExchangeRequestProtocol)!) {
		
		uploadContinuation?.resume()
		uploadContinuation = nil
		uploadProgress = nil
	}

	public func requestsManager(_ requestsManager: (any FTPRequestsManagerProtocol)!, didFailRequest request: (any FTPRequestProtocol)!, withError error: (any Error)!) {
		
		if let listContinuation {
			listContinuation.resume(throwing: error)
			self.listContinuation = nil
		}

		if let downloadContinuation {
			downloadContinuation.resume(throwing: error)
			self.downloadContinuation = nil
			downloadProgress = nil
		}

		if let uploadContinuation {
			uploadContinuation.resume(throwing: error)
			self.uploadContinuation = nil
			uploadProgress = nil
		}
	}
}

