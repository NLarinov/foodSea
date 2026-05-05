import Foundation

enum Constants {
    enum API {
        private static let gatewayURL = "https://foodsea-app.ru"
        static let coreBaseURL = gatewayURL
        static let optimizationBaseURL = gatewayURL
        static let orderingBaseURL = gatewayURL
        static let minioInternalPrefix = "http://localhost:9000"
        static let minioPublicURL = gatewayURL
        static let timeoutInterval: TimeInterval = 10
        static let itemsPerPage = 20
    }

    enum UI {
        static let minimumTapSize: CGFloat = 44
        static let standardPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largePadding: CGFloat = 24
        static let cornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 8
        static let cellSpacing: CGFloat = 12
        static let productImageHeight: CGFloat = 280
        static let productImageAspectRatio: CGFloat = 1.0
        static let priceTableMaxHeight: CGFloat = 260
        static let thumbnailSize: CGFloat = 80
        static let buttonHeight: CGFloat = 50
        static let searchBarHeight: CGFloat = 44
        static let tabBarIconSize: CGFloat = 24
        static let sectionHeaderHeight: CGFloat = 44
        static let separatorInset: CGFloat = 16
        static let badgeFontSize: CGFloat = 12
        static let titleFontSize: CGFloat = 17
        static let subtitleFontSize: CGFloat = 14
        static let captionFontSize: CGFloat = 12
        static let priceFontSize: CGFloat = 16
        static let largeTitleFontSize: CGFloat = 28
    }

    enum Animation {
        static let defaultDuration: TimeInterval = 0.3
        static let longDuration: TimeInterval = 0.5
        static let springDamping: CGFloat = 0.8
    }

    enum Search {
        static let debounceInterval: TimeInterval = 0.3
    }

    enum Cache {
        static let productTTL: TimeInterval = 300
        static let detailTTL: TimeInterval = 600
        static let searchTTL: TimeInterval = 120
        static let imageCacheMaxSize = 100 * 1024 * 1024
    }

    enum Mock {
        static let shortDelay: UInt64 = 300_000_000
        static let mediumDelay: UInt64 = 500_000_000
        static let longDelay: UInt64 = 1_000_000_000
    }

    enum Cart {
        static let maxQuantity = 99
        static let minQuantity = 1
        static let storageKey = "foodsea_cart_items"
        static let itemCountKey = "cartItemCount"
    }

    enum Onboarding {
        static let shownKey = "foodsea_onboarding_shown"
        static let slideCount = 3
    }

    enum TabBar {
        static let homeTitle = "Главная"
        static let catalogTitle = "Каталог"
        static let cartTitle = "Корзина"
        static let ordersTitle = "Заказы"
        static let homeIcon = "house.fill"
        static let catalogIcon = "square.grid.2x2.fill"
        static let cartIcon = "cart.fill"
        static let ordersIcon = "clock.fill"
    }

    enum Optimization {
        static let title = "Результат оптимизации"
        static let totalCostLabel = "Товары"
        static let deliveryCostLabel = "Доставка"
        static let grandTotalLabel = "Итого"
        static let savingsFormat = "Вы экономите %@ ₽"
        static let storeOrdersSection = "Заказы по магазинам"
        static let substitutionsSection = "Замены"
        static let applyButton = "Применить и оформить"
        static let backToCartButton = "Вернуться к корзине"
        static let loadingMessage = "Оптимизируем корзину..."
        static let noSubstitutions = "Замен нет"
        static let acceptButton = "Принять"
        static let rejectButton = "Отклонить"
        static let deliveryFreeLabel = "Бесплатно"
        static let itemsCountFormat = "%d товаров"
        static let storeHeaderHeight: CGFloat = 56
        static let savingsBannerHeight: CGFloat = 48
        static let timelineDotSize: CGFloat = 12
        static let timelineLineWidth: CGFloat = 2
    }

    enum Orders {
        static let title = "Заказы"
        static let allFilter = "Все"
        static let orderNumberPrefix = "Заказ"
        static let checkoutTitle = "Оформление"
        static let checkoutSummaryHeader = "Ваш заказ"
        static let confirmationTitle = "Заказ оформлен!"
        static let confirmationMessage = "Ваш заказ успешно создан"
        static let estimatedDeliveryLabel = "Ожидаемая доставка"
        static let deliveryAddressLabel = "Адрес доставки"
        static let financialSummaryHeader = "Итого по заказу"
        static let statusFilterHeight: CGFloat = 36
    }

    enum Scanner {
        static let overlayAlpha: CGFloat = 0.5
        static let targetRectSize: CGFloat = 250
        static let instructionBottomOffset: CGFloat = 60
        static let manualEntryPlaceholder = "Введите штрихкод"
    }

    enum PhotoSearch {
        static let topK: Int = 5
        static let minOCRLength: Int = 3
        static let maxOCRLength: Int = 4000
        static let fallbackOCR = "---"
        static let maxImageBytes: Int = 8 * 1024 * 1024
        static let targetCompressionBytes: Int = 2 * 1024 * 1024
        static let initialJPEGQuality: CGFloat = 0.85
        static let minJPEGQuality: CGFloat = 0.5
        static let jpegQualityStep: CGFloat = 0.1
        static let shutterButtonSize: CGFloat = 72
        static let shutterInnerInset: CGFloat = 6
        static let controlButtonSize: CGFloat = 44
        static let hintTopOffset: CGFloat = 32
        static let bottomPanelHeight: CGFloat = 120
        static let bottomPanelBackgroundAlpha: CGFloat = 0.5
        static let hintBackgroundAlpha: CGFloat = 0.4
        static let resultOverlayAlpha: CGFloat = 0.6
    }

