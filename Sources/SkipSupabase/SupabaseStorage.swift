// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import Foundation

#if !SKIP
@_exported import Supabase
#else
import io.github.jan.supabase.storage.Storage
import io.github.jan.supabase.storage.storage
import io.github.jan.supabase.storage.__
import io.github.jan.supabase.storage.BucketBuilder
import io.github.jan.supabase.auth.minimalSettings

import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
#endif

#if SKIP
// SKIP NOWARN
// This extension will be moved into its extended type definition when translated to Kotlin. It will not be able to access this file's private types or fileprivate members
extension SupabaseClient {
    public var storage: SupabaseStorageClient {
        SupabaseStorageClient(storage: client.storage)
    }
}

public class StorageApi: @unchecked Sendable {
//    public let configuration: StorageClientConfiguration
//
//    public init(configuration: StorageClientConfiguration) {
//    }
}

/// Storage Bucket API
public class StorageBucketApi: StorageApi, @unchecked Sendable {
    fileprivate let storage: io.github.jan.supabase.storage.Storage
    //public let configuration: StorageClientConfiguration

    init(storage: io.github.jan.supabase.storage.Storage) {
        self.storage = storage

        //var configuration = configuration
        //    if configuration.headers["X-Client-Info"] == nil {
        //      configuration.headers["X-Client-Info"] = "storage-swift/\(version)"
        //    }
        //self.configuration = configuration
    }

    /// Retrieves the details of all Storage buckets within an existing project.
    public func listBuckets() async throws -> [Bucket] {
        // SKIP NOWARN
        try await Array(storage.retrieveBuckets()).map({ Bucket(bucket: $0) })
    }

    /// Retrieves the details of an existing Storage bucket.
    /// - Parameters:
    ///   - id: The unique identifier of the bucket you would like to retrieve.
    public func getBucket(_ id: String) async throws -> Bucket {
        // SKIP NOWARN
        guard let bucket = storage.retrieveBucketById(id) else {
            throw BucketNotFoundError(localizedDescription: "No such bucket: \(id)")
        }
        try await Bucket(bucket: bucket)
    }

    /// Creates a new Storage bucket.
    /// - Parameters:
    ///   - id: A unique identifier for the bucket you are creating.
    ///   - options: Options for creating the bucket.
    public func createBucket(_ id: String, options: BucketOptions = .init()) async throws {
        // SKIP NOWARN
        try await storage.createBucket(id) {
            `public` = options.`public`
            if let size = options.fileSizeLimit {
                // let limit =  io.github.jan.supabase.storage.FileSizeLimit(string) // internal-only
                // so we need to use the extension defined in https://github.com/supabase-community/supabase-kt/blob/master/Storage/src/commonMain/kotlin/io/github/jan/supabase/storage/BucketBuilder.kt
                if size.hasSuffix("gb"), let limit = Long(size.dropLast(2)) {
                    fileSizeLimit = limit.gigabytes
                } else if size.hasSuffix("mb"), let limit = Long(size.dropLast(2)) {
                    fileSizeLimit = limit.megabytes
                } else if size.hasSuffix("kb"), let limit = Long(size.dropLast(2)) {
                    fileSizeLimit = limit.kilobytes
                } else if size.hasSuffix("b"), let limit = Long(size.dropLast(1)) {
                    fileSizeLimit = limit.bytes
                }
            }
            if let mimes = options.allowedMimeTypes {
                allowedMimeTypes(mimeTypes: mimes.toList())
            }
        }
    }

