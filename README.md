# VKU Field Survey PWA

Ứng dụng **Progressive Web App (PWA) offline-first** để khảo sát/kiểm tra tình trạng
cơ sở vật chất trong khuôn viên VKU, xây dựng bằng **Flutter Web**.

> Mini-Project 1 — môn PWA/Mobile Web. Ứng dụng hoạt động đầy đủ kể cả khi
> **không có kết nối mạng**: dữ liệu được ghi trực tiếp vào **IndexedDB** của
> trình duyệt (thông qua Hive) và có thể đồng bộ sau khi có mạng trở lại.

---

## 1. Tính năng

- 📋 Tạo phiếu khảo sát: tên cơ sở vật chất, vị trí, tình trạng (Tốt / Cần sửa / Hư hỏng), ghi chú, ảnh đính kèm (tuỳ chọn).
- 📴 **Offline-first**: mọi thao tác lưu/xoá ghi thẳng vào `IndexedDB` (qua Hive box), không cần mạng.
- 🔄 Hàng chờ đồng bộ: các phiếu chưa đồng bộ được đánh dấu, có nút "Đồng bộ" khi thiết bị online trở lại.
- 📶 Hiển thị trạng thái online/offline theo thời gian thực (`connectivity_plus`).
- 📲 Cài đặt như app gốc (Add to Home Screen) nhờ Web App Manifest + Service Worker do Flutter tự sinh khi build.
- 🎨 Giao diện theo màu thương hiệu VKU (đỏ / xanh dương / vàng).

## 2. Kiến trúc & công nghệ

| Thành phần | Công nghệ |
|---|---|
| UI framework | Flutter Web (Material 3) |
| Lưu trữ offline | `hive` + `hive_flutter` (Flutter Web tự động dùng IndexedDB làm backend) |
| Cache tài nguyên / Service Worker | Sinh tự động bởi `flutter build web` |
| Ảnh đính kèm | `image_picker` (đọc file cục bộ, không cần mạng) |
| Trạng thái mạng | `connectivity_plus` |
| ID phiếu | `uuid` |

Cấu trúc thư mục:

```
lib/
  models/survey_entry.dart        # Model dữ liệu 1 phiếu khảo sát
  services/survey_repository.dart # CRUD + hàng chờ đồng bộ trên Hive/IndexedDB
  screens/home_screen.dart        # Danh sách phiếu + trạng thái mạng + đồng bộ
  screens/add_edit_survey_screen.dart # Form tạo phiếu mới
  widgets/survey_card.dart        # Card hiển thị 1 phiếu
  theme.dart                      # Theme màu VKU
  main.dart                       # Entry point
web/
  index.html, manifest.json, _redirects  # Cấu hình PWA + deploy SPA fallback
```

## 3. Yêu cầu môi trường

- [Flutter SDK](https://docs.flutter.dev/get-started/install) >= 3.22 (kênh `stable`), đã bật Web:
  ```bash
  flutter channel stable
  flutter upgrade
  flutter config --enable-web
  ```
- Trình duyệt Chrome (để chạy dev) hoặc bất kỳ trình duyệt hiện đại nào (để dùng bản build).

## 4. Chạy thử (development)

```bash
flutter pub get
flutter run -d chrome
```

## 5. Build bản production (PWA offline-first)

```bash
flutter build web --release --pwa-strategy=offline-first
```

Kết quả nằm trong `build/web/` — đây chính là thư mục cần deploy. Cờ
`--pwa-strategy=offline-first` yêu cầu service worker cache toàn bộ app-shell
ngay lần tải đầu tiên, giúp app mở lại được dù mất mạng hoàn toàn.

## 6. Triển khai (Deploy)

### Cách A — Cloudflare Pages
1. Push repo này lên GitHub (xem mục 7).
2. Trên Cloudflare Pages → **Create a project** → **Connect to Git** → chọn repo.
3. Cấu hình build:
   - **Build command**: `flutter build web --release --pwa-strategy=offline-first`
   - **Build output directory**: `build/web`
   - **Environment variable**: dùng image Cloudflare có sẵn Flutter, hoặc thêm bước cài Flutter trong build command (xem `vercel.json` để tham khảo cách clone Flutter SDK trong CI nếu image không có sẵn).
4. Deploy → Cloudflare cấp domain dạng `https://<project>.pages.dev` — đây chính là **link HTTPS thực tế** cần nộp.

### Cách B — Vercel
1. Import repo GitHub vào Vercel.
2. File `vercel.json` (đã có sẵn trong repo) tự cấu hình `buildCommand`, `outputDirectory`, và rewrite SPA.
3. Deploy → nhận domain dạng `https://<project>.vercel.app`.

> Lưu ý: `web/_redirects` đảm bảo mọi route đều trả về `index.html`
> (bắt buộc cho ứng dụng single-page như Flutter Web).

## 7. Đưa code lên GitHub (Public repo)

```bash
git init
git add .
git commit -m "VKU Field Survey PWA - Mini-Project 1"
git branch -M main
git remote add origin https://github.com/<your-username>/vku-field-survey-pwa.git
git push -u origin main
```

## 8. Kiểm thử offline thủ công

1. Mở app đã deploy (hoặc `flutter run -d chrome`).
2. Mở DevTools → tab **Network** → chọn **Offline**.
3. Tạo một phiếu khảo sát mới → phiếu vẫn được lưu và hiển thị trong danh sách (đọc/ghi từ IndexedDB, không qua mạng).
4. Tải lại trang khi vẫn offline → dữ liệu vẫn còn (persist qua Hive box).
5. Bật lại Network → bấm nút **Đồng bộ** trên AppBar → các phiếu chuyển trạng thái "Đã đồng bộ".

## 9. Hướng phát triển tiếp (Tuần sau)

Đóng gói bản build `build/web` này thành ứng dụng Android (`.apk`) bằng
**Capacitor Bridge**, cho phép cài đặt như app native trên điện thoại.

## 10. Giấy phép

Mini-project phục vụ mục đích học tập tại VKU.
