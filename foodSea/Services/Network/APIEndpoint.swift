import Foundation

enum APIEndpoint {
    // Auth (core service)
    case register(email: String, password: String)
    case login(email: String, password: String)
    case refresh(token: String)
    case logout

    // Products (core service)
    case listProducts(page: Int, perPage: Int)
    case getProduct(id: String)
    case getProductByBarcode(code: String)
    case getOffers(productId: String)
    case searchProducts(query: String, filters: SearchFilters?)

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
}

extension APIEndpoint {
    var path: String {
        switch self {
        case .register:                        return "/api/v1/auth/register"
        case .login:                           return "/api/v1/auth/login"
        case .refresh:                         return "/api/v1/auth/refresh"
        case .logout:                          return "/api/v1/auth/logout"
        case .listProducts:                    return "/api/v1/products"
        case .getProduct(let id):              return "/api/v1/products/\(id)"
        case .getProductByBarcode(let code):   return "/api/v1/products/barcode/\(code)"
        case .getOffers(let productId):        return "/api/v1/products/\(productId)/offers"
        case .searchProducts:                  return "/api/v1/search"
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
        }
    }

    var method: String {
        switch self {
        case .register, .login, .refresh, .logout, .addToCart, .runOptimization, .placeOrder, .photoSearch:
            return "POST"
        case .updateCartItem:
            return "PUT"
        case .removeCartItem, .clearCart:
            return "DELETE"
        default:
            return "GET"
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .register, .login, .refresh:
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
        default:
            return nil
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .listProducts(let page, let perPage):
            return [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "page_size", value: "\(perPage)")
            ]
        case .searchProducts(let query, let filters):
            var items = [URLQueryItem(name: "q", value: query)]
            if let minPrice = filters?.minPrice {
                let kopecks = NSDecimalNumber(decimal: minPrice).multiplying(byPowerOf10: 2).int64Value
                items.append(URLQueryItem(name: "min_price", value: "\(kopecks)"))
            }
            if let maxPrice = filters?.maxPrice {
                let kopecks = NSDecimalNumber(decimal: maxPrice).multiplying(byPowerOf10: 2).int64Value
                items.append(URLQueryItem(name: "max_price", value: "\(kopecks)"))
            }
            return items
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
