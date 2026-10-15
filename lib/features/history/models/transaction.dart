import 'package:flutter/material.dart';

enum TransactionType { earn, spend, discount }

class Transaction {
  const Transaction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.type,
    this.secondaryAmount,
    this.spentBonus,
    this.earnedBonus,
  });

  final String id;
  final String title;
  final String subtitle;
  final String amount;
  final String date;
  final TransactionType type;
  final String? secondaryAmount;
  final double? spentBonus;
  final double? earnedBonus;
}

class TransactionDetailItem {
  const TransactionDetailItem({
    required this.name,
    required this.count,
    required this.price,
  });

  final String name;
  final int count;
  final double price;
}

class TransactionDetail {
  const TransactionDetail({
    required this.id,
    required this.partnerName,
    required this.partnerLogo,
    required this.category,
    required this.categoryIcon,
    required this.address,
    required this.date,
    required this.status,
    required this.totalAmount,
    required this.cashbackEarned,
    this.bonusSpent = 0.0,
    this.netBonus = 0.0,
    required this.paymentMethod,
    required this.items,
  });

  final String id;
  final String partnerName;
  final String partnerLogo;
  final String category;
  final IconData categoryIcon;
  final String address;
  final String date;
  final String status;
  final double totalAmount;
  final double cashbackEarned;
  final double bonusSpent;
  final double netBonus;
  final String paymentMethod;
  final List<TransactionDetailItem> items;
}

const List<Transaction> kTransactions = [
  Transaction(
    id: '1',
    title: 'Bravo Market',
    subtitle: 'Alış-veriş bonusu',
    amount: '+ 2.50 ₼',
    date: 'Bu gün, 14:30',
    type: TransactionType.earn,
  ),
  Transaction(
    id: '2',
    title: 'Stilist Nigar',
    subtitle: 'Xidmət ödənişi',
    amount: '- 15.00 ₼',
    date: 'Dünən, 18:00',
    type: TransactionType.spend,
  ),
  Transaction(
    id: '3',
    title: 'Baku Medical Plaza',
    subtitle: 'Endirim tətbiq edildi',
    amount: '10%',
    date: '12 Fev, 10:00',
    type: TransactionType.discount,
  ),
  Transaction(
    id: '4',
    title: 'Hill Restaurant',
    subtitle: 'Hesab ödənişi',
    amount: '- 45.00 ₼',
    date: '10 Fev, 21:15',
    type: TransactionType.spend,
  ),
  Transaction(
    id: '5',
    title: 'Azera Bonus',
    subtitle: 'Hədiyyə bonus',
    amount: '+ 10.00 ₼',
    date: '01 Fev, 09:00',
    type: TransactionType.earn,
  ),
  Transaction(
    id: '6',
    title: 'VetArt',
    subtitle: 'Müayinə',
    amount: '5%',
    date: '28 Yan, 15:30',
    type: TransactionType.discount,
  ),
];

const Map<String, TransactionDetail> kTransactionDetails = {
  '1': TransactionDetail(
    id: '1',
    partnerName: 'Bravo Market',
    partnerLogo:
        'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?auto=format&fit=crop&w=200&q=80',
    category: 'Supermarket',
    categoryIcon: Icons.shopping_cart_outlined,
    address: 'Gənclik Mall, Bakı',
    date: 'Bu gün, 14:30',
    status: 'Uğurlu',
    totalAmount: 25.0,
    cashbackEarned: 2.5,
    paymentMethod: 'Visa **** 4242',
    items: [
      TransactionDetailItem(name: 'Süd 1L', count: 2, price: 4.0),
      TransactionDetailItem(name: 'Çörək', count: 1, price: 1.2),
      TransactionDetailItem(name: 'Meyvə', count: 1, price: 8.5),
    ],
  ),
  '2': TransactionDetail(
    id: '2',
    partnerName: 'Stilist Nigar',
    partnerLogo:
        'https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=200&q=80',
    category: 'Xidmət',
    categoryIcon: Icons.content_cut_outlined,
    address: 'Nizami küç. 45',
    date: 'Dünən, 18:00',
    status: 'Uğurlu',
    totalAmount: 15.0,
    cashbackEarned: 0,
    paymentMethod: 'Nağd',
    items: [
      TransactionDetailItem(name: 'Xidmət ödənişi', count: 1, price: 15.0),
    ],
  ),
  '3': TransactionDetail(
    id: '3',
    partnerName: 'Baku Medical Plaza',
    partnerLogo:
        'https://images.unsplash.com/photo-1631217868264-e5b90bb7e133?auto=format&fit=crop&w=200&q=80',
    category: 'Səhiyyə',
    categoryIcon: Icons.medical_services_outlined,
    address: '28 May, Bakı',
    date: '12 Fev, 10:00',
    status: 'Uğurlu',
    totalAmount: 120.0,
    cashbackEarned: 0,
    paymentMethod: 'Mastercard **** 8888',
    items: [
      TransactionDetailItem(name: 'Müayinə', count: 1, price: 80.0),
      TransactionDetailItem(name: 'Analizlər', count: 1, price: 40.0),
    ],
  ),
  '4': TransactionDetail(
    id: '4',
    partnerName: 'Hill Restaurant',
    partnerLogo:
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=200&q=80',
    category: 'Restoran',
    categoryIcon: Icons.restaurant_outlined,
    address: 'Neftçilər pr. 73',
    date: '10 Fev, 21:15',
    status: 'Uğurlu',
    totalAmount: 45.0,
    cashbackEarned: 2.25,
    paymentMethod: 'Visa **** 4242',
    items: [
      TransactionDetailItem(name: 'Əsas yemək', count: 1, price: 22.0),
      TransactionDetailItem(name: 'İçki', count: 2, price: 11.5),
    ],
  ),
  '5': TransactionDetail(
    id: '5',
    partnerName: 'Azera Bonus',
    partnerLogo:
        'https://images.unsplash.com/photo-1607083206869-4c7672e72a8a?auto=format&fit=crop&w=200&q=80',
    category: 'Bonus',
    categoryIcon: Icons.card_giftcard_outlined,
    address: '—',
    date: '01 Fev, 09:00',
    status: 'Uğurlu',
    totalAmount: 0,
    cashbackEarned: 10.0,
    paymentMethod: '—',
    items: [
      TransactionDetailItem(name: 'Hədiyyə bonus', count: 1, price: 0),
    ],
  ),
  '6': TransactionDetail(
    id: '6',
    partnerName: 'VetArt',
    partnerLogo:
        'https://images.unsplash.com/photo-1587300003388-59208cc962cb?auto=format&fit=crop&w=200&q=80',
    category: 'Veterinar',
    categoryIcon: Icons.pets_outlined,
    address: 'Səməd Vurğun 34',
    date: '28 Yan, 15:30',
    status: 'Uğurlu',
    totalAmount: 35.0,
    cashbackEarned: 0,
    paymentMethod: 'Kart',
    items: [
      TransactionDetailItem(name: 'Müayinə', count: 1, price: 35.0),
    ],
  ),
};