    /// Updates a Storage bucket.
    /// - Parameters:
    ///   - id: A unique identifier for the bucket you are updating.
    ///   - options: Options for updating the bucket.
    public func updateBucket(_ id: String, options: BucketOptions) async throws {
        // SKIP NOWARN
        try await storage.updateBucket(id) {
            `public` = options.`public`
            if let size = options.fileSizeLimit {
                // let limit =  io.github.jan.supabase.storage.FileSizeLimit(string) // internal-only
                // so we need to use the extension defined in https://github.com/supabase-community/supabase-kt/blob/master/Storage/src/commonMain/kotlin/io/github/jan/supabase/storage/BucketBuilder.kt
                if size.hasSuffix("gb"), let limit = Long(size.dropLast(2)) {
                    fileSizeLimit = limit.gigabytes
                } else if size.hasSuffix("mb"), let limit = Long(size.dropLast(2)) {
                    fileSizeLimit = limit.megabytes
                } else if size.hasSuffix("kb"), let limit = Long(size.dropLast(2)) {
                    fileSizeLimit = limit.kilobytes
                } else if size.hasSuffix("b"), let limit = Long(size.dropLast(1)) {
                    fileSizeLimit = limit.bytes
                }
            }
            if let mimes = options.allowedMimeTypes {
                allowedMimeTypes(mimeTypes: mimes.toList())
            }
        }
    }

    /// Removes all objects inside a single bucket.
    /// - Parameters:
    ///   - id: The unique identifier of the bucket you would like to empty.
    public func emptyBucket(_ id: String) async throws {
        // SKIP NOWARN
        try await storage.emptyBucket(id)
    }

    /// Deletes an existing bucket. A bucket can't be deleted with existing objects inside it.
    /// You must first `empty()` the bucket.
    /// - Parameters:
    ///   - id: The unique identifier of the bucket you would like to delete.
    public func deleteBucket(_ id: String) async throws {
        // SKIP NOWARN
        try await storage.deleteBucket(id)
    }
}

public class SupabaseStorageClient: StorageBucketApi, @unchecked Sendable {
    /// Perform file operation in a bucket.
    /// - Parameter id: The bucket id to operate on.
    /// - Returns: StorageFileApi object
    public func from(_ id: String) -> StorageFileApi {
        StorageFileApi(bucket: self.storage.get(id))
    }
}


public struct BucketNotFoundError : Error {
    var localizedDescription: String
}

// TODO: add property support
public struct StorageClientConfiguration: Sendable {

    // public let url: URL
    // public var headers: [String: String]
    //  public let encoder: JSONEncoder
    //  public let decoder: JSONDecoder
    //public let session: StorageHTTPSession
    //public let logger: (any SupabaseLogger)?

    public init(
        //url: URL,
        //headers: [String: String]
        //    encoder: JSONEncoder = .defaultStorageEncoder,
        //    decoder: JSONDecoder = .defaultStorageDecoder,
        //session: StorageHTTPSession = .init(),
        //logger: (any SupabaseLogger)? = nil
    ) {
        // self.url = url
        //self.headers = headers
        //    self.encoder = encoder
        //    self.decoder = decoder
        //self.session = session
        //self.logger = logger
    }
}

enum FileUpload {
    case data(Data)
    case url(URL)
}

/// Supabase Storage File API
public class StorageFileApi: StorageApi, @unchecked Sendable {
    let bucket: io.github.jan.supabase.storage.BucketApi

    /// The bucket id to operate on.
    //let bucketId: String

    init(bucket: io.github.jan.supabase.storage.BucketApi) {
        super.init()
        self.bucket = bucket
    }

    /// Uploads a file to an existing bucket.
    /// - Parameters:
    ///   - path: The relative file path. Should be of the format `folder/subfolder/filename.png`. The bucket must already exist before attempting to upload.
    ///   - data: The Data to be stored in the bucket.
    ///   - options: The options for the uploaded file.
    @discardableResult
    public func upload(
        _ path: String,
        data: Data,
        options: FileOptions = FileOptions()
    ) async throws -> FileUploadResponse {
        // SKIP NOWARN
        FileUploadResponse(path: path, try await bucket.upload(path: path, data: data.kotlin()) {
            upsert = options.upsert
            //cacheControl = options.cacheControl
            if let ctype = options.contentType {
                contentType = io.ktor.http.ContentType.parse(ctype)
            }
            //duplex = options.duplex
            //metadata = options.metadata
            //headers = options.headers
        })
    }

