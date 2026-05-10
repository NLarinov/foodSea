import Foundation

enum APIEndpoint {
    // Auth (core service)
    case register(email: String, password: String)
    case login(email: String, password: String)
    case refresh(token: String)
    case logout
    case oauthStart(provider: String, redirectURI: String)
    case oauthCallback(provider: String, code: String, state: String, redirectURI: String)
    case oauthAppleNative(identityToken: String, fullName: String?, email: String?)
    case oauthYandexSDKCallback(accessToken: String)

    // Products (core service)
    case listProducts(page: Int, perPage: Int, categoryId: String?, subcategoryId: String?, brandId: String?)
    case getProduct(id: String)
    case getProductByBarcode(code: String)
    case getOffers(productId: String)
    case searchProducts(query: String, filters: SearchFilters?)

    // Catalog metadata (core service)
    case listCategories
    case listBrands

    // Cart (core service)
    case getCart
    case addToCart(productId: String, quantity: Int)
    case updateCartItem(productId: String, quantity: Int)
    case removeCartItem(productId: String)
    case clearCart

    // Optimization (optimization service)
    case runOptimization
    case getAnalogs(productId: String)

    // Orders (ordering service)
    case listOrders
    case getOrder(id: String)
    case placeOrder(optimizationResultId: String)

    // Photo search (core service, multipart)
    case photoSearch

    // Voice (core service)
    case parseVoice(text: String, locale: String)

    // Notifications (core service)
    case registerDevice(token: String, appVersion: String?)
    case unregisterDevice
    case registerLiveActivity(orderId: String, pushToken: String)
    case unregisterLiveActivity(orderId: String)
}

extension APIEndpoint {
    var path: String {
        switch self {
        case .register:                        return "/api/v1/auth/register"
        case .login:                           return "/api/v1/auth/login"
        case .refresh:                         return "/api/v1/auth/refresh"
        case .logout:                          return "/api/v1/auth/logout"
        case .oauthStart(let provider, _):     return "/api/v1/auth/oauth/native/\(provider)/start"
        case .oauthCallback(let provider, _, _, _): return "/api/v1/auth/oauth/native/\(provider)/callback"
        case .oauthAppleNative:                return "/api/v1/auth/oauth/native/apple/callback"
        case .oauthYandexSDKCallback:          return "/api/v1/auth/oauth/native/yandex/sdk/callback"
        case .listProducts:                    return "/api/v1/products"
        case .getProduct(let id):              return "/api/v1/products/\(id)"
        case .getProductByBarcode(let code):   return "/api/v1/barcode/\(code)"
        case .getOffers(let productId):        return "/api/v1/products/\(productId)/offers"
        case .searchProducts:                  return "/api/v1/search"
        case .listCategories:                  return "/api/v1/categories"
        case .listBrands:                      return "/api/v1/brands"
        case .getCart:                         return "/api/v1/cart"
        case .addToCart:                       return "/api/v1/cart/items"
        case .updateCartItem(let id, _):       return "/api/v1/cart/items/\(id)"
        case .removeCartItem(let id):          return "/api/v1/cart/items/\(id)"
        case .clearCart:                       return "/api/v1/cart"
        case .runOptimization:                 return "/api/v1/optimize"
        case .getAnalogs(let productId):       return "/api/v1/analogs/\(productId)"
        case .listOrders:                      return "/api/v1/orders"
        case .getOrder(let id):                return "/api/v1/orders/\(id)"
        case .placeOrder:                      return "/api/v1/orders"
        case .photoSearch:                     return "/api/v1/products/photo-search"
        case .parseVoice:                      return "/api/v1/voice/parse"
        case .registerDevice:                  return "/api/v1/notifications/devices"
        case .unregisterDevice:                return "/api/v1/notifications/devices"
        case .registerLiveActivity(let orderId, _):
            return "/api/v1/notifications/orders/\(orderId)/live-activity"
        case .unregisterLiveActivity(let orderId):
            return "/api/v1/notifications/orders/\(orderId)/live-activity"
        }
    }

    var method: String {
        switch self {
        case .register, .login, .refresh, .logout, .addToCart, .runOptimization, .placeOrder,
             .photoSearch, .parseVoice, .oauthCallback, .oauthAppleNative, .oauthYandexSDKCallback,
             .registerDevice, .registerLiveActivity:
            return "POST"
        case .updateCartItem:
            return "PUT"
        case .removeCartItem, .clearCart, .unregisterDevice, .unregisterLiveActivity:
            return "DELETE"
        default:
            return "GET"
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .register, .login, .refresh,
             .oauthStart, .oauthCallback, .oauthAppleNative, .oauthYandexSDKCallback:
            return false
        default:
            return true
        }
    }

