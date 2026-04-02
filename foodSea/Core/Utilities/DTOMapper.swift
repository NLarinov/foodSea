import Foundation

// MARK: - Helpers

private func kopecksToDecimal(_ kopecks: Int64) -> Decimal {
    Decimal(kopecks) / 100
}

private func remapImageURL(_ urlString: String?) -> URL? {
    guard let urlString else { return nil }
    let remapped = urlString.replacingOccurrences(
        of: Constants.API.minioInternalPrefix,
        with: Constants.API.minioPublicURL
    )
    return URL(string: remapped, encodingInvalidCharacters: true)
}

// MARK: - Category / Store / Offer

extension CategoryBriefDTO {
    func toDomain() -> Category {
        Category(id: id, name: name, iconName: nil)
    }
}

extension StoreBriefDTO {
    func toDomain() -> Store {
        Store(id: id, name: name, logoURL: logoUrl.flatMap { URL(string: $0) })
    }
}

extension OfferDTO {
    func toPriceEntry() -> PriceEntry {
        PriceEntry(
            store: store.toDomain(),
            price: kopecksToDecimal(priceKopecks),
            originalPrice: originalPriceKopecks.map { kopecksToDecimal($0) },
            hasPromotion: discountPercent != nil,
            deliveryFee: 0,
            freeDeliveryThreshold: nil
        )
    }
}

// MARK: - Products

extension ProductDetailDTO {
    func toDomain(offers: [OfferDTO]) -> Product {
        Product(
            id: id,
            name: name,
            description: description ?? "",
            brand: brand?.name ?? "",
            category: category.toDomain(),
            imageURL: remapImageURL(imageUrl),
            barcode: barcode,
            prices: offers.map { $0.toPriceEntry() },
            isAvailable: inStock
        )
    }
}

extension ProductBriefDTO {
    func toDomain() -> Product {
        let prices: [PriceEntry]
        if let kopecks = minPriceKopecks {
            prices = [PriceEntry(
                store: Store(id: "", name: "", logoURL: nil),
                price: kopecksToDecimal(kopecks),
                originalPrice: nil,
                hasPromotion: false,
                deliveryFee: 0,
                freeDeliveryThreshold: nil
            )]
        } else {
            prices = []
        }
        return Product(
            id: id,
            name: name,
            description: "",
            brand: "",
            category: Category(id: "", name: "", iconName: nil),
            imageURL: remapImageURL(imageUrl),
            barcode: nil,
            prices: prices,
            isAvailable: inStock,
            maxDiscountPercent: maxDiscountPercent
        )
    }
}

extension SearchResultItemDTO {
    func toDomain() -> Product {
        let priceEntry = PriceEntry(
            store: Store(id: "", name: "", logoURL: nil),
            price: kopecksToDecimal(minPriceKopecks),
            originalPrice: nil,
            hasPromotion: maxDiscountPercent != nil,
            deliveryFee: 0,
            freeDeliveryThreshold: nil
        )
        return Product(
            id: id,
            name: name,
            description: "",
            brand: brandId ?? "",
            category: Category(id: categoryId, name: "", iconName: nil),
            imageURL: remapImageURL(imageUrl),
            barcode: barcode,
            prices: [priceEntry],
            isAvailable: inStock,
            maxDiscountPercent: maxDiscountPercent.map(Int.init)
        )
    }
}

extension AnalogDTO {
    func toDomain() -> Product {
        Product(
            id: productId,
            name: productName,
            description: "",
            brand: "",
            category: Category(id: "", name: "", iconName: nil),
            imageURL: nil,
            barcode: nil,
            prices: [PriceEntry(
                store: Store(id: "", name: "", logoURL: nil),
                price: kopecksToDecimal(minPriceKopecks),
                originalPrice: nil,
                hasPromotion: false,
                deliveryFee: 0,
                freeDeliveryThreshold: nil
            )],
            isAvailable: true
        )
    }
}

// MARK: - Optimization

extension AssignmentDTO {
    func toOptimizedItem() -> OptimizedItem {
        let price = kopecksToDecimal(priceKopecks)
        let product = Product(
            id: productId,
            name: productName,
            description: "",
            brand: "",
            category: Category(id: "", name: "", iconName: nil),
            imageURL: nil,
            barcode: nil,
            prices: [PriceEntry(
                store: Store(id: storeId, name: storeName, logoURL: nil),
                price: price,
                originalPrice: nil,
                hasPromotion: false,
                deliveryFee: 0,
                freeDeliveryThreshold: nil
            )],
            isAvailable: true
        )
        return OptimizedItem(product: product, quantity: quantity, price: price)
    }
}