    /// Uploads a file to an existing bucket.
    /// - Parameters:
    ///   - path: The relative file path. Should be of the format `folder/subfolder/filename.png`. The bucket must already exist before attempting to upload.
    ///   - fileURL: The file URL to be stored in the bucket.
    ///   - options: The options for the uploaded file.
    @available(*, unavailable)
    @discardableResult
    public func upload(
        _ path: String,
        fileURL: URL,
        options: FileOptions = FileOptions()
    ) async throws -> FileUploadResponse {
        fatalError("TODO: upload")
    }

    /// Replaces an existing file at the specified path with a new one.
    /// - Parameters:
    ///   - path: The relative file path. Should be of the format `folder/subfolder`. The bucket already exist before attempting to upload.
    ///   - data: The Data to be stored in the bucket.
    ///   - options: The options for the updated file.
    @discardableResult
    public func update(
        _ path: String,
        data: Data,
        options: FileOptions = FileOptions()
    ) async throws -> FileUploadResponse {
        // SKIP NOWARN
        FileUploadResponse(path: path, try await bucket.update(path: path, data: data.kotlin()) {
            upsert = options.upsert
            if let ctype = options.contentType {
                contentType = io.ktor.http.ContentType.parse(ctype)
            }
        })
    }

    /// Replaces an existing file at the specified path with a new one.
    /// - Parameters:
    ///   - path: The relative file path. Should be of the format `folder/subfolder`. The bucket already exist before attempting to upload.
    ///   - fileURL: The file URL to be stored in the bucket.
    ///   - options: The options for the updated file.
    @available(*, unavailable)
    @discardableResult
    public func update(
        _ path: String,
        fileURL: URL,
        options: FileOptions = FileOptions()
    ) async throws -> FileUploadResponse {
        fatalError("TODO: update")
    }

    /// Moves an existing file to a new path.
    /// - Parameters:
    ///   - source: The original file path, including the current file name. For example `folder/image.png`.
    ///   - destination: The new file path, including the new file name. For example `folder/image-new.png`.
    ///   - options: The destination options.
    public func move(
        from source: String,
        to destination: String,
        options: DestinationOptions? = nil
    ) async throws {
        // SKIP NOWARN
        try await bucket.move(from: source, to: destination, destinationBucket: options?.destinationBucket)
    }

    /// Copies an existing file to a new path.
    /// - Parameters:
    ///   - source: The original file path, including the current file name. For example `folder/image.png`.
    ///   - destination: The new file path, including the new file name. For example `folder/image-copy.png`.
    ///   - options: The destination options.
    @discardableResult
    public func copy(
        from source: String,
        to destination: String,
        options: DestinationOptions? = nil
    ) async throws -> String {
        // SKIP NOWARN
        try await bucket.copy(from: source, to: destination, destinationBucket: options?.destinationBucket)
        return destination // TODO: is this the right return value?
    }

    /// Creates a signed URL. Use a signed URL to share a file for a fixed amount of time.
    /// - Parameters:
    ///   - path: The file path, including the current file name. For example `folder/image.png`.
    ///   - expiresIn: The number of seconds until the signed URL expires. For example, `60` for a URL which is valid for one minute.
    ///   - download: Trigger a download with the specified file name.
    ///   - transform: Transform the asset before serving it to the client.
    @available(*, unavailable)
    public func createSignedURL(
        path: String,
        expiresIn: Int,
        download: String? = nil,
        transform: TransformOptions? = nil
    ) async throws -> URL {
        // TODO: handle download parameter
        return try await createSignedURL(path: path, expiresIn: expiresIn, download: false, transform: transform)
    }

    /// Creates a signed URL. Use a signed URL to share a file for a fixed amount of time.
    /// - Parameters:
    ///   - path: The file path, including the current file name. For example `folder/image.png`.
    ///   - expiresIn: The number of seconds until the signed URL expires. For example, `60` for a URL which is valid for one minute.
    ///   - download: Trigger a download with the default file name.
    ///   - transform: Transform the asset before serving it to the client.
    public func createSignedURL(
        path: String,
        expiresIn: Int,
        download: Bool,
        transform: TransformOptions? = nil
    ) async throws -> URL {
        // SKIP NOWARN
        URL(string: try await bucket.createSignedUrl(path: path, expiresIn: expiresIn.seconds) {
            if let options = transform {
                quality = options.quality
                format = options.format
                resize = options.resize == "cover" ? ImageTransformation.Resize.COVER : options.resize == "contain" ? ImageTransformation.Resize.CONTAIN : options.resize == "fill" ? ImageTransformation.Resize.FILL : nil
                if let width = options.width, let height = options.height {
                    size(width, height)
                }
            }
        })!
    }

