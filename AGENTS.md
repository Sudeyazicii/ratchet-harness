# AGENTS.md — Sistem ve Geliştirme Anayasası (Değiştirilemez Kurallar)

Bu dosya, projede kod üreten tüm otonom ajanlar ve geliştiriciler için bağlayıcıdır. Aşağıdaki maddeler tartışmaya ve esnetilmeye kapalıdır:

## MADDE 1: ÇALIŞMA ZAMANI VE BAĞIMLILIKLAR
1.1. Hedef Ruby sürümü **3.4**'tür (`.ruby-version`).
1.2. Yalnızca Ruby standart kütüphanesi (`stdlib`) ve `Minitest` kullanılabilir. Harici gem eklenmesi KESİNLİKLE YASAKTIR.
1.3. Tüm dosyalarda `# frozen_string_literal: true` bildirimi zorunludur.

## MADDE 2: MİMARİ VE SÖZDİZİMİ KISITLAMALARI
2.1. **Monkey Patching YASAKTIR**: Ruby Core veya Standard Library sınıfları (`Object`, `String`, `Integer`, `Array` vb.) kesinlikle modifiye edilemez, açık sınıf (open class) açılamaz.
2.2. **method_missing YASAKTIR**: Dinamik metot çağrılarını yakalamak için `method_missing` veya `respond_to_missing?` kullanılamaz.
2.3. **Açık ve Aranabilir Metot Üretimi**: Durum sorguları (`aktif?`, `donduruldu?`, `mezun?`) `define_method` ile açık ve liste sorgularında (`instance_methods`) çıkacak şekilde tanımlanmalıdır.
2.4. Tanımlı olmayan durum/metot sorguları sessizce geçiştirilemez; standart `NoMethodError` fırlatılmalıdır.

## MADDE 3: DEVAMSIZLIK VE AKADEMİK DURUM KURALLARI
3.1. Toplam oturum sayısı 10'dur. Devamsızlık aralığı `0..10` tamsayılarıdır.
3.2. **SINIR VAKA (TAM 3 DEVAMSIZLIK)**: 10 oturumda %30 devamsızlık tam 3 oturuma karşılık gelir. Devamsızlık değeri **tam 3 ve üzeri** olduğunda (`>= 3`) öğrenci istisnasız **RİSKLİ** (`riskli?`) sayılır. Sınır değer `> 3` DEĞİL, `>= 3` olarak kodlanacaktır.
3.3. **KALMA KURALI**: Devamsızlık **4 ve üzeri** olduğunda (`>= 4`) öğrenci istisnasız **KALDI** (`kaldi?`) sayılır.
3.4. **ÖZGÜN KURALLAR**:
   - `onur_adayi?`: Yalnızca `aktif?` statüsünde ve devamsızlığı `0` olan öğrenciler.
   - `burs_kesilir?`: Devamsızlığı `riskli?` (`>= 3`) olan veya `donduruldu?` statüsündeki öğrenciler.

## MADDE 4: TEST VE GÜVENLİK ZORUNLULUĞU
4.1. Her yeni özellik veya değişiklik öncesinde ve sonrasında `bin/kontrol` çalıştırılmalıdır.
4.2. Minitest test suite'i sıfır hata ve sıfır başarısızlık ile tamamlanmalıdır.
4.3. Test koşulmadan veya `bin/kontrol` yeşil vermeden hiçbir kod tamamlanmış sayılamaz.
