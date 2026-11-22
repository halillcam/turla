# Turla

Turla, butik tur firmaları ile müşterilerini aynı yerde buluşturan bir tur satış ve tur günü yönetim uygulamasıdır.

Küçük ve orta ölçekli tur firmaları satışlarını çoğunlukla telefon, mesajlaşma uygulamaları ve el ile tutulan listelerle yürütüyor. Kontenjanın ne kadarının dolduğu, kimin ödeme yaptığı, otobüse kimin bindiği ve yolculara son dakika bilgisinin nasıl ulaştırılacağı gibi işler hem firma hem de müşteri için yorucu ve hataya açık. Turla bu süreci tek bir sistemde topluyor: müşteri turu telefonundan bulup bilet alıyor, firma turlarını ve katılımcılarını panelden yönetiyor, tur sorumlusu da tur günü yolcuları QR kod ile karşılayıp onlarla uygulama üzerinden iletişim kuruyor.

Proje Kahramanmaraş'ta geliştiriliyor ve şu an MVP aşamasında. Mobil uygulama müşteriler ve tur sorumluları için, web paneli ise tur firmaları ve sistem yöneticisi için.

## Roller

**Misafir.** Uygulamayı açan herkes giriş yapmadan şehrini seçip o şehirden kalkan turları bölgelere göre görebilir, tur detayını, programını ve kalan kontenjanı inceleyebilir. Bilet almak için giriş yapması gerekir.

**Müşteri.** Turun uygun bir tarihini seçip bilet alır. Bilet alındığında ona özel, tek kullanımlık bir QR kod oluşur. Bu QR kod internet olmadan da açılabilir, çünkü tur günü otobüste bağlantı olmayabilir. Müşteri biletini kalkıştan en geç bir saat öncesine kadar iptal edebilir; iptal edilen koltuk tekrar satışa açılır ve ödenen tutarın tamamı iade edilir. Tur günü QR kodu okutulduktan sonra tur sohbetine katılır ve tur sorumlusunun duyurularını alır.

**Tur sorumlusu (rehber).** Firmanın çalışanıdır ve tur tarihlerine atanır. Atandığı tarihte katılımcı listesini görür, gelenleri ve gelmeyenleri ayırt eder, QR kodları okutur, yolculara duyuru gönderir ve sohbete katılır. Tur bittiğinde "turu bitir" talebi gönderir.

**Şirket yöneticisi.** Web panelinden turları, tarihleri, kontenjanı, araç ve şoför bilgisini, tur programını ve görselleri yönetir. Rehber hesaplarını açar ve tarihlere atar. Telefonla ya da ofisten bilet alan müşterileri sisteme kendisi ekleyebilir. Rehberin gönderdiği bitiş talebini onaylar; onay yalnızca o tarihi kapatır, aynı turun diğer tarihleri etkilenmez.

**Sistem yöneticisi.** Sisteme firma ekler, firmaları açıp kapatır, tüm verileri görür ve firmalara duyuru gönderir.

## Nasıl çalışıyor

Bilet alma, iptal ve iade, QR okutma ve tur bitirme gibi para ve kontenjanla ilgili işlemler telefonda değil, sunucuda tek bir işlem halinde yapılıyor. Böylece iki kişi aynı anda son koltuğu almaya çalışırsa koltuğu yalnızca biri alabiliyor ve bir QR kod bir kez okutulduktan sonra tekrar kullanılamıyor.

Herkes yalnızca kendisini ilgilendiren veriyi görüyor. Bir firma yalnızca kendi turlarını ve biletlerini, müşteri yalnızca kendi biletlerini görüyor. Tur sohbetine de yalnızca QR kodu okutulmuş yolcular ve o tarihin rehberi yazabiliyor.

Gerçek ödeme altyapısı henüz bağlı değil. MVP'de ödeme adımı bir demo ekranıyla gösteriliyor; şirket kuruluşu tamamlandığında gerçek ödeme altyapısı eklenecek.

## Teknolojiler

Flutter (mobil uygulama ve web paneli), Bloc, Supabase (PostgreSQL, Auth, Storage), Firebase Cloud Messaging.
