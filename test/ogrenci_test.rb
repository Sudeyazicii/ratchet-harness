# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/ogrenci"
require_relative "../lib/devamsizlik_kontrol"

class OgrenciTest < Minitest::Test
  def setup
    @ogrenci_aktif = Ogrenci.new(ad: "Ahmet Yılmaz", durum: :aktif, devamsizlik: 0)
    @ogrenci_donduruldu = Ogrenci.new(ad: "Ayşe Demir", durum: :donduruldu, devamsizlik: 1)
    @ogrenci_mezun = Ogrenci.new(ad: "Mehmet Kaya", durum: :mezun, devamsizlik: 2)
  end

  # =========================================================================
  # 1. TEMEL NİTELİK VE GİRDİ DOĞRULAMA TESTLERİ
  # =========================================================================

  def test_ogrenci_basariyla_olusturulur
    assert_equal "Ahmet Yılmaz", @ogrenci_aktif.ad
    assert_equal :aktif, @ogrenci_aktif.durum
    assert_equal 0, @ogrenci_aktif.devamsizlik
  end

  def test_gecersiz_ad_hata_firlatir
    assert_raises(ArgumentError) { Ogrenci.new(ad: nil) }
    assert_raises(ArgumentError) { Ogrenci.new(ad: "   ") }
  end

  def test_gecersiz_durum_hata_firlatir
    assert_raises(ArgumentError) { Ogrenci.new(ad: "Ali", durum: :kayit_silindi) }
    assert_raises(ArgumentError) { @ogrenci_aktif.durum = :bilinmeyen }
  end

  def test_gecersiz_devamsizlik_araligi_hata_firlatir
    assert_raises(ArgumentError) { Ogrenci.new(ad: "Ali", devamsizlik: -1) }
    assert_raises(ArgumentError) { Ogrenci.new(ad: "Ali", devamsizlik: 11) }
    assert_raises(ArgumentError) { Ogrenci.new(ad: "Ali", devamsizlik: "3") }
    assert_raises(ArgumentError) { @ogrenci_aktif.devamsizlik = 12 }
  end

  # =========================================================================
  # 2. DİNAMİK METOT ÜRETİMİ (define_method) VE MONKEY-PATCH/METHOD_MISSING TESTLERİ
  # =========================================================================

  def test_durum_sorgulari_define_method_ile_dogru_calisir
    assert_equal true, @ogrenci_aktif.aktif?
    assert_equal false, @ogrenci_aktif.donduruldu?
    assert_equal false, @ogrenci_aktif.mezun?

    assert_equal false, @ogrenci_donduruldu.aktif?
    assert_equal true, @ogrenci_donduruldu.donduruldu?
    assert_equal false, @ogrenci_donduruldu.mezun?

    assert_equal false, @ogrenci_mezun.aktif?
    assert_equal false, @ogrenci_mezun.donduruldu?
    assert_equal true, @ogrenci_mezun.mezun?
  end

  def test_durum_sorgulari_acik_ve_aranabilirdir
    # define_method ile üretilen metotlar instance_methods listesinde görünmelidir
    assert_includes Ogrenci.instance_methods(false), :aktif?
    assert_includes Ogrenci.instance_methods(false), :donduruldu?
    assert_includes Ogrenci.instance_methods(false), :mezun?

    assert @ogrenci_aktif.respond_to?(:aktif?)
    assert @ogrenci_aktif.respond_to?(:donduruldu?)
    assert @ogrenci_aktif.respond_to?(:mezun?)
  end

  def test_bilinmeyen_metot_nomethoderror_firlatir_ve_method_missing_kullanilmaz
    # method_missing ile yakalama YASAKTIR. Standart NoMethodError dönmelidir.
    assert_raises(NoMethodError) { @ogrenci_aktif.kayitli_mi? }
    assert_raises(NoMethodError) { @ogrenci_aktif.devamsiz_mi? }
    assert_equal false, @ogrenci_aktif.respond_to?(:kayitli_mi?)
  end

  def test_monkey_patch_yapilmadigi_dogrulanir
    # Ruby Core sınıflarına (Object, Integer, String) hiçbir ekleme yapılmamış olmalıdır
    refute Integer.instance_methods.include?(:devamsiz_mi?)
    refute Object.instance_methods.include?(:ogrenci_durumu)
    refute String.instance_methods.include?(:aktif_ogrenci?)
  end

  # =========================================================================
  # 3. KURAL MOTORU TESTLERİ VE KRİTİK SINIR VAKA TESTLERİ (>= 3 ve >= 4)
  # =========================================================================

  def test_sinir_vaka_tam_3_devamsizlik_kesinlikle_risklidir
    # Ödev Kuralı: Devamsızlık tam 3 olduğunda (10 oturumda %30) ve üzeri ise (>= 3).
    # Sınır vaka: 3 devamsızlık riskli SAYILIR.
    ogrenci_2 = Ogrenci.new(ad: "Sınır Altı", devamsizlik: 2)
    ogrenci_3 = Ogrenci.new(ad: "Tam Sınır", devamsizlik: 3)
    ogrenci_4 = Ogrenci.new(ad: "Sınır Üstü", devamsizlik: 4)

    # 2 devamsızlık -> riskli DEĞİL
    refute DevamsizlikKontrol.riskli?(ogrenci_2), "2 devamsızlık riskli olmamalıdır"

    # 3 devamsızlık -> RİSKLİ (CRITICAL BOUNDARY TEST)
    assert DevamsizlikKontrol.riskli?(ogrenci_3), "TAM 3 DEVAMSIZLIK RİSKLİ SAYILMALIDIR (>= 3)"

    # 4 devamsızlık -> RİSKLİ
    assert DevamsizlikKontrol.riskli?(ogrenci_4), "4 devamsızlık riskli olmalıdır"
  end

  def test_sinir_vaka_tam_4_devamsizlik_kesinlikle_kaldidir
    # Kural 2: Devamsızlık 4 ve üzeri olduğunda (>= 4) kaldı sayılır.
    ogrenci_3 = Ogrenci.new(ad: "Üç Devamsızlık", devamsizlik: 3)
    ogrenci_4 = Ogrenci.new(ad: "Dört Devamsızlık", devamsizlik: 4)
    ogrenci_5 = Ogrenci.new(ad: "Beş Devamsızlık", devamsizlik: 5)
    ogrenci_10 = Ogrenci.new(ad: "On Devamsızlık", devamsizlik: 10)

    # 3 devamsızlık -> Henüz kalmadı (sadece riskli)
    refute DevamsizlikKontrol.kaldi?(ogrenci_3), "3 devamsızlıkta henüz kalınmaz"

    # 4 devamsızlık -> KALDI (CRITICAL BOUNDARY TEST)
    assert DevamsizlikKontrol.kaldi?(ogrenci_4), "TAM 4 DEVAMSIZLIK KALDI SAYILMALIDIR (>= 4)"

    # 5 ve 10 devamsızlık -> KALDI
    assert DevamsizlikKontrol.kaldi?(ogrenci_5)
    assert DevamsizlikKontrol.kaldi?(ogrenci_10)
  end

  # =========================================================================
  # 4. ÖZGÜN KURALLAR TESTİ (:onur_adayi ve :burs_kesilir)
  # =========================================================================

  def test_ozgun_kural_onur_adayi_sadece_sifir_devamsizlik_ve_aktif_icin_gecerlidir
    ogrenci_sifir_aktif = Ogrenci.new(ad: "Örnek Öğrenci", durum: :aktif, devamsizlik: 0)
    ogrenci_bir_aktif = Ogrenci.new(ad: "Bir Devamsızlık", durum: :aktif, devamsizlik: 1)
    ogrenci_sifir_donduruldu = Ogrenci.new(ad: "Donduran", durum: :donduruldu, devamsizlik: 0)

    assert DevamsizlikKontrol.onur_adayi?(ogrenci_sifir_aktif), "Sıfır devamsızlık ve aktif olan onur adayıdır"
    refute DevamsizlikKontrol.onur_adayi?(ogrenci_bir_aktif), "1 devamsızlığı olan onur adayı olamaz"
    refute DevamsizlikKontrol.onur_adayi?(ogrenci_sifir_donduruldu), "Aktif olmayan öğrenci onur adayı olamaz"
  end

  def test_ozgun_kural_burs_kesilir_riskli_veya_donduruldu_icin_calisir
    ogrenci_temiz = Ogrenci.new(ad: "Burslu", durum: :aktif, devamsizlik: 2)
    ogrenci_riskli = Ogrenci.new(ad: "Burslu Riskli", durum: :aktif, devamsizlik: 3)
    ogrenci_donduruldu = Ogrenci.new(ad: "Burslu Donduran", durum: :donduruldu, devamsizlik: 1)

    refute DevamsizlikKontrol.burs_kesilir?(ogrenci_temiz)
    assert DevamsizlikKontrol.burs_kesilir?(ogrenci_riskli), "Tam 3 devamsızlıkta burs kesilmelidir"
    assert DevamsizlikKontrol.burs_kesilir?(ogrenci_donduruldu), "Dondurulduğunda burs kesilmelidir"
  end

  # =========================================================================
  # 5. TOPLU DEĞERLENDİRME VE RAPORLAMA TESTLERİ
  # =========================================================================

  def test_degerlendir_tum_etiketleri_eksiksiz_uretir
    ogrenci_mukemmel = Ogrenci.new(ad: "Tam Puan", durum: :aktif, devamsizlik: 0)
    ogrenci_sinir_3 = Ogrenci.new(ad: "Sınır Üç", durum: :aktif, devamsizlik: 3)
    ogrenci_kalan = Ogrenci.new(ad: "Kalan", durum: :aktif, devamsizlik: 4)

    assert_equal %i[aktif onur_adayi], DevamsizlikKontrol.degerlendir(ogrenci_mukemmel)
    assert_equal %i[aktif riskli burs_kesilir], DevamsizlikKontrol.degerlendir(ogrenci_sinir_3)
    assert_equal %i[aktif riskli kaldi burs_kesilir], DevamsizlikKontrol.degerlendir(ogrenci_kalan)
  end

  def test_gecersiz_nesne_tipi_arguman_hatasi_verir
    assert_raises(ArgumentError) { DevamsizlikKontrol.riskli?("Öğrenci") }
    assert_raises(ArgumentError) { DevamsizlikKontrol.kaldi?(nil) }
    assert_raises(ArgumentError) { DevamsizlikKontrol.degerlendir(123) }
  end
end