extension SubstitutionDTO {
    func toDomain() -> Substitution {
        let emptyCategory = Category(id: "", name: "", iconName: nil)
        let original = Product(id: originalProductId, name: originalProductName,
                               description: "", brand: "", category: emptyCategory,
                               imageURL: nil, barcode: nil, prices: [], isAvailable: true)
        let alternative = Product(id: analogProductId, name: analogProductName,
                                  description: "", brand: "", category: emptyCategory,
                                  imageURL: nil, barcode: nil, prices: [], isAvailable: true)
        return Substitution(
            id: UUID().uuidString,
            original: original,
            alternative: alternative,
            priceDifference: kopecksToDecimal(abs(priceDeltaKopecks)),
            isAccepted: false
        )
    }
}

extension OptimizationResultDTO {
    func toDomain() -> OptimizationResult {
        let grouped = Dictionary(grouping: items, by: \.storeId)
        let storeOrders = grouped.map { storeId, assignments -> StoreOrder in
            let store = Store(id: storeId, name: assignments[0].storeName, logoURL: nil)
            let optimizedItems = assignments.map { $0.toOptimizedItem() }
            let subtotal = optimizedItems.reduce(Decimal(0)) { $0 + $1.price * Decimal($1.quantity) }
            return StoreOrder(id: storeId, store: store, items: optimizedItems,
                              subtotal: subtotal, deliveryFee: 0)
        }.sorted { $0.store.name < $1.store.name }

        return OptimizationResult(
            id: id,
            totalCost: kopecksToDecimal(totalKopecks),
            deliveryCost: kopecksToDecimal(deliveryKopecks),
            savings: kopecksToDecimal(savingsKopecks),
            storeOrders: storeOrders,
            substitutions: substitutions.map { $0.toDomain() }
        )
    }
}

// MARK: - Orders

extension OrderStatus {
    init(backendString: String) {
        switch backendString.lowercased() {
        case "created", "pending": self = .pending
        case "confirmed":          self = .confirmed
        case "assembling":         self = .assembling
        case "shipped":            self = .shipped
        case "in_transit", "in_delivery": self = .inTransit
        case "delivered":          self = .delivered
        case "cancelled":          self = .cancelled
        default:                   self = .pending
        }
    }
}

extension OrderBriefDTO {
    func toDomain() -> Order {
        Order(
            id: id,
            orderNumber: "FS-\(id.prefix(8).uppercased())",
            createdAt: createdAt,
            status: OrderStatus(backendString: status),
            totalCost: kopecksToDecimal(totalKopecks + deliveryKopecks),
            stores: [],
            items: []
        )
    }
}

extension OrderDetailDTO {
    func toDomain() -> OrderDetail {
        let emptyCategory = Category(id: "", name: "", iconName: nil)
        let orderItems = items.map { item -> OrderItem in
            let product = Product(id: item.productId, name: item.productName,
                                  description: "", brand: "", category: emptyCategory,
                                  imageURL: nil, barcode: nil, prices: [], isAvailable: true)
            let store = Store(id: item.storeId, name: item.storeName, logoURL: nil)
            return OrderItem(product: product, quantity: Int(item.quantity),
                             pricePerUnit: kopecksToDecimal(item.priceKopecks), store: store)
        }
        var seenIds = Set<String>()
        let stores = items.compactMap { item -> Store? in
            guard seenIds.insert(item.storeId).inserted else { return nil }
            return Store(id: item.storeId, name: item.storeName, logoURL: nil)
        }
        let order = Order(
            id: id,
            orderNumber: "FS-\(id.prefix(8).uppercased())",
            createdAt: createdAt,
            status: OrderStatus(backendString: status),
            totalCost: kopecksToDecimal(totalKopecks + deliveryKopecks),
            stores: stores,
            items: orderItems
        )
        let timeline = history.map { change in
            StatusEvent(status: OrderStatus(backendString: change.status),
                        timestamp: change.changedAt,
                        description: change.comment ?? "")
        }
        return OrderDetail(order: order, timeline: timeline,
                           deliveryAddress: nil, estimatedDelivery: nil)
    }
}
