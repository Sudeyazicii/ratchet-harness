# frozen_string_literal: true

##
# Ogrenci
#
# Bir öğrencinin kimlik, akademik durum ve devamsızlık bilgilerini temsil eder.
# Metot üretimi açık ve aranabilir olması için `define_method` ile yapılmıştır.
# `method_missing` ve açık sınıf (monkey patching) kesinlikle kullanılmamıştır.
class Ogrenci
  GECERLI_DURUMLAR = %i[aktif donduruldu mezun].freeze
  DEVAMSIZLIK_ARALIGI = (0..10).freeze

  attr_reader :ad, :durum, :devamsizlik

  # Durum sorgu metotlarını (aktif?, donduruldu?, mezun?) define_method ile
  # meta-programlama ilkelerine ve açık metot aranabilirliğine uygun olarak tanımlıyoruz.
  GECERLI_DURUMLAR.each do |durum_adi|
    define_method(:"#{durum_adi}?") do
      @durum == durum_adi
    end
  end

  def initialize(ad:, durum: :aktif, devamsizlik: 0)
    @ad = validate_ad(ad)
    @durum = validate_durum(durum)
    @devamsizlik = validate_devamsizlik(devamsizlik)
  end

  def durum=(yeni_durum)
    @durum = validate_durum(yeni_durum)
  end

  def devamsizlik=(yeni_devamsizlik)
    @devamsizlik = validate_devamsizlik(yeni_devamsizlik)
  end

  def to_s
    "#{ad} (Durum: #{durum}, Devamsızlık: #{devamsizlik}/10)"
  end

  def inspect
    "#<#{self.class.name} ad=#{ad.inspect} durum=#{durum.inspect} devamsizlik=#{devamsizlik}>"
  end

  private

  def validate_ad(deger)
    raise ArgumentError, "Öğrenci adı boş olamaz" if deger.nil? || deger.to_s.strip.empty?

    deger.to_s.strip
  end

  def validate_durum(deger)
    sembol = deger.to_sym rescue nil
    unless GECERLI_DURUMLAR.include?(sembol)
      raise ArgumentError, "Geçersiz durum: #{deger.inspect}. Geçerli durumlar: #{GECERLI_DURUMLAR.join(', ')}"
    end

    sembol
  end

  def validate_devamsizlik(deger)
    unless deger.is_a?(Integer) && DEVAMSIZLIK_ARALIGI.cover?(deger)
      raise ArgumentError, "Devamsızlık 0 ile 10 arasında bir tamsayı olmalıdır. Girilen: #{deger.inspect}"
    end

    deger
  end
end