    /// Creates multiple signed URLs. Use a signed URL to share a file for a fixed amount of time.
    /// - Parameters:
    ///   - paths: The file paths to be downloaded, including the current file names. For example `["folder/image.png", "folder2/image2.png"]`.
    ///   - expiresIn: The number of seconds until the signed URLs expire. For example, `60` for URLs which are valid for one minute.
    ///   - download: Trigger a download with the specified file name.
    @available(*, unavailable)
    public func createSignedURLs(
        paths: [String],
        expiresIn: Int,
        download: String? = nil
    ) async throws -> [URL] {
        fatalError("TODO: createSignedURLs")
    }

    /// Creates multiple signed URLs. Use a signed URL to share a file for a fixed amount of time.
    /// - Parameters:
    ///   - paths: The file paths to be downloaded, including the current file names. For example `["folder/image.png", "folder2/image2.png"]`.
    ///   - expiresIn: The number of seconds until the signed URLs expire. For example, `60` for URLs which are valid for one minute.
    ///   - download: Trigger a download with the default file name.
    @available(*, unavailable)
    public func createSignedURLs(
        paths: [String],
        expiresIn: Int,
        download: Bool
    ) async throws -> [URL] {
        fatalError("TODO: createSignedURLs")
        //try await createSignedURLs(paths: paths, expiresIn: expiresIn, download: download ? "" : nil)
    }

    /// Deletes files within the same bucket
    /// - Parameters:
    ///   - paths: An array of files to be deletes, including the path and file name. For example [`folder/image.png`].
    /// - Returns: A list of removed ``FileObject``.
    public func remove(paths: [String]) async throws -> [FileObject] {
        // SKIP NOWARN
        try await bucket.delete(paths: paths.toList())
        return paths.map({ FileObject(name: $0) })
    }

    /// Lists all the files within a bucket.
    /// - Parameters:
    ///   - path: The folder path.
    ///   - options: Search options, including `limit`, `offset`, and `sortBy`.
    public func list(
        path: String? = nil,
        options: SearchOptions? = nil
    ) async throws -> [FileObject] {
        // SKIP NOWARN
        Array(try await bucket.list(prefix: path ?? options?.prefix ?? "") {
            if let options = options {
                limit = options.limit
                offset = options.offset
                search = options.search
                if let sortByColumn = options.sortBy?.column,
                    let sortByOrder = options.sortBy?.order {
                    sortBy(column: sortByColumn, order: sortByOrder)
                }
            }
        }).map({ FileObject(object: $0) })
    }

    /// Downloads a file from a private bucket. For public buckets, make a request to the URL returned
    /// from ``StorageFileApi/getPublicURL(path:download:fileName:options:)`` instead.
    /// - Parameters:
    ///   - path: The file path to be downloaded, including the path and file name. For example `folder/image.png`.
    ///   - options: Transform the asset before serving it to the client.
    @discardableResult
    public func download(
        path: String,
        options: TransformOptions? = nil
    ) async throws -> Data {
        // SKIP NOWARN
        try await Data(platformValue: bucket.downloadAuthenticated(path: path) {
            if let options = options {
                transform {
                    width = options.width
                    height = options.height
                    quality = options.quality
                    format = options.format
                    // resize = options.resize // TODO
                }
            }
        })
    }

    /// Retrieves the details of an existing file.
    /// Needs: https://github.com/supabase-community/supabase-kt/pull/694
    @available(*, unavailable)
    public func info(path: String) async throws -> FileObjectV2 {
        fatalError("TODO: info")
    }

    /// Needs: https://github.com/supabase-community/supabase-kt/pull/694
    /// Checks the existence of file.
    @available(*, unavailable)
    public func exists(path: String) async throws -> Bool {
        fatalError("TODO: exists")
    }

