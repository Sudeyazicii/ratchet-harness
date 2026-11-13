# YZM379 · İleri Ruby ve Harness: Öğrenci ve Devamsızlık Kural Motoru

> **Dersin Temel Tezi:** *"Ajan = Model + Harness."*  
> Model (Claude, GPT vb.) zaten Ruby kodu yazabiliyor; kod yazmak artık ucuzladı. Asıl mühendislik değeri ajanın neyi göreceğini, hangi kurallara uyacağını, sınır vakalarını nasıl yakalayacağını ve hatalarından nasıl kalıcı ders çıkaracağını (**Ratchet / Mandal Mekanizması**) tasarlamakta yatmaktadır.  
> Bu projede *"vibe coding"* (hislerle kodlama) tamamen terk edilmiş; sayılar, metrikler, otomatik kancalar ve katı anayasa kuralları ile deterministik bir yazılım süreci kurgulanmıştır.

---

## 📋 İçindekiler
1. [Proje Mimarisi ve Sınıf Tasarımı](#1-proje-mimarisi-ve-sınıf-tasarımı)
2. [Kurallar ve Sınır Vaka Analizi](#2-kurallar-ve-sınır-vaka-analizi)
3. [Mandal (Ratchet) Altyapısı](#3-mandal-ratchet-altyapısı)
4. [A/B Koşusu ve Ölçüm Raporu](#4-ab-koşusu-ve-ölçüm-raporu)
5. [Doğrulama Kancası (`bin/kontrol`) Kullanımı](#5-doğrulama-kancası-binkontrol-kullanımı)
6. [Minitest Test Paketi ve Doğrulama](#6-minitest-test-paketi-ve-doğrulama)
7. [Yapamadıklarım ve Öğrenilen Dersler](#7-yapamadıklarım-ve-öğrenilen-dersler)

---

## 1. Proje Mimarisi ve Sınıf Tasarımı

Sistem iki temel Ruby modülü üzerinden kurgulanmıştır:

### `Ogrenci` (`lib/ogrenci.rb`)
- **Nitelikler:** `ad` (String), `durum` (`:aktif`, `:donduruldu`, `:mezun`), `devamsizlik` (`0..10` oturum).
- **Dinamik Metot Üretimi (`define_method`):**  
  Durum sorguları (`aktif?`, `donduruldu?`, `mezun?`) meta-programlama ile ancak açık ve aranabilir biçimde `define_method` kullanılarak tanımlanmıştır. `Ogrenci.instance_methods(false)` çağrıldığında bu metotlar net olarak listelenir.
- **YASAKLAR (Anti-Pattern Reddi):**  
  - Kesinlikle `method_missing` kullanılmamıştır. Tanımsız metot çağrılarında standart `NoMethodError` fırlatılır.
  - Kesinlikle Ruby çekirdek sınıflarına açık sınıf (Monkey Patch) yapılmamıştır.

### `DevamsizlikKontrol` (`lib/devamsizlik_kontrol.rb`)
- Devamsızlık kurallarını tek bir sorumluluk altında toplayan saf kural motorudur.
- Öğrencinin durumunu inceleyerek tekil sorgular (`riskli?`, `kaldi?`, `onur_adayi?`, `burs_kesilir?`) ve toplu etiketleme (`degerlendir`) gerçekleştirir.

---

## 2. Kurallar ve Sınır Vaka Analizi

Dönem toplam 10 oturumdan oluşmaktadır.

| Kural | Tetiklenme Şartı | Sınır Vaka Davranışı | Açıklama |
|---|---|---|---|
| **1. `riskli`** | `devamsizlik >= 3` | **Tam 3 Devamsızlık:** `%30` sınırıdır ve istisnasız **RİSKLİ SAYILIR**. | Modelin en sık yaptığı `> 3` hatası engellenmiş, `>= 3` kuralı mandallanmıştır. |
| **2. `kaldi`** | `devamsizlik >= 4` | **Tam 4 Devamsızlık:** Doğrudan **KALDI** sayılır. | 3 devamsızlıkta kalmaz (riskli kalır), 4 ve üzerinde kalır. |
| **3. `onur_adayi` (Özgün Kural 1)** | `aktif? && devamsizlik == 0` | Devamsızlık `1` olduğunda veya durum `donduruldu` ise derhal düşer. | Sıfır devamsızlıkla derslere kesintisiz devam eden aktif öğrencileri ödüllendirir. |
| **4. `burs_kesilir` (Özgün Kural 2)** | `riskli? \|\| donduruldu?` | Devamsızlık tam 3 olduğunda burs otomatik olarak kesintiye uğrar. | Akademik risk sınırına giren veya kaydını donduran öğrencilerin bursunu keser. |

---

## 3. Mandal (Ratchet) Altyapısı

Ratchet felsefesi: *Bir hatayı tespit et $\to$ Rehbere kural yaz $\to$ Sensörle doğrula $\to$ Kancayla kapıyı kapat.*

1. **Rehber Katmanı (`AGENTS.md` & `CLAUDE.md`):**  
   Ajanın uyması gereken anayasa kuralları (sürüm 3.4, monkey patch yasağı, method_missing yasağı, tam 3 devamsızlık kuralı). `CLAUDE.md`, Git index'inde gerçek bir symlink (`120000` mode) olarak `AGENTS.md`'ye bağlanmıştır.
2. **Sensör Katmanı (`test/ogrenci_test.rb`):**  
   Minitest ile sınır vakaları, `ArgumentError` durumlarını, `NoMethodError` fırlatılmasını ve `define_method` varlığını 10 test senaryosu ve 20 assertion ile denetler.
3. **Kanca Katmanı (`bin/kontrol`):**  
   Statik analiz (grep/AST) ile `method_missing`, monkey patch, `> 3` sınır hatası ve `frozen_string_literal` ihlallerini anında yakalar; ardından testleri çalıştırır.

---

## 4. A/B Koşusu ve Ölçüm Raporu

Gerçek log çıktıları [`logs/run_a_raw.log`](logs/run_a_raw.log) ve [`logs/run_b_harness.log`](logs/run_b_harness.log) dosyalarında kayıt altındadır.

### Karşılaştırma ve Metrik Tablosu

| Metrik / Parametre | A Koşusu (Rehbersiz & Ham Koşu) | B Koşusu (Harness & Ratchet Destekli) | Değişim / Kazanım |
|---|---|---|---|
| **Tur Sayısı (Turns)** | 3 Tur (Düzeltme ikazlarıyla) | **1 Tur (İlk seferde kusursuz)** | **%66.7 Azalma** (3 $\to$ 1) |
| **Karşılaşılan Kritik Hata Sayısı** | **5 Hata** (`> 3` sınır hatası, `method_missing`, monkey patch, `> 4` kalma hatası, validation yokluğu) | **0 Hata (Sıfır Hata)** | **%100 İyileşme** (5 $\to$ 0) |
| **Test Koruması (Sensör)** | Yok (Hatalar insan gözüyle fark edildi) | **Aktif (Minitest + Otomatik Kanca)** | Tam Güvenlik Ağı |
| **Giriş (Prompt) Tokenı** | ~42 token | ~460 token (AGENTS.md anayasası dahil) | Rehber bağlamı nedeniyle +418 token |
| **Toplam Token Tüketimi** | ~2,480 token (Tekrarlayan 3 turun kümülatif bağlamı) | ~980 token (Tek turda üretim ve kapanış) | **%60.5 Token Tasarrufu** (~1,500 token kazanç) |
| **Tahmini Maliyet** | $0.0372 (Düzeltmelerle şişen bağlam) | $0.0147 | **%60.5 Maliyet Düşüşü** |
| **Geliştirici Müdahale Eforu** | Yüksek (Her sınır değer için insan uyarısı gerekti) | **Sıfır (Otonom ve deterministik)** | Tam Otonomi |

> **Metrik Çıkarımı:** Rehber (`AGENTS.md`) girdi tokenını ilk başta bir miktar artırsa da, ajanın ilk turda doğru kodu üretmesini sağlayarak tekrarlayan hata-düzeltme döngülerini yok etmiş ve **toplam token tüketiminde %60.5 net tasarruf** sağlamıştır.

---

## 5. Doğrulama Kancası (`bin/kontrol`) Kullanımı

`bin/kontrol`, hem Unix/Linux/macOS kabuklarında (`bash`), hem de Windows ortamında (`bin/kontrol.ps1` ve `bin/kontrol.bat`) çalışacak hibrit mimaride kurgulanmıştır.

### Çalıştırma:

```bash
# Linux / macOS / Git Bash
./bin/kontrol

# Windows PowerShell
.\bin\kontrol.ps1

# Windows CMD
bin\kontrol.bat
```

### Kancanın Yaptığı Doğrulamalar:
1. `method_missing` kullanılmış mı? $\to$ Varsa kural ihlaliyle durdurur.
2. Ruby Core sınıflarına Monkey Patch yapılmış mı? $\to$ Varsa durdurur.
3. Devamsızlık kontrolünde `> 3` yazılmış mı? $\to$ Varsa `devamsizlik >= 3` olmalıdır diyerek durdurur.
4. Dosya başlarında `# frozen_string_literal: true` eksik mi? $\to$ Varsa uyarır.
5. Minitest testlerini koşturur ve sonucu raporlar.

---

## 6. Minitest Test Paketi ve Doğrulama

Testleri doğrudan çalıştırmak için:

```bash
ruby -Ilib:test test/ogrenci_test.rb
```

### Test Kapsamı (20 Assertion):
- `test_ogrenci_basariyla_olusturulur`
- `test_gecersiz_ad_hata_firlatir`
- `test_gecersiz_durum_hata_firlatir`
- `test_gecersiz_devamsizlik_araligi_hata_firlatir`
- `test_durum_sorgulari_define_method_ile_dogru_calisir`
- `test_durum_sorgulari_acik_ve_aranabilirdir`
- `test_bilinmeyen_metot_nomethoderror_firlatir_ve_method_missing_kullanilmaz`
- `test_monkey_patch_yapilmadigi_dogrulanir`
- `test_sinir_vaka_tam_3_devamsizlik_kesinlikle_risklidir` (Kritik sınır vaka)
- `test_sinir_vaka_tam_4_devamsizlik_kesinlikle_kaldidir` (Kritik sınır vaka)
- `test_ozgun_kural_onur_adayi_sadece_sifir_devamsizlik_ve_aktif_icin_gecerlidir`
- `test_ozgun_kural_burs_kesilir_riskli_veya_donduruldu_icin_calisir`
- `test_degerlendir_tum_etiketleri_eksiksiz_uretir`
- `test_gecersiz_nesne_tipi_arguman_hatasi_verir`

---

## 7. Yapamadıklarım ve Öğrenilen Dersler

1. **Windows Ortamında Yerel Sembolik Bağ (Symlink) Kısıtı:**  
   Windows işletim sisteminde yönetici izni (`SeCreateSymbolicLinkPrivilege`) olmadan `mklink` veya `New-Item -ItemType SymbolicLink` çalıştırıldığında işletim sistemi erişim engeli vermektedir.  
   *Aşma Yöntemi:* Git'in nesne tabanlı mimarisinden faydalanılarak `git update-index --add --cacheinfo 120000` komutu ile Git ağacında `CLAUDE.md -> AGENTS.md` bağı tam bir POSIX symlink (mode 120000) olarak saklandı. Böylece repo GitHub veya Linux/macOS ortamına çekildiğinde gerçek bir sembolik bağ olarak davranması garanti altına alındı.
2. **LLM'lerin İstatistiki "Aşma" Önyargısı:**  
   Büyük dil modelleri eğitim verilerindeki genel "limit aşımı" örnekleri nedeniyle `%30 sınırı` ifadesini koşulsuz olarak `> 3` şeklinde algılama eğilimindedir. Modelin sağduyusuna güvenilemeyeceği, bu tür sınır koşullarının (`boundary conditions`) mutlaka hem anayasada hem de test suite'inde katı birer sensör olarak kilitlenmesi gerektiği somut metriklerle tecrübe edilmiştir.
3. **Otomasyonun Gücü:**  
   `bin/kontrol` gibi bir kanca geliştirici döngüsüne entegre edilmediğinde, insan dikkatinin zamanla dağıldığı ve hatalı kodların ana dala sızabildiği görülmüştür. Harness mühendisliği, model kalitesinden bağımsız olarak yazılım kalitesini belirli bir taban seviyesinin altına düşürmeyen tek garantidir.
