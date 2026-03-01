# Uzman (Expert) Tarafı – Backend Gereksinimleri

Bu dokümanda, uzman kayıt ve yönetim akışı için backend’de (Firebase / kendi sunucunuz) yapılması gerekenler listelenmiştir.

---

## 1. Firestore Koleksiyonları ve Şema

### 1.1 `users` koleksiyonu

Uzman kayıt sonrası aynı koleksiyonda, `role` ile ayrım yapılıyor.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `displayName` | string | Ad soyad |
| `email` | string | E-posta (küçük harf) |
| `phoneNumber` | string | Telefon (sadece rakam, 10 hane) |
| `role` | string | `"user"` veya `"expert"` – uzmanlar için `"expert"` |
| `createdAt` | Timestamp | Kayıt tarihi |
| `photoURL` | string? | (Opsiyonel) Profil fotoğrafı URL |

- **Document ID:** Firebase Auth `uid`
- **Index:** `email` ve `phoneNumber` üzerinden mükerrer kontrol yapılıyor; bu alanlarda sorgu kullanıyorsanız gerekli composite index’leri Firebase Console’dan ekleyin.

---

### 1.2 `expert_profiles` koleksiyonu

Her uzman için tek doküman; document ID = Auth `uid`.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `displayName` | string | Ad soyad |
| `email` | string | E-posta |
| `phoneNumber` | string | Telefon |
| `businessName` | string | İşletme adı |
| `serviceCategories` | array\<string\> | Hizmet kategorileri (örn. "Temizlik", "Tesisatçı") |
| `businessType` | string | `"sahis"` veya `"sirket"` |
| `taxNumber` | string | Vergi numarası (opsiyonel, boş olabilir) |
| `experienceYears` | number | Deneyim yılı |
| `expertiseAreas` | array\<string\> | Uzmanlık alanları |
| `educationLevel` | string | Eğitim düzeyi (örn. "Lisans", "Yüksek Lisans") |
| `schoolName` | string | Okul / kurum adı (opsiyonel) |
| `certificateURLs` | array\<string\> | Sertifika dosyalarının Storage URL’leri (şu an uygulama boş array yazıyor) |
| `status` | string | `"pending"` \| `"approved"` \| `"rejected"` – başvuru onay durumu |
| `createdAt` | Timestamp | Başvuru tarihi |

**Henüz uygulamada gönderilmeyen / backend’de eklenmesi gereken alanlar:**

| Alan | Tip | Açıklama |
|------|-----|----------|
| `idFrontURL` | string? | Kimlik ön yüz fotoğrafı Storage URL |
| `idBackURL` | string? | Kimlik arka yüz fotoğrafı Storage URL |
| `rejectionReason` | string? | Red nedeni (status = rejected ise) |
| `approvedAt` | Timestamp? | Onay tarihi |
| `rejectedAt` | Timestamp? | Red tarihi |

İleride eklenebilecek (çalışma detayları, banka, portföy):

- `serviceCities`, `workingHours`, `minPrice`, `maxPrice`, `serviceType`, `bankName`, `iban`, `accountHolderName`, `portfolioImageURLs` vb.

---

## 2. Firebase Storage Yapısı

Dosyaların tutulacağı path’ler örnek:

```
/expert_documents/{uid}/id_front.jpg      → Kimlik ön yüz
/expert_documents/{uid}/id_back.jpg       → Kimlik arka yüz
/expert_documents/{uid}/certificates/     → Sertifikalar (birden fazla dosya)
```

- **Kural:** Sadece ilgili kullanıcı (`uid`) kendi klasörüne yazabilmeli; okuma ise sadece backend/admin veya onay sonrası yetkili taraflara açılmalı.
- Dosya boyutu ve tipi (sadece resim/PDF) kısıtlaması Storage kurallarında veya Cloud Functions ile enforce edilmeli.

---

## 3. Firestore Güvenlik Kuralları (Rules)

- **users:**  
  - Okuma: Giriş yapmış kullanıcı kendi dokümanını okuyabilsin.  
  - Yazma: Sadece kendi dokümanına (uid eşleşmeli) yazabilsin; `role` alanı için istenirse sadece belirli koşullarda (örn. ilk oluşturma) izin verilebilir.