    /// A simple convenience function to get the URL for an asset in a public bucket. If you do not want to use this function, you can construct the public URL by concatenating the bucket URL with the path to the asset. This function does not verify if the bucket is public. If a public URL is created for a bucket which is not public, you will not be able to download the asset.
    /// - Parameters:
    ///  - path: The path and name of the file to generate the public URL for. For example `folder/image.png`.
    ///  - download: Trigger a download with the specified file name.
    ///  - options: Transform the asset before retrieving it on the client.
    ///
    ///  - Note: The bucket needs to be set to public, either via ``StorageBucketApi/updateBucket(_:options:)`` or by going to Storage on [supabase.com/dashboard](https://supabase.com/dashboard), clicking the overflow menu on a bucket and choosing "Make public".
    @available(*, unavailable)
    public func getPublicURL(
        path: String,
        download: String? = nil,
        options: TransformOptions? = nil
    ) throws -> URL {
        // TODO: handle download parameter
        // SKIP NOWARN
        try await getPublicURL(path, download: false, options: options)
    }

    /// A simple convenience function to get the URL for an asset in a public bucket. If you do not want to use this function, you can construct the public URL by concatenating the bucket URL with the path to the asset. This function does not verify if the bucket is public. If a public URL is created for a bucket which is not public, you will not be able to download the asset.
    /// - Parameters:
    ///  - path: The path and name of the file to generate the public URL for. For example `folder/image.png`.
    ///  - download: Trigger a download with the default file name.
    ///  - options: Transform the asset before retrieving it on the client.
    ///
    ///  - Note: The bucket needs to be set to public, either via ``StorageBucketApi/updateBucket(_:options:)`` or by going to Storage on [supabase.com/dashboard](https://supabase.com/dashboard), clicking the overflow menu on a bucket and choosing "Make public".
    public func getPublicURL(
        path: String,
        download: Bool,
        options: TransformOptions? = nil
    ) throws -> URL {
        // SKIP NOWARN
        if let options = options {
            return URL(string: try await bucket.publicRenderUrl(path: path) {
                if let options = options {
                    quality = options.quality
                    format = options.format
                    resize = options.resize == "cover" ? ImageTransformation.Resize.COVER : options.resize == "contain" ? ImageTransformation.Resize.CONTAIN : options.resize == "fill" ? ImageTransformation.Resize.FILL : nil
                    if let width = options.width, let height = options.height {
                        size(width, height)
                    }
                }
            })!
        } else {
            return URL(string: try await bucket.publicUrl(path: path))!
        }
    }

    /// Creates a signed upload URL. Signed upload URLs can be used to upload files to the bucket without further authentication. They are valid for 2 hours.
    /// - Parameter path: The file path, including the current file name. For example `folder/image.png`.
    /// - Returns: A URL that can be used to upload files to the bucket without further
    /// authentication.
    @available(*, unavailable)
    public func createSignedUploadURL(
        path: String,
        options: CreateSignedUploadURLOptions? = nil
    ) async throws -> SignedUploadURL {
        fatalError("TODO: createSignedUploadURL")
    }

    /// Upload a file with a token generated from ``StorageFileApi/createSignedUploadURL(path:)``.
    /// - Parameters:
    ///   - path: The file path, including the file name. Should be of the format `folder/subfolder/filename.png`. The bucket must already exist before attempting to upload.
    ///   - token: The token generated from ``StorageFileApi/createSignedUploadURL(path:)``.
    ///   - data: The Data to be stored in the bucket.
    ///   - options: HTTP headers, for example `cacheControl`.
    /// - Returns: A key pointing to stored location.
    @available(*, unavailable)
    @discardableResult
    public func uploadToSignedURL(
        _ path: String,
        token: String,
        data: Data,
        options: FileOptions? = nil
    ) async throws -> SignedURLUploadResponse {
        fatalError("TODO: uploadToSignedURL")
    }

