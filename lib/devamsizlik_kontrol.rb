# frozen_string_literal: true

require_relative "ogrenci"

##
# DevamsizlikKontrol
#
# Bir öğrencinin 10 oturumluk bir dönem içerisindeki devamsızlık durumuna göre
# akademik durumunu ve risk seviyesini tespit eden kural motoru.
#
# Kurallar:
# 1. riskli: Devamsızlık tam 3 olduğunda (%30) ve üzeri ise (>= 3). Sınır vaka: 3 devamsızlık RİSKLİ sayılır.
# 2. kaldi: Devamsızlık 4 ve üzeri olduğunda (>= 4).
# 3. Kendi Kuralımız - onur_adayi: Öğrenci aktif ve devamsızlığı 0 ise onur adayıdır.
# 4. Kendi Kuralımız - burs_kesilir: Devamsızlık >= 3 ise veya öğrenci kaydını dondurmuşsa bursu kesilir.
#
# Monkey patching ve method_missing kesinlikle kullanılmamıştır.
class DevamsizlikKontrol
  DEVAMSIZLIK_SINIRI_RISK = 3   # 10 oturumda %30 = 3 oturum. Sınır vaka: 3 dahil (>= 3)
  DEVAMSIZLIK_SINIRI_KALMA = 4  # 4 ve üzeri devamsızlık doğrudan kalma sebebidir (>= 4)

  class << self
    # Kural 1: Sınır vaka: Tam 3 devamsızlık riskli SAYILIR (>= 3)
    def riskli?(ogrenci)
      ogrenci_dogrula!(ogrenci)
      ogrenci.devamsizlik >= DEVAMSIZLIK_SINIRI_RISK
    end

    # Kural 2: Devamsızlık 4 ve üzeri olduğunda öğrenci devamsızlıktan kalır (>= 4)
    def kaldi?(ogrenci)
      ogrenci_dogrula!(ogrenci)
      ogrenci.devamsizlik >= DEVAMSIZLIK_SINIRI_KALMA
    end

    # Kural 3 (Özgün Kural): Onur öğrencisi adaylığı
    # Öğrenci aktif statüde olmalı ve hiç devamsızlığı bulunmamalıdır (== 0).
    def onur_adayi?(ogrenci)
      ogrenci_dogrula!(ogrenci)
      ogrenci.aktif? && ogrenci.devamsizlik.zero?
    end

    # Kural 4 (Özgün Kural): Burs kesilme kontrolü
    # Risk sınırına ulaşan (>= 3) veya donduruldu statüsündeki öğrencilerin bursu kesilir.
    def burs_kesilir?(ogrenci)
      ogrenci_dogrula!(ogrenci)
      ogrenci.donduruldu? || riskli?(ogrenci)
    end

    # Öğrencinin bütün kurallara göre durumunu değerlendirir ve etiket sembolleri döndürür.
    # Örnek: [:aktif, :onur_adayi] veya [:aktif, :riskli, :kaldi, :burs_kesilir]
    def degerlendir(ogrenci)
      ogrenci_dogrula!(ogrenci)

      durumlar = [ogrenci.durum]
      durumlar << :onur_adayi if onur_adayi?(ogrenci)
      durumlar << :riskli if riskli?(ogrenci)
      durumlar << :kaldi if kaldi?(ogrenci)
      durumlar << :burs_kesilir if burs_kesilir?(ogrenci)
      durumlar.freeze
    end

    # İnsan tarafından okunabilir özet rapor
    def durum_ozeti(ogrenci)
      ogrenci_dogrula!(ogrenci)
      etiketler = degerlendir(ogrenci)

      aciklamalar = []
      aciklamalar << "Öğrenci: #{ogrenci.ad}"
      aciklamalar << "Akademik Statü: #{ogrenci.durum.to_s.upcase}"
      aciklamalar << "Devamsızlık: #{ogrenci.devamsizlik}/10"

      if etiketler.include?(:kaldi)
        aciklamalar << "Sonuç: DEVAMSIZLIKTAN KALDI (Oturum >= 4)"
      elsif etiketler.include?(:riskli)
        aciklamalar << "Sonuç: DEVAMSIZLIK RİSK SINIRINDA (Oturum >= 3)"
      else
        aciklamalar << "Sonuç: DEVAM DURUMU NORMAL"
      end

      aciklamalar << "Özel Durum: ONUR LİSTESİ ADAYI (Sıfır Devamsızlık)" if etiketler.include?(:onur_adayi)
      aciklamalar << "İdari Uyarı: BURS KESİNTİSİ UYGULANIR" if etiketler.include?(:burs_kesilir)

      aciklamalar.join(" | ")
    end

    private

    def ogrenci_dogrula!(ogrenci)
      unless ogrenci.is_a?(Ogrenci)
        raise ArgumentError, "Beklenen Ogrenci nesnesi, alınan: #{ogrenci.class}"
      end
    end
  end
end