- **expert_profiles:**  
  - Okuma: Uzman kendi profilini okusun; onaylı uzmanlar listesi için `status == "approved"` ile sorgu yapan taraflara (örn. uygulama) okuma izni.  
  - Yazma: Sadece ilgili `uid` kendi profilini oluşturabilsin / güncelleyebilsin.  
  - `status`, `rejectionReason`, `approvedAt`, `rejectedAt` gibi alanların sadece admin/backend tarafından yazılması için ya bu alanları kullanıcı yazısından hariç tutun ya da Cloud Functions ile güncelleyin.

---

## 4. Backend / Cloud Functions İhtiyaçları

1. **Kimlik ve sertifika yükleme**  
   Uygulama şu an kimlik ön/arka fotoğraflarını ve sertifikaları sunucuya göndermiyor. İki seçenek:
   - **A)** İstemci doğrudan Storage’a (yukarıdaki path’lere) yüklesin; sonra `expert_profiles` dokümanına `idFrontURL`, `idBackURL`, `certificateURLs` yazılsın (istemci veya bir Cloud Function ile).
   - **B)** İstemci bir HTTP endpoint’e (Cloud Function veya kendi API’nize) base64/binary göndersin; backend Storage’a yükleyip URL’leri Firestore’a yazsın.

2. **Onay / red akışı**  
   - Admin panel veya backend’de uzman başvurusu listelenmeli.  
   - Onay: `expert_profiles/{uid}` içinde `status: "approved"`, `approvedAt: serverTimestamp()`.  
   - Red: `status: "rejected"`, `rejectionReason`, `rejectedAt`.  
   - İsteğe bağlı: Onay/red sonrası push veya e-posta bildirimi (FCM / e-posta servisi).

3. **Mükerrer kontrol**  
   Uygulama zaten `users` koleksiyonunda `email` ve `phoneNumber` ile sorgu yapıyor. Backend tarafında:
   - Aynı e-posta/telefon ile ikinci bir uzman hesabı açılmasın diye bu sorguların ve gerekirse unique constraint benzeri davranışın (ör. Cloud Function ile ek kontrol) tutarlı çalıştığından emin olun.

4. **Rol tabanlı erişim**  
   Uygulama `users` dokümanındaki `role` alanına bakarak uzman/kullanıcı ayrımı yapıyor. Backend’de:
   - Sadece `role === "expert"` olanlar için uzman paneline / uzman API’lerine izin verin.  
   - `expert_profiles.status === "approved"` olmayan uzmanların hizmet vermesini (ilan, randevu vb.) engelleyin.

---

## 5. Özet Checklist

- [ ] **Firestore:** `users` ve `expert_profiles` şemaları yukarıdaki gibi; `expert_profiles` için `idFrontURL`, `idBackURL` (ve istenirse `rejectionReason`, `approvedAt`, `rejectedAt`) alanları tanımlı.
- [ ] **Firestore Rules:** `users` ve `expert_profiles` için okuma/yazma kuralları role ve uid’e göre kısıtlanmış.
- [ ] **Storage:** `expert_documents/{uid}/...` path’leri ve kuralları tanımlı; kimlik + sertifika yükleme akışı (istemci veya backend) çalışıyor.
- [ ] **Uygulama tarafı:** Kimlik ön/arka ve sertifika görselleri Storage’a yüklenip URL’ler `expert_profiles`’a yazılıyor (şu an yazılmıyor).
- [ ] **Onay akışı:** Admin/backend’de başvuru listesi, onay/red ve isteğe bağlı bildirim hazır.
- [ ] **Rol ve onay kontrolü:** Sadece `role: "expert"` ve `status: "approved"` olanlar uzman işlemlerini yapabilsin.

Bu liste, uzman tarafı için backend’de gerekli olanları tek yerde toplar; Firebase Console, Storage Rules, Cloud Functions veya kendi API’nizi buna göre kurgulayabilirsiniz.