    /// Upload a file with a token generated from ``StorageFileApi/createSignedUploadURL(path:)``.
    /// - Parameters:
    ///   - path: The file path, including the file name. Should be of the format `folder/subfolder/filename.png`. The bucket must already exist before attempting to upload.
    ///   - token: The token generated from ``StorageFileApi/createSignedUploadURL(path:)``.
    ///   - fileURL: The file URL to be stored in the bucket.
    ///   - options: HTTP headers, for example `cacheControl`.
    /// - Returns: A key pointing to stored location.
    @available(*, unavailable)
    @discardableResult
    public func uploadToSignedURL(
        _ path: String,
        token: String,
        fileURL: URL,
        options: FileOptions? = nil
    ) async throws -> SignedURLUploadResponse {
        try await _uploadToSignedURL(
            path: path,
            token: token,
            file: .url(fileURL),
            options: options
        )
    }

    private func _uploadToSignedURL(
        path: String,
        token: String,
        file: FileUpload,
        options: FileOptions?
    ) async throws -> SignedURLUploadResponse {
        fatalError("TODO: _uploadToSignedURL")

        //    let options = options ?? defaultFileOptions
        //    var headers = options.headers.map { HTTPFields($0) } ?? HTTPFields()
        //
        //    headers[.xUpsert] = "\(options.upsert)"
        //    headers[.duplex] = options.duplex
        //
        //    let formData = MultipartFormData()
        //    file.encode(to: formData, withPath: path, options: options)
        //
        //    struct UploadResponse: Decodable {
        //      let Key: String
        //    }
        //
        //    let fullPath = try await execute(
        //      HTTPRequest(
        //        url: configuration.url
        //          .appendingPathComponent("object/upload/sign/\(bucketId)/\(path)"),
        //        method: .put,
        //        query: [URLQueryItem(name: "token", value: token)],
        //        formData: formData,
        //        options: options,
        //        headers: headers
        //      )
        //    )
        //    .decoded(as: UploadResponse.self, decoder: configuration.decoder)
        //    .Key
        //
        //    return SignedURLUploadResponse(path: path, fullPath: fullPath)
    }
}

//extension HTTPField.Name {
//  static let duplex = Self("duplex")!
//  static let xUpsert = Self("x-upsert")!
//}

public struct BucketOptions: Sendable {
    /// The visibility of the bucket. Public buckets don't require an authorization token to download objects, but still require a valid token for all other operations. Bu default, buckets are private.
    public let `public`: Bool
    /// Specifies the allowed mime types that this bucket can accept during upload. The default value is null, which allows files with all mime types to be uploaded. Each mime type specified can be a wildcard, e.g. image/*, or a specific mime type, e.g. image/png.
    public let fileSizeLimit: String?
    /// Specifies the max file size in bytes that can be uploaded to this bucket. The global file size limit takes precedence over this value. The default value is null, which doesn't set a per bucket file size limit.
    public let allowedMimeTypes: [String]?

    public init(
        public: Bool = false,
        fileSizeLimit: String? = nil,
        allowedMimeTypes: [String]? = nil
    ) {
        self.public = `public`
        self.fileSizeLimit = fileSizeLimit
        self.allowedMimeTypes = allowedMimeTypes
    }
}

/// Transform the asset before serving it to the client.
public struct TransformOptions: Encodable, Sendable {
    /// The width of the image in pixels.
    public var width: Int?
    /// The height of the image in pixels.
    public var height: Int?
    /// The resize mode can be cover, contain or fill. Defaults to cover.
    /// Cover resizes the image to maintain it's aspect ratio while filling the entire width and height.
    /// Contain resizes the image to maintain it's aspect ratio while fitting the entire image within the width and height.
    /// Fill resizes the image to fill the entire width and height. If the object's aspect ratio does not match the width and height, the image will be stretched to fit.
    public var resize: String?
    /// Set the quality of the returned image. A number from 20 to 100, with 100 being the highest quality. Defaults to 80.
    public var quality: Int?
    /// Specify the format of the image requested.
    public var format: String?

    public init(
        width: Int? = nil,
        height: Int? = nil,
        resize: String? = nil,
        quality: Int? = 80,
        format: String? = nil
    ) {
        self.width = width
        self.height = height
        self.resize = resize
        self.quality = quality
        self.format = format
    }

