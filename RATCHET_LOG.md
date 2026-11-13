# RATCHET_LOG.md — Hatadan Kalıcı Kurala (Mandal Günlüğü)

> **Dersin Tezi:** *"Ajan = Model + Harness." Kod yazmak ucuzladı; asıl mühendislik değeri ajanın neyi göreceğini, hangi kurallara uyacağını, sınır vakalarını nasıl yakalayacağını ve hatalarından nasıl kalıcı ders çıkaracağını tasarlamakta.*
>
> **Ratchet (Mandal) İlkesi:** Bir yazılım ajanının yaptığı hiçbir hata havada kaybolamaz. Karşılaşılan her hata bir daha asla tekrarlanamayacak şekilde anayasaya (`AGENTS.md`), sensöre (`Minitest`) veya yürütme kancasına (`bin/kontrol`) kilitlenir. Mandal sadece ileriye döner; geriye kayış imkansız kılınır.

---

## 1. Hata $\to$ Kalıcılaştırma Matrisi

| # | A Koşusunda Karşılaşılan Hata | Ortaya Çıkardığı Risk / Zafiyet | Kalıcı Kural / Test Çözümü | Mandallanan Katman | B Koşusundaki Davranış |
|---|-------------------------------|----------------------------------|----------------------------|--------------------|------------------------|
| **1** | **Ölümcül Sınır Vaka Sapması:** Devamsızlık %30 dendiğinde modelin `> 3` (`self > 3`) yazması. | 10 oturumda tam 3 devamsızlığı olan öğrenci normal geçirilerek okul yönetmeliği ihlal edildi. Sınır vaka gözden kaçtı. | Devamsızlık tam 3 olduğunda ve üzeri ise istisnasız **RİSKLİ** sayılır (`>= 3`). | **Rehber:** `AGENTS.md` Md. 3.2<br>**Sensör:** `test_sinir_vaka_tam_3_devamsizlik_kesinlikle_risklidir`<br>**Kanca:** `bin/kontrol` boundary regex | Model ilk seferde `devamsizlik >= 3` yazdı. Sınır vaka testi anında yeşil verdi. |
| **2** | **Kolaycı Anti-Pattern:** Durum sorguları için `method_missing` kullanılması. | Kod okunamaz hale geldi, metotlar `instance_methods` aramalarında çıkmadı, performans düştü, yazım hataları yutuldu. | `method_missing` ve `respond_to_missing?` kesinlikle yasaklandı. Durum sorguları `define_method` ile açık ve aranabilir üretildi. | **Rehber:** `AGENTS.md` Md. 2.2-2.3<br>**Sensör:** `test_durum_sorgulari_acik_ve_aranabilirdir`, `test_bilinmeyen_metot_nomethoderror_firlatir`<br>**Kanca:** `bin/kontrol` AST/grep denetimi | `define_method` ile `%i[aktif donduruldu mezun]` sorguları açıkça tanımlandı. Bilinmeyen metotlarda `NoMethodError` fırlatıldı. |
| **3** | **Global Kapsam Kirliliği:** Devamsızlık kontrolü için `Integer` core sınıfına Monkey Patch yapılması (`Integer#devamsizlik_sinirini_asti_mi?`). | Ruby global nesne alanı kirletildi, yan etkiler (side-effects) oluştu, modülerlik bozuldu. | Ruby Core sınıflarına (`Object`, `Integer`, `String`, vb.) dokunmak/açık sınıf açmak kesinlikle yasaklandı. Kontrol `DevamsizlikKontrol` sınıfına devredildi. | **Rehber:** `AGENTS.md` Md. 2.1<br>**Sensör:** `test_monkey_patch_yapilmadigi_dogrulanir`<br>**Kanca:** `bin/kontrol` monkey patch filtresi | Tamamen saf, modüler ve tek sorumluluk prensibine (SRP) uygun `DevamsizlikKontrol` sınıfı üretildi. |
| **4** | **Kalma Sınırı Belirsizliği:** Devamsızlıktan kalma kuralında modelin `> 4` yazması. | 4 devamsızlığı olan öğrencinin kalması gerekirken sistem ancak 5. devamsızlıkta kalma işlemi yaptı. | `kaldi?` kuralı net biçimde `devamsizlik >= 4` olarak tanımlandı. | **Rehber:** `AGENTS.md` Md. 3.3<br>**Sensör:** `test_sinir_vaka_tam_4_devamsizlik_kesinlikle_kaldidir` | Model sınır değerleri `>= 4` olarak eksiksiz kodladı. |
| **5** | **Girdi Validasyonu Eksikliği:** Devamsızlığa negatif sayı (`-2`) veya 10'dan büyük sayı (`15`) verilmesine izin verilmesi. | Veri tabanında mantıksız ve bozuk veri durumları oluştu. | `devamsizlik` değerinin `0..10` tamsayı aralığında (`DEVAMSIZLIK_ARALIGI`) olması zorunlu kılındı. Aksi halde `ArgumentError` fırlatıldı. | **Rehber:** `AGENTS.md` Md. 3.1<br>**Sensör:** `test_gecersiz_devamsizlik_araligi_hata_firlatir` | Girişler `validate_devamsizlik` ile koruma altına alındı. |
| **6** | **Ruby 3.4 Modern Standart İhmali:** Dosya başlarında `# frozen_string_literal: true` kullanılmaması. | Bellek optimizasyonundan feragat edildi, Ruby 3.4 önerileri çiğnendi. | Tüm Ruby dosyalarında ilk satırın `# frozen_string_literal: true` olması şart koşuldu. | **Rehber:** `AGENTS.md` Md. 1.3<br>**Kanca:** `bin/kontrol` başlık denetimi | Kod üretilir üretilmez kanca tarafından başlık denetimi yapıldı ve doğrulandı. |

