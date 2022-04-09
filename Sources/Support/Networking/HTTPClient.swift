import Foundation

/// Provides an asynchronous API for making network request calls against a specific remote.
///
/// Each instance of `HTTPClient` is configured to talk to a specific remote (e.g. on a certain remote host and path, and has the necessary auth credentials).
/// The `HTTPClient` may perform app-specific behaviours. For example, it may perform additional security checks, or collect metrics around network failures.
///
/// Normally, how the client performs a request is opaque to the caller. However, specific implementations in an app may define additional behaviour.
public protocol HTTPClient {
    
    /// Performs the `request` and returns the result.
    ///
    /// There are two different reasons the operation may fail:
    /// * The `HTTPClient` itself may reject the request. For example, as a security measure, it may disallow any requests that override the auth token.
    ///   In these cases, the client will return ``HTTPRequestError/rejectedRequest(underlyingError:)``.
    /// * The `HTTPClient` attempts to perform the request, but it fails for other reasons. For example, the network connect might time out, or the response may fail integrity checks done by the client.
    ///   In these cases, the client will return ``HTTPRequestError/networkFailure(underlyingError:)``.
    ///
    /// Note that receiving an HTTP reponse with an error code (e.g. 500) does not normally cause a failure result on this API.
    /// Consumers of this API should check for any HTTP failures and process the response accordingly.
    ///
    /// - Parameter request: The request to perform
    /// - Returns: The result of the operation
    func perform(_ request: HTTPRequest) async -> Result<HTTPResponse, HTTPRequestError>
}

/// Use ``HTTPClient`` instead.
@available(*, deprecated, renamed: "HTTPClient")
public typealias AsyncHTTPClient = HTTPClient

extension HTTPClient {
    
    func fetch<E: HTTPEndpoint>(_ endpoint: E, with input: E.Input) async -> Result<E.Output, NetworkRequestError> {
        await Result { try endpoint.request(for: input) }
            .mapError(NetworkRequestError.badInput)
            .flatMap { request in
                await perform(request)
                    .mapError(NetworkRequestError.init)
            }
            .flatMap { response in
                switch response.statusCode {
                case 200 ..< 300:
                    return Result { try endpoint.parse(response) }
                        .mapError(NetworkRequestError.badResponse)
                default:
                    return .failure(.httpError(response: response))
                }
            }
    }
    
}
