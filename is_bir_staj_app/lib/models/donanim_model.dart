class DonanimModel {
  final String en;
  final String? bilgisayarAdi;
  final String? cinsi;
  final String? marka;
  final String? model;
  final String? durumu;
  final String? kullanicisi;

  DonanimModel({
    required this.en,
    this.bilgisayarAdi,
    this.cinsi,
    this.marka,
    this.model,
    this.durumu,
    this.kullanicisi,
  });

  factory DonanimModel.fromJson(Map<String, dynamic> json) {
    return DonanimModel(
      en: json['en'] ?? '',
      bilgisayarAdi: json['bilgisayarAdi'],
      cinsi: json['cinsi'],
      marka: json['marka'],
      model: json['model'],
      durumu: json['durumu'],
      kullanicisi: json['kullanicisi'],
    );
  }
}