    var queryItems: [URLQueryItem] {
        var items = [URLQueryItem]()

        if let width {
            items.append(URLQueryItem(name: "width", value: String(width)))
        }

        if let height {
            items.append(URLQueryItem(name: "height", value: String(height)))
        }

        if let resize {
            items.append(URLQueryItem(name: "resize", value: resize))
        }

        if let quality {
            items.append(URLQueryItem(name: "quality", value: String(quality)))
        }

        if let format {
            items.append(URLQueryItem(name: "format", value: format))
        }

        return items
    }
}

public struct SearchOptions: Encodable, Sendable {
    var prefix: String

    /// The number of files you want to be returned.
    public var limit: Int?

    /// The starting position.
    public var offset: Int?

    /// The column to sort by. Can be any column inside a ``FileObject``.
    public var sortBy: SortBy?

    /// The search string to filter files by.
    public var search: String?

    public init(
        limit: Int? = nil,
        offset: Int? = nil,
        sortBy: SortBy? = nil,
        search: String? = nil
    ) {
        prefix = ""
        self.limit = limit
        self.offset = offset
        self.sortBy = sortBy
        self.search = search
    }
}

public struct SortBy: Encodable, Sendable {
    public var column: String?
    public var order: String?

    public init(column: String? = nil, order: String? = nil) {
        self.column = column
        self.order = order
    }
}

public struct FileOptions: Sendable {
    /// The number of seconds the asset is cached in the browser and in the Supabase CDN. This is set
    /// in the `Cache-Control: max-age=<seconds>` header. Defaults to 3600 seconds.
    public var cacheControl: String

    /// The `Content-Type` header value.
    public var contentType: String?

    /// When upsert is set to `true`, the file is overwritten if it exists. When set to `false`, an error
    /// is thrown if the object already exists. Defaults to `false`.
    public var upsert: Bool

    /// The duplex option is a string parameter that enables or disables duplex streaming, allowing
    /// for both reading and writing data in the same stream. It can be passed as an option to the
    /// fetch() method.
    public var duplex: String?

    /// The metadata option is an object that allows you to store additional information about the file.
    /// This information can be used to filter and search for files.
    /// The metadata object can contain any key-value pairs you want to store.
    public var metadata: [String: AnyJSON]?

    /// Optionally add extra headers.
    public var headers: [String: String]?

    public init(
        cacheControl: String = "3600",
        contentType: String? = nil,
        upsert: Bool = false,
        duplex: String? = nil,
        metadata: [String: AnyJSON]? = nil,
        headers: [String: String]? = nil
    ) {
        self.cacheControl = cacheControl
        self.contentType = contentType
        self.upsert = upsert
        self.duplex = duplex
        self.metadata = metadata
        self.headers = headers
    }
}

public struct SignedURL: Decodable, Sendable {
    /// An optional error message.
    public var error: String?

    /// The signed url.
    public var signedURL: URL

    /// The path of the file.
    public var path: String

    public init(error: String? = nil, signedURL: URL, path: String) {
        self.error = error
        self.signedURL = signedURL
        self.path = path
    }
}

public struct SignedUploadURL: Sendable {
    public let signedURL: URL
    public let path: String
    public let token: String
}

public struct FileUploadResponse: Sendable {
    public let id: String
    public let path: String
    public let fullPath: String

    // https://github.com/supabase-community/supabase-kt/blob/master/Storage/src/commonMain/kotlin/io/github/jan/supabase/storage/FileUploadResponse.kt
    init(path: String, _ response: io.github.jan.supabase.storage.FileUploadResponse) {
        self.id = response.id!
        self.path = path
        self.fullPath = response.key! // fullPath // no such path
    }
}

public struct SignedURLUploadResponse: Sendable {
    public let path: String
    public let fullPath: String
}

public struct CreateSignedUploadURLOptions: Sendable {
    public var upsert: Bool

    public init(upsert: Bool) {
        self.upsert = upsert
    }
}

public struct DestinationOptions: Sendable {
    public var destinationBucket: String?