    enum Voice {
        static let micButtonSize: CGFloat = 80
        static let pulseScale: CGFloat = 1.2
        static let pulseAnimationDuration: TimeInterval = 1.0
        static let confidenceBarHeight: CGFloat = 4
        static let maxRecordingDuration: TimeInterval = 30
        static let recordingTimerInterval: TimeInterval = 0.1
    }

    enum Notifications {
        static let orderUpdateTitle = "Обновление заказа"
        static let orderCreatedTitle = "Заказ оформлен"
        static let orderCreatedBody = "Мы получили ваш заказ и начинаем обработку"
        static let orderPendingBody = "Заказ принят, ждём подтверждения магазином"
        static let orderConfirmedBody = "Магазин подтвердил заказ"
        static let orderDeliveredBody = "Ваш заказ доставлен!"
        static let orderInTransitBody = "Курьер уже в пути"
        static let orderAssemblingBody = "Ваш заказ собирается"
        static let orderCancelledBody = "Заказ отменён"
        static let localNotificationDelay: TimeInterval = 5
        static let categoryIdentifier = "foodsea_order"
        static let orderIdKey = "order_id"
    }

    enum OrderTracking {
        static let pollIntervalSec: Int = 20
    }

    enum PushTokens {
        static let apnsTokenKey = "foodsea.apnsToken"
    }

    enum Home {
        static let bannerHeight: CGFloat = 140
        static let filterChipHeight: CGFloat = 36
        static let allFilterTitle = "Все"
        static let forYouTitle = "Рекомендуем для вас"
        static let promoTitle = "Акции и скидки"
    }

    enum Catalog {
        static let subcategoryCellHeight: CGFloat = 100
        static let subcategoryCellWidth: CGFloat = 110
        static let subcategoryIconSize: CGFloat = 32
    }

    enum OAuth {
        static let callbackScheme = "foodsea"
        static let callbackHost = "oauth"
        static let callbackPath = "/callback"
        static let nativeRedirectURI = "foodsea://oauth/callback"
        static let googleProvider = "google"
        static let yandexProvider = "yandex"
        static let appleProvider = "apple"
        static let codeQueryItem = "code"
        static let stateQueryItem = "state"

        static let yandexClientID = "5e1277d1b081410fac11d4282663d2a4"
    }

    enum Strings {
        static let appName = "FoodSea"
        static let emptyCartMessage = "В корзине пока ничего нет("
        static let emptyCartSubtitle = "Давайте наполним её!"
        static let emptyCartAction = "Перейти в каталог"
        static let recommendedProducts = "Популярные товары"
        static let emptySearchMessage = "Ничего не найдено"
        static let emptySearchHint = "Попробуйте другой запрос"
        static let emptyOrdersMessage = "У вас пока нет заказов"
        static let optimizeButton = "Оптимизировать"
        static let addToCartButton = "В корзину"
        static let applyFilters = "Применить"
        static let resetFilters = "Сбросить"
        static let closeButton = "Закрыть"
        static let clearCart = "Очистить корзину"
        static let clearCartConfirmation = "Вы уверены, что хотите очистить корзину?"
        static let deleteConfirmation = "Удалить товар?"
        static let cancel = "Отмена"
        static let delete = "Удалить"
        static let retry = "Повторить"
        static let networkError = "Проверьте подключение к интернету"
        static let serverError = "Что-то пошло не так. Попробуйте позже"
        static let addedToCart = "Товар добавлен в корзину"
        static let scannerTitle = "Сканер штрихкода"
        static let scannerHint = "Наведите камеру на штрихкод"
        static let productNotFound = "Товар не найден"
        static let manualEntry = "Ввести вручную"
        static let voiceTitle = "Голосовой ввод"
        static let voiceHint = "Например: молоко, хлеб белый, 2 кг яблок"
        static let voiceRecording = "Говорите..."
        static let voiceProcessing = "Обработка..."
        static let addAllToCart = "Добавить все в корзину"
        static let submitOrder = "Оформить заказ"
        static let orderConfirmed = "Заказ оформлен"
        static let toOrders = "К заказам"
        static let toCatalog = "В каталог"
        static let photoSearchTitle = "Поиск по фото"
        static let photoSearchHint = "Сфотографируйте товар, и мы найдём его"
        static let photoSearchGallery = "Из галереи"
        static let photoSearchTryAgain = "Попробовать снова"
        static let photoSearchCameraUnavailable = "Камера недоступна"
        static let photoSearchCameraUnavailableMessage = "Используйте галерею или закройте экран"
        static let photoSearchProcessing = "Ищем товар…"
        static let welcomeSubtitle = "Сэкономьте на покупках"
        static let signInWithApple = "Войти через Apple"
        static let signInWithGoogle = "Войти через Google"
        static let signInWithYandex = "Войти через Yandex"
        static let signInWithEmail = "Войти по почте"
        static let orSeparator = "или"
        static let oauthGenericError = "Не удалось войти. Попробуйте позже."
        static let oauthProviderNetworkError = "Не удалось подключиться к провайдеру"
        static let oauthSessionExpiredError = "Сессия истекла, попробуйте снова"
        static let oauthEmailCollisionError = "Этот email уже привязан к другому способу входа"
        static let oauthAppleVerificationError = "Не удалось проверить подпись Apple"
    }
}