---

## 2. Katman Bazında Güvenlik Duvarı Analizi

```
                          GELİŞTİRİCİ / MODEL
                                  │
                                  ▼
      ┌────────────────────────────────────────────────────────┐
      │ 1. REHBER KATMANI (AGENTS.md / CLAUDE.md)              │
      │    - Anayasa kuralları ajanın bağlamına önceden verilir │
      │    - Ambigüite ve varsayımlar sıfırlanır               │
      └───────────────────────────┬────────────────────────────┘
                                  │
                                  ▼
      ┌────────────────────────────────────────────────────────┐
      │ 2. KANCA KATMANI (bin/kontrol)                         │
      │    - Kaydetme/çalıştırma anında statik kod analizi      │
      │    - method_missing / monkey patch anında reddedilir   │
      └───────────────────────────┬────────────────────────────┘
                                  │
                                  ▼
      ┌────────────────────────────────────────────────────────┐
      │ 3. SENSÖR KATMANI (Minitest: test/ogrenci_test.rb)     │
      │    - Sınır vakalar (tam 3, tam 4 devamsızlık) sınanır   │
      │    - Bilinmeyen metot davranışları doğrulanır           │
      └───────────────────────────┬────────────────────────────┘
                                  │
                                  ▼
                           GÜVENLİ VE SAĞLAM KOD
```

### Katman 1: Rehber (`AGENTS.md` & `CLAUDE.md`)
- **Görevi:** Ajanın eğitim verisindeki "genel geçer ve esnek" Ruby pratiklerini kısıtlamak, projeye özgü katı sınırları belirlemek.
- **Etkisi:** Ajan sınır değerlerde ikilem yaşamaz; tam 3'ün riskli olduğunu ve `method_missing`'in yasak olduğunu doğrudan bilir.

### Katman 2: Doğrulama Kancası (`bin/kontrol`)
- **Görevi:** Kod çalışma zamanına gitmeden önce statik olarak yasaklı kalıpları (`method_missing`, monkey patch, `> 3` sınır hatası) tarar.
- **Etkisi:** Ajan hatalı bir kod üretse dahi insan müdahalesine gerek kalmadan anında önüne hata basar ve kodun commit edilmesini engeller.

### Katman 3: Sensör (`test/ogrenci_test.rb`)
- **Görevi:** Çalışma zamanında tüm uç sınır vakaları (`boundary conditions`) assert/refute ile denetler.
- **Etkisi:** 3 ve 4 devamsızlık değerleri arasındaki kritik geçişin ve `NoMethodError` fırlatma mekanizmasının %100 doğrulukla çalışmasını garanti altına alır.