    public init(destinationBucket: String? = nil) {
        self.destinationBucket = destinationBucket
    }
}

public struct FileObject: Identifiable, Hashable, Codable, Sendable {
    public var name: String
    public var bucketId: String?
    public var owner: String?
    public var id: UUID?
    public var updatedAt: Date?
    public var createdAt: Date?
    public var lastAccessedAt: Date?
    public var metadata: [String: AnyJSON]?
    public var buckets: Bucket?

    public init(object: io.github.jan.supabase.storage.FileObject) {
        self.name = object.name
        //self.bucketId = object.bucketId
        //self.owner = object.owner
        if let id = object.id {
            self.id = UUID(uuidString: id)
        }
        self.updatedAt = instant2date(object.updatedAt)
        self.createdAt = instant2date(object.createdAt)
        self.lastAccessedAt = instant2date(object.lastAccessedAt)
        //self.metadata = object.metadata
        //self.buckets = object.buckets
    }

    public init(
        name: String,
        bucketId: String? = nil,
        owner: String? = nil,
        id: UUID? = nil,
        updatedAt: Date? = nil,
        createdAt: Date? = nil,
        lastAccessedAt: Date? = nil,
        metadata: [String: AnyJSON]? = nil,
        buckets: Bucket? = nil
    ) {
        self.name = name
        self.bucketId = bucketId
        self.owner = owner
        self.id = id
        self.updatedAt = updatedAt
        self.createdAt = createdAt
        self.lastAccessedAt = lastAccessedAt
        self.metadata = metadata
        self.buckets = buckets
    }

    enum CodingKeys: String, CodingKey {
        case name
        case bucketId = "bucket_id"
        case owner
        case id
        case updatedAt = "updated_at"
        case createdAt = "created_at"
        case lastAccessedAt = "last_accessed_at"
        case metadata
        case buckets
    }
}

public struct FileObjectV2: Identifiable, Hashable, Decodable, Sendable {
    public let id: String
    public let version: String
    public let name: String
    public let bucketId: String?
    public let updatedAt: Date?
    public let createdAt: Date?
    public let lastAccessedAt: Date?
    public let size: Int?
    public let cacheControl: String?
    public let contentType: String?
    public let etag: String?
    public let lastModified: Date?
    public let metadata: [String: AnyJSON]?

    enum CodingKeys: String, CodingKey {
        case id
        case version
        case name
        case bucketId = "bucket_id"
        case updatedAt = "updated_at"
        case createdAt = "created_at"
        case lastAccessedAt = "last_accessed_at"
        case size
        case cacheControl = "cache_control"
        case contentType = "content_type"
        case etag
        case lastModified = "last_modified"
        case metadata
    }
}

public struct Bucket: Identifiable, Hashable, Codable, Sendable {
    public var id: String
    public var name: String
    public var owner: String
    public var isPublic: Bool
    public var createdAt: Date
    public var updatedAt: Date
    public var allowedMimeTypes: [String]?
    public var fileSizeLimit: Int64?

    fileprivate init(bucket: io.github.jan.supabase.storage.Bucket) {
        self.id = bucket.id
        self.name = bucket.name
        self.owner = bucket.owner
        self.isPublic = bucket.public
        self.createdAt = instant2date(bucket.createdAt) ?? .now
        self.updatedAt = instant2date(bucket.updatedAt) ?? .now
        if let mimes = bucket.allowedMimeTypes {
            self.allowedMimeTypes = Array(mimes)
        }
        self.fileSizeLimit = bucket.fileSizeLimit
    }

    public init(
        id: String,
        name: String,
        owner: String,
        isPublic: Bool,
        createdAt: Date,
        updatedAt: Date,
        allowedMimeTypes: [String]? = nil,
        fileSizeLimit: Int64? = nil
    ) {
        self.id = id
        self.name = name
        self.owner = owner
        self.isPublic = isPublic
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.allowedMimeTypes = allowedMimeTypes
        self.fileSizeLimit = fileSizeLimit
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case owner
        case isPublic = "public"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case allowedMimeTypes = "allowed_mime_types"
        case fileSizeLimit = "file_size_limit"
    }
}

#endif

