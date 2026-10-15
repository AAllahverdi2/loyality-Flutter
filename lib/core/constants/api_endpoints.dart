class ApiEndpoints {
  static const String baseUrl = 'http://192.168.100.173';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  static const String login = '/api/Auth/login';
  static const String googleLogin = '/api/Auth/google-login';
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
  static const String lookupTransactionStatuses = '/api/Lookups/transactionStatuses';

  // Partner Offers
  static const String partnerOffersGetAll = '/api/PartnerOffers/getAll';

  // Terms and Conditions
  static const String termsAndConditionsGetAll = '/api/TermsAndConditions/getAll';

  // Wallets
  static const String walletMyBalance = '/api/Wallets/myBalance';

  // Transactions
  static const String transactionsMy = '/api/Transactions/my';
  static const String transactionsGetById = '/api/Transactions/getById';

  // Support Topics
  static const String supportTopicsActive = '/api/SupportTopics/active';

  // File Endpoints
  static const String fileUpload = '/api/File/upload';
  static String fileDownload(String attachId) => '/api/File/download/$attachId';
  static String fileDelete(String id) => '/api/File/delete/$id';
}
