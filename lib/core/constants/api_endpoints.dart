class ApiEndpoints {
  static const String baseUrl = 'http://192.168.100.173';
  // static const String baseUrl = 'https://apiloyalty.azeraholding.az';
  // static const String baseUrl = 'http://192.168.141.2';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  static const String login = '/api/Auth/login';
  static const String googleLogin = '/api/Auth/google-login';
  static const String appleLogin = '/api/auth/apple-login';
  static const String register = '/api/Auth/register';
  static const String sendRegisterCode = '/api/Auth/sendRegisterCode';
  static const String verifyRegisterCode = '/api/Auth/verifyRegisterCode';
  static const String refreshToken = '/api/Auth/refreshToken';
  static const String logout = '/api/Auth/logout';
  static const String forgotPassword = '/api/Auth/forgotPassword';
  static const String verifyResetCode = '/api/Auth/verifyResetCode';
  static const String resetPassword = '/api/Auth/resetPassword';
  static const String changePassword = '/api/Auth/changePassword';

  static const String homeData = '/home';
  static const String banners = '/api/AppBanners/getAll';
  static const String appBannersGetAll = '/api/AppBanners/getAll';
  static const String categories = '/home/categories';
  static const String featuredOffers = '/home/featured';

  static const String myProfile = '/api/Users/myProfile';
  static const String updateProfile = '/api/Users/myProfile/update';
  static const String myBarcode = '/api/Users/myBarcode';
  static const String userProfile = '/api/Users/myProfile';
  static const String setMyPinCode = '/api/Users/myPinCode/set';
  static const String verifyMyPinCode = '/api/Users/myPinCode/verify';
  static const String changeEmailSendCurrentCode =
      '/api/Users/changeEmail/sendCurrentCode';
  static const String changeEmailVerifyCurrentCode =
      '/api/Users/changeEmail/verifyCurrentCode';
  static const String changeEmailSendNewCode =
      '/api/Users/changeEmail/sendNewCode';
  static const String changeEmailConfirm = '/api/Users/changeEmail/confirm';
  static const String discounts = '/discounts';
  static const String partners = '/partners';
  static const String partnersGetAll = '/api/Partners/getAll';
  static const String partnersGetById = '/api/Partners/getById';
  static const String partnerCategoriesGetAll = '/api/PartnerCategories/getAll';
  static const String myFavorites = '/api/Partners/myFavorites';
  static String addPartnerToFavorites(String partnerId) =>
      '/api/Partners/myFavorites/add/$partnerId';
  static String removePartnerFromFavorites(String partnerId) =>
      '/api/Partners/myFavorites/remove/$partnerId';

  // Lookups
  static const String lookupPartners = '/api/Lookups/partners';
  static const String lookupOfferTypes = '/api/Lookups/offerTypes';
  static const String lookupTransactionTypes = '/api/Lookups/transactionTypes';
  static const String lookupTransactionStatuses =
      '/api/Lookups/transactionStatuses';

  // Partner Offers
  static const String partnerOffersGetAll = '/api/PartnerOffers/getAll';

  // Terms and Conditions
  static const String termsAndConditionsGetAll =
      '/api/TermsAndConditions/getAll';

  // Wallets
  static const String walletMyBalance = '/api/Wallets/myBalance';

  // Transactions
  static const String transactionsMy = '/api/Transactions/my';
  static const String transactionsGetById = '/api/Transactions/getById';

  // Support Topics & Chat Endpoints
  static const String supportTopicsActive = '/api/SupportTopics/active';
  static const String supportConversationsCreate =
      '/api/SupportConversations/create';
  static const String supportConversationsMy = '/api/SupportConversations/my';
  static String supportConversationsMyById(String id) =>
      '/api/SupportConversations/my/$id';
  static String supportConversationsMyMessages(String id) =>
      '/api/SupportConversations/my/$id/messages';
  static String supportConversationsMyMessagesSeen(String id) =>
      '/api/SupportConversations/my/$id/messages/seen';
  static String supportConversationsMyClose(String id) =>
      '/api/SupportConversations/my/$id/close';

  // SignalR Hub
  static String get supportChatHub => '$baseUrl/hubs/supportChat';

  // File Endpoints
  static const String fileUpload = '/api/File/upload';
  static String fileDownload(String attachId) => '/api/File/download/$attachId';
  static String fileDelete(String id) => '/api/File/delete/$id';

  // Notifications Endpoints & SignalR Hub
  static const String notificationsList = '/api/Notifications';
  static const String notificationsUnreadCount =
      '/api/Notifications/unread-count';
  static String notificationById(String id) => '/api/Notifications/$id';
  static String notificationMarkRead(String id) =>
      '/api/Notifications/$id/read';
  static const String notificationsReadAll = '/api/Notifications/read-all';
  static String get notificationsHub => '$baseUrl/hubs/notifications';
}