    var bodyData: Data? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        switch self {
        case .register(let email, let password):
            return try? encoder.encode(RegisterRequestDTO(email: email, password: password))
        case .login(let email, let password):
            return try? encoder.encode(LoginRequestDTO(email: email, password: password))
        case .refresh(let token):
            return try? encoder.encode(RefreshRequestDTO(refreshToken: token))
        case .addToCart(let productId, let quantity):
            return try? encoder.encode(AddItemRequestDTO(productId: productId, quantity: Int16(quantity)))
        case .updateCartItem(_, let quantity):
            return try? encoder.encode(UpdateItemRequestDTO(quantity: Int16(quantity)))
        case .placeOrder(let id):
            return try? encoder.encode(PlaceOrderRequestDTO(optimizationResultId: id))
        case .oauthCallback(_, let code, let state, let redirectURI):
            return try? encoder.encode(OAuthCallbackRequestDTO(code: code, state: state, redirectUri: redirectURI))
        case .oauthAppleNative(let token, let fullName, let email):
            return try? encoder.encode(OAuthAppleNativeRequestDTO(identityToken: token, fullName: fullName, email: email))
        case .oauthYandexSDKCallback(let accessToken):
            return try? encoder.encode(OAuthYandexSDKCallbackRequestDTO(accessToken: accessToken))
        case .parseVoice(let text, let locale):
            return try? encoder.encode(ParseVoiceRequestDTO(text: text, locale: locale))
        case .registerDevice(let token, let appVersion):
            return try? encoder.encode(RegisterDeviceRequestDTO(
                apnsToken: token,
                bundleId: Constants.PushTokens.bundleID,
                environment: Constants.PushTokens.environment,
                appVersion: appVersion
            ))
        case .registerLiveActivity(_, let pushToken):
            return try? encoder.encode(RegisterLiveActivityRequestDTO(
                pushToken: pushToken,
                bundleId: Constants.PushTokens.bundleID,
                environment: Constants.PushTokens.environment
            ))
        default:
            return nil
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .listProducts(let page, let perPage, let categoryId, let subcategoryId, let brandId):
            var items = [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "page_size", value: "\(perPage)")
            ]
            if let categoryId { items.append(URLQueryItem(name: "category_id", value: categoryId)) }
            if let subcategoryId { items.append(URLQueryItem(name: "subcategory_id", value: subcategoryId)) }
            if let brandId { items.append(URLQueryItem(name: "brand_id", value: brandId)) }
            return items
        case .searchProducts(let query, let filters):
            var items = [URLQueryItem(name: "q", value: query)]
            if let categoryId = filters?.categoryId {
                items.append(URLQueryItem(name: "category_id", value: categoryId))
            }
            if let brandId = filters?.brandId {
                items.append(URLQueryItem(name: "brand_id", value: brandId))
            }
            if let minPrice = filters?.minPrice {
                let kopecks = NSDecimalNumber(decimal: minPrice).multiplying(byPowerOf10: 2).int64Value
                items.append(URLQueryItem(name: "min_price", value: "\(kopecks)"))
            }
            if let maxPrice = filters?.maxPrice {
                let kopecks = NSDecimalNumber(decimal: maxPrice).multiplying(byPowerOf10: 2).int64Value
                items.append(URLQueryItem(name: "max_price", value: "\(kopecks)"))
            }
            if let inStock = filters?.inStock {
                items.append(URLQueryItem(name: "in_stock", value: inStock ? "true" : "false"))
            }
            if let hasDiscount = filters?.hasDiscount {
                items.append(URLQueryItem(name: "has_discount", value: hasDiscount ? "true" : "false"))
            }
            return items
        case .oauthStart(_, let redirectURI):
            return [URLQueryItem(name: "redirect_uri", value: redirectURI)]
        default:
            return []
        }
    }

    func url(baseURL: String) -> URL {
        guard var components = URLComponents(string: baseURL + path) else {
            return URL(string: "http://localhost")!
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        return components.url ?? URL(string: baseURL)!
    }
}

struct ParseVoiceRequestDTO: Encodable, Sendable {
    let text: String
    let locale: String
}

struct RegisterDeviceRequestDTO: Encodable, Sendable {
    let apnsToken: String
    let bundleId: String
    let environment: String
    let appVersion: String?
}

struct RegisterLiveActivityRequestDTO: Encodable, Sendable {
    let pushToken: String
    let bundleId: String
    let environment: String
}
