import Foundation

enum MockData {

    static let stores: [Store] = [
        Store(id: "store_1", name: "Пятёрочка", logoURL: nil),
        Store(id: "store_2", name: "Магнит", logoURL: nil),
        Store(id: "store_3", name: "Лента", logoURL: nil),
        Store(id: "store_4", name: "Перекрёсток", logoURL: nil),
        Store(id: "store_5", name: "ВкусВилл", logoURL: nil),
    ]

    static let categories: [Category] = [
        Category(id: "cat_1", name: "Молочные продукты", iconName: "cup.and.saucer"),
        Category(id: "cat_2", name: "Хлеб и выпечка", iconName: "birthday.cake"),
        Category(id: "cat_3", name: "Мясо и птица", iconName: "fork.knife"),
        Category(id: "cat_4", name: "Овощи и фрукты", iconName: "leaf"),
        Category(id: "cat_5", name: "Напитки", iconName: "waterbottle"),
        Category(id: "cat_6", name: "Крупы и макароны", iconName: "bag"),
        Category(id: "cat_7", name: "Кондитерские изделия", iconName: "birthday.cake"),
        Category(id: "cat_8", name: "Бытовая химия", iconName: "sparkles"),
    ]

    static let products: [Product] = [
        Product(
            id: "prod_1", name: "Молоко Простоквашино 3.2%", description: "Молоко пастеризованное, 930 мл",
            brand: "Простоквашино", category: categories[0], imageURL: nil, barcode: "4607025392408",
            prices: [
                PriceEntry(store: stores[0], price: 89.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[1], price: 94.50, originalPrice: nil, hasPromotion: false, deliveryFee: 149, freeDeliveryThreshold: 2000),
                PriceEntry(store: stores[4], price: 109.00, originalPrice: nil, hasPromotion: false, deliveryFee: 0, freeDeliveryThreshold: nil),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_2", name: "Кефир Домик в деревне 1%", description: "Кефир 1%, 930 мл",
            brand: "Домик в деревне", category: categories[0], imageURL: nil, barcode: "4607025392415",
            prices: [
                PriceEntry(store: stores[0], price: 79.90, originalPrice: 99.90, hasPromotion: true, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[2], price: 84.50, originalPrice: nil, hasPromotion: false, deliveryFee: 0, freeDeliveryThreshold: 1000),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_3", name: "Сыр Российский 50%", description: "Сыр полутвёрдый, нарезка, 150 г",
            brand: "Hochland", category: categories[0], imageURL: nil, barcode: "4607025392422",
            prices: [
                PriceEntry(store: stores[0], price: 189.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[1], price: 179.90, originalPrice: nil, hasPromotion: false, deliveryFee: 149, freeDeliveryThreshold: 2000),
                PriceEntry(store: stores[3], price: 199.90, originalPrice: 229.90, hasPromotion: true, deliveryFee: 99, freeDeliveryThreshold: 1500),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_4", name: "Творог Президент 9%", description: "Творог мягкий, 200 г",
            brand: "Президент", category: categories[0], imageURL: nil, barcode: "4607025392439",
            prices: [
                PriceEntry(store: stores[0], price: 119.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[4], price: 139.00, originalPrice: nil, hasPromotion: false, deliveryFee: 0, freeDeliveryThreshold: nil),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_5", name: "Хлеб Бородинский", description: "Хлеб ржаной заварной, 400 г",
            brand: "Хлебозавод №1", category: categories[1], imageURL: nil, barcode: "4607025392446",
            prices: [
                PriceEntry(store: stores[0], price: 54.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[1], price: 49.90, originalPrice: nil, hasPromotion: false, deliveryFee: 149, freeDeliveryThreshold: 2000),
                PriceEntry(store: stores[2], price: 52.00, originalPrice: nil, hasPromotion: false, deliveryFee: 0, freeDeliveryThreshold: 1000),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_6", name: "Батон нарезной", description: "Батон пшеничный высший сорт, 400 г",
            brand: "Хлебозавод №1", category: categories[1], imageURL: nil, barcode: "4607025392453",
            prices: [
                PriceEntry(store: stores[0], price: 42.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[1], price: 39.90, originalPrice: nil, hasPromotion: false, deliveryFee: 149, freeDeliveryThreshold: 2000),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_7", name: "Куриная грудка охлаждённая", description: "Филе куриное, 1 кг",
            brand: "Петелинка", category: categories[2], imageURL: nil, barcode: "4607025392460",
            prices: [
                PriceEntry(store: stores[0], price: 329.90, originalPrice: 389.90, hasPromotion: true, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[1], price: 349.90, originalPrice: nil, hasPromotion: false, deliveryFee: 149, freeDeliveryThreshold: 2000),
                PriceEntry(store: stores[2], price: 319.90, originalPrice: nil, hasPromotion: false, deliveryFee: 0, freeDeliveryThreshold: 1000),
                PriceEntry(store: stores[3], price: 359.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_8", name: "Фарш говяжий", description: "Фарш из говядины, 500 г",
            brand: "Мираторг", category: categories[2], imageURL: nil, barcode: "4607025392477",
            prices: [
                PriceEntry(store: stores[0], price: 299.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[2], price: 279.90, originalPrice: nil, hasPromotion: false, deliveryFee: 0, freeDeliveryThreshold: 1000),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_9", name: "Свинина шейка", description: "Свиная шейка без кости, 1 кг",
            brand: "Черкизово", category: categories[2], imageURL: nil, barcode: "4607025392484",
            prices: [
                PriceEntry(store: stores[1], price: 449.90, originalPrice: 519.90, hasPromotion: true, deliveryFee: 149, freeDeliveryThreshold: 2000),
                PriceEntry(store: stores[2], price: 469.90, originalPrice: nil, hasPromotion: false, deliveryFee: 0, freeDeliveryThreshold: 1000),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_10", name: "Помидоры черри", description: "Томаты черри, 250 г",
            brand: "Эко Ферма", category: categories[3], imageURL: nil, barcode: "4607025392491",
            prices: [
                PriceEntry(store: stores[0], price: 149.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[3], price: 139.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[4], price: 169.00, originalPrice: nil, hasPromotion: false, deliveryFee: 0, freeDeliveryThreshold: nil),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_11", name: "Огурцы свежие", description: "Огурцы длинноплодные, 1 кг",
            brand: "Тепличный", category: categories[3], imageURL: nil, barcode: "4607025392508",
            prices: [
                PriceEntry(store: stores[0], price: 129.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[1], price: 119.90, originalPrice: nil, hasPromotion: false, deliveryFee: 149, freeDeliveryThreshold: 2000),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_12", name: "Бананы", description: "Бананы спелые, 1 кг",
            brand: "Bonanza", category: categories[3], imageURL: nil, barcode: "4607025392515",
            prices: [
                PriceEntry(store: stores[0], price: 79.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[1], price: 74.90, originalPrice: nil, hasPromotion: false, deliveryFee: 149, freeDeliveryThreshold: 2000),
                PriceEntry(store: stores[2], price: 69.90, originalPrice: nil, hasPromotion: false, deliveryFee: 0, freeDeliveryThreshold: 1000),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_13", name: "Яблоки Гала", description: "Яблоки сорт Гала, 1 кг",
            brand: "Сады Придонья", category: categories[3], imageURL: nil, barcode: "4607025392522",
            prices: [
                PriceEntry(store: stores[0], price: 109.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[3], price: 99.90, originalPrice: 129.90, hasPromotion: true, deliveryFee: 99, freeDeliveryThreshold: 1500),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_14", name: "Картофель", description: "Картофель мытый, 2 кг",
            brand: "Овощная Ферма", category: categories[3], imageURL: nil, barcode: "4607025392539",
            prices: [
                PriceEntry(store: stores[0], price: 89.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[1], price: 79.90, originalPrice: nil, hasPromotion: false, deliveryFee: 149, freeDeliveryThreshold: 2000),
                PriceEntry(store: stores[2], price: 74.90, originalPrice: nil, hasPromotion: false, deliveryFee: 0, freeDeliveryThreshold: 1000),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_15", name: "Вода Святой Источник", description: "Вода питьевая негазированная, 1.5 л",
            brand: "Святой Источник", category: categories[4], imageURL: nil, barcode: "4607025392546",
            prices: [
                PriceEntry(store: stores[0], price: 39.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[1], price: 42.90, originalPrice: nil, hasPromotion: false, deliveryFee: 149, freeDeliveryThreshold: 2000),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_16", name: "Сок Добрый яблочный", description: "Сок яблочный осветлённый, 1 л",
            brand: "Добрый", category: categories[4], imageURL: nil, barcode: "4607025392553",
            prices: [
                PriceEntry(store: stores[0], price: 99.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[1], price: 94.90, originalPrice: nil, hasPromotion: false, deliveryFee: 149, freeDeliveryThreshold: 2000),
                PriceEntry(store: stores[3], price: 109.90, originalPrice: 129.90, hasPromotion: true, deliveryFee: 99, freeDeliveryThreshold: 1500),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_17", name: "Кока-Кола", description: "Напиток газированный, 1.5 л",
            brand: "Coca-Cola", category: categories[4], imageURL: nil, barcode: "4607025392560",
            prices: [
                PriceEntry(store: stores[0], price: 109.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[1], price: 104.90, originalPrice: nil, hasPromotion: false, deliveryFee: 149, freeDeliveryThreshold: 2000),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_18", name: "Рис Мистраль", description: "Рис длиннозёрный, 900 г",
            brand: "Мистраль", category: categories[5], imageURL: nil, barcode: "4607025392577",
            prices: [
                PriceEntry(store: stores[0], price: 129.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[2], price: 119.90, originalPrice: nil, hasPromotion: false, deliveryFee: 0, freeDeliveryThreshold: 1000),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_19", name: "Гречка Увелка", description: "Крупа гречневая ядрица, 800 г",
            brand: "Увелка", category: categories[5], imageURL: nil, barcode: "4607025392584",
            prices: [
                PriceEntry(store: stores[0], price: 99.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[1], price: 89.90, originalPrice: nil, hasPromotion: false, deliveryFee: 149, freeDeliveryThreshold: 2000),
                PriceEntry(store: stores[2], price: 94.90, originalPrice: nil, hasPromotion: false, deliveryFee: 0, freeDeliveryThreshold: 1000),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_20", name: "Макароны Barilla спагетти", description: "Спагетти №5, 450 г",
            brand: "Barilla", category: categories[5], imageURL: nil, barcode: "4607025392591",
            prices: [
                PriceEntry(store: stores[0], price: 149.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[3], price: 139.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[4], price: 159.00, originalPrice: nil, hasPromotion: false, deliveryFee: 0, freeDeliveryThreshold: nil),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_21", name: "Шоколад Алёнка", description: "Шоколад молочный, 90 г",
            brand: "Красный Октябрь", category: categories[6], imageURL: nil, barcode: "4607025392607",
            prices: [
                PriceEntry(store: stores[0], price: 89.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[1], price: 84.90, originalPrice: nil, hasPromotion: false, deliveryFee: 149, freeDeliveryThreshold: 2000),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_22", name: "Печенье Юбилейное", description: "Печенье сахарное классическое, 313 г",
            brand: "Юбилейное", category: categories[6], imageURL: nil, barcode: "4607025392614",
            prices: [
                PriceEntry(store: stores[0], price: 79.90, originalPrice: 99.90, hasPromotion: true, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[1], price: 89.90, originalPrice: nil, hasPromotion: false, deliveryFee: 149, freeDeliveryThreshold: 2000),
                PriceEntry(store: stores[2], price: 84.90, originalPrice: nil, hasPromotion: false, deliveryFee: 0, freeDeliveryThreshold: 1000),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_23", name: "Конфеты Коркунов", description: "Ассорти из тёмного и молочного шоколада, 192 г",
            brand: "Коркунов", category: categories[6], imageURL: nil, barcode: "4607025392621",
            prices: [
                PriceEntry(store: stores[3], price: 349.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[4], price: 369.00, originalPrice: nil, hasPromotion: false, deliveryFee: 0, freeDeliveryThreshold: nil),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_24", name: "Средство Fairy", description: "Средство для мытья посуды, 650 мл",
            brand: "Fairy", category: categories[7], imageURL: nil, barcode: "4607025392638",
            prices: [
                PriceEntry(store: stores[0], price: 179.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[1], price: 169.90, originalPrice: nil, hasPromotion: false, deliveryFee: 149, freeDeliveryThreshold: 2000),
                PriceEntry(store: stores[2], price: 159.90, originalPrice: nil, hasPromotion: false, deliveryFee: 0, freeDeliveryThreshold: 1000),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_25", name: "Порошок Persil", description: "Стиральный порошок автомат, 3 кг",
            brand: "Persil", category: categories[7], imageURL: nil, barcode: "4607025392645",
            prices: [
                PriceEntry(store: stores[0], price: 599.90, originalPrice: 699.90, hasPromotion: true, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[2], price: 649.90, originalPrice: nil, hasPromotion: false, deliveryFee: 0, freeDeliveryThreshold: 1000),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_26", name: "Сметана Домик в деревне 20%", description: "Сметана 20%, 300 г",
            brand: "Домик в деревне", category: categories[0], imageURL: nil, barcode: "4607025392652",
            prices: [
                PriceEntry(store: stores[0], price: 99.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[1], price: 94.90, originalPrice: nil, hasPromotion: false, deliveryFee: 149, freeDeliveryThreshold: 2000),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_27", name: "Яйца С1", description: "Яйца куриные столовые, 10 шт",
            brand: "Роскар", category: categories[2], imageURL: nil, barcode: "4607025392669",
            prices: [
                PriceEntry(store: stores[0], price: 99.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[1], price: 89.90, originalPrice: nil, hasPromotion: false, deliveryFee: 149, freeDeliveryThreshold: 2000),
                PriceEntry(store: stores[2], price: 94.90, originalPrice: nil, hasPromotion: false, deliveryFee: 0, freeDeliveryThreshold: 1000),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_28", name: "Масло сливочное Lurpak", description: "Масло сливочное 82.5%, 200 г",
            brand: "Lurpak", category: categories[0], imageURL: nil, barcode: "4607025392676",
            prices: [
                PriceEntry(store: stores[3], price: 249.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[4], price: 269.00, originalPrice: nil, hasPromotion: false, deliveryFee: 0, freeDeliveryThreshold: nil),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_29", name: "Лук репчатый", description: "Лук репчатый, 1 кг",
            brand: "Овощная Ферма", category: categories[3], imageURL: nil, barcode: "4607025392683",
            prices: [
                PriceEntry(store: stores[0], price: 39.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[1], price: 34.90, originalPrice: nil, hasPromotion: false, deliveryFee: 149, freeDeliveryThreshold: 2000),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_30", name: "Морковь мытая", description: "Морковь мытая, 1 кг",
            brand: "Овощная Ферма", category: categories[3], imageURL: nil, barcode: "4607025392690",
            prices: [
                PriceEntry(store: stores[0], price: 49.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[1], price: 44.90, originalPrice: nil, hasPromotion: false, deliveryFee: 149, freeDeliveryThreshold: 2000),
                PriceEntry(store: stores[2], price: 42.90, originalPrice: nil, hasPromotion: false, deliveryFee: 0, freeDeliveryThreshold: 1000),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_31", name: "Чай Greenfield Earl Grey", description: "Чай чёрный в пакетиках, 25 шт",
            brand: "Greenfield", category: categories[4], imageURL: nil, barcode: "4607025392706",
            prices: [
                PriceEntry(store: stores[0], price: 119.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[3], price: 109.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_32", name: "Подсолнечное масло Олейна", description: "Масло подсолнечное рафинированное, 1 л",
            brand: "Олейна", category: categories[5], imageURL: nil, barcode: "4607025392713",
            prices: [
                PriceEntry(store: stores[0], price: 139.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[1], price: 134.90, originalPrice: nil, hasPromotion: false, deliveryFee: 149, freeDeliveryThreshold: 2000),
                PriceEntry(store: stores[2], price: 129.90, originalPrice: nil, hasPromotion: false, deliveryFee: 0, freeDeliveryThreshold: 1000),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_33", name: "Туалетная бумага Zewa", description: "Бумага туалетная 3 слоя, 12 рулонов",
            brand: "Zewa", category: categories[7], imageURL: nil, barcode: "4607025392720",
            prices: [
                PriceEntry(store: stores[0], price: 399.90, originalPrice: nil, hasPromotion: false, deliveryFee: 99, freeDeliveryThreshold: 1500),
                PriceEntry(store: stores[2], price: 379.90, originalPrice: nil, hasPromotion: false, deliveryFee: 0, freeDeliveryThreshold: 1000),
            ],
            isAvailable: true
        ),
        Product(
            id: "prod_34", name: "Сосиски Молочные", description: "Сосиски молочные, 400 г",
            brand: "Останкино", category: categories[2], imageURL: nil, barcode: nil,
            prices: [],
            isAvailable: false
        ),
    ]

    static let orders: [Order] = {
        let calendar = Calendar.current
        let now = Date()
        return [
            Order(
                id: "order_1", orderNumber: "FS-20260315-001",
                createdAt: calendar.date(byAdding: .day, value: -5, to: now)!,
                status: .delivered, totalCost: 1249.70,
                stores: [stores[0], stores[2]],
                items: [
                    OrderItem(product: products[0], quantity: 2, pricePerUnit: 89.90, store: stores[0]),
                    OrderItem(product: products[4], quantity: 1, pricePerUnit: 52.00, store: stores[2]),
                    OrderItem(product: products[6], quantity: 2, pricePerUnit: 319.90, store: stores[2]),
                ]
            ),
            Order(
                id: "order_2", orderNumber: "FS-20260314-002",
                createdAt: calendar.date(byAdding: .day, value: -3, to: now)!,
                status: .inTransit, totalCost: 879.50,
                stores: [stores[1]],
                items: [
                    OrderItem(product: products[11], quantity: 2, pricePerUnit: 74.90, store: stores[1]),
                    OrderItem(product: products[18], quantity: 1, pricePerUnit: 89.90, store: stores[1]),
                    OrderItem(product: products[20], quantity: 3, pricePerUnit: 84.90, store: stores[1]),
                ]
            ),
            Order(
                id: "order_3", orderNumber: "FS-20260315-003",
                createdAt: calendar.date(byAdding: .day, value: -1, to: now)!,
                status: .assembling, totalCost: 1589.60,
                stores: [stores[0], stores[3]],
                items: [
                    OrderItem(product: products[2], quantity: 2, pricePerUnit: 189.90, store: stores[0]),
                    OrderItem(product: products[9], quantity: 3, pricePerUnit: 139.90, store: stores[3]),
                    OrderItem(product: products[19], quantity: 2, pricePerUnit: 139.90, store: stores[3]),
                ]
            ),
            Order(
                id: "order_4", orderNumber: "FS-20260315-004",
                createdAt: now,
                status: .confirmed, totalCost: 649.70,
                stores: [stores[4]],
                items: [
                    OrderItem(product: products[3], quantity: 1, pricePerUnit: 139.00, store: stores[4]),
                    OrderItem(product: products[22], quantity: 1, pricePerUnit: 369.00, store: stores[4]),
                ]
            ),
            Order(
                id: "order_5", orderNumber: "FS-20260315-005",
                createdAt: calendar.date(byAdding: .hour, value: -2, to: now)!,
                status: .pending, totalCost: 429.70,
                stores: [stores[0]],
                items: [
                    OrderItem(product: products[14], quantity: 2, pricePerUnit: 39.90, store: stores[0]),
                    OrderItem(product: products[24], quantity: 1, pricePerUnit: 599.90, store: stores[0]),
                ]
            ),
        ]
    }()

    static let orderDetails: [String: OrderDetail] = {
        let calendar = Calendar.current
        return [
            "order_1": OrderDetail(
                order: orders[0],
                timeline: [
                    StatusEvent(status: .pending, timestamp: calendar.date(byAdding: .day, value: -5, to: Date())!, description: "Заказ создан"),
                    StatusEvent(status: .confirmed, timestamp: calendar.date(byAdding: .hour, value: -118, to: Date())!, description: "Заказ подтверждён магазином"),
                    StatusEvent(status: .assembling, timestamp: calendar.date(byAdding: .hour, value: -116, to: Date())!, description: "Заказ собирается"),
                    StatusEvent(status: .shipped, timestamp: calendar.date(byAdding: .hour, value: -110, to: Date())!, description: "Заказ передан в доставку"),
                    StatusEvent(status: .inTransit, timestamp: calendar.date(byAdding: .hour, value: -108, to: Date())!, description: "Курьер в пути"),
                    StatusEvent(status: .delivered, timestamp: calendar.date(byAdding: .hour, value: -106, to: Date())!, description: "Заказ доставлен"),
                ],
                deliveryAddress: "ул. Ленина, д. 42, кв. 15",
                estimatedDelivery: nil
            ),
            "order_2": OrderDetail(
                order: orders[1],
                timeline: [
                    StatusEvent(status: .pending, timestamp: calendar.date(byAdding: .day, value: -3, to: Date())!, description: "Заказ создан"),
                    StatusEvent(status: .confirmed, timestamp: calendar.date(byAdding: .hour, value: -70, to: Date())!, description: "Заказ подтверждён"),
                    StatusEvent(status: .assembling, timestamp: calendar.date(byAdding: .hour, value: -68, to: Date())!, description: "Заказ собирается"),
                    StatusEvent(status: .inTransit, timestamp: calendar.date(byAdding: .hour, value: -2, to: Date())!, description: "Курьер в пути"),
                ],
                deliveryAddress: "пр. Мира, д. 10, кв. 3",
                estimatedDelivery: calendar.date(byAdding: .hour, value: 1, to: Date())
            ),
        ]
    }()
}
