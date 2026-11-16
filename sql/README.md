# Truy vấn chuẩn bị dữ liệu

Các truy vấn sử dụng MySQL 8.0+ và các bảng `level_start`, `level_end`, `in_app_purchase` trong schema `game_data`. Notebook hiện đọc CSV và không thực thi SQL.

## Các truy vấn chính

| Bước | File | Ý chính |
|---|---|---|
| 1 | [analysis_scope.sql](checks/analysis_scope.sql) | Đếm người theo màn, rồi so sánh cỡ mẫu giữa hai phạm vi |
| 2 | [quality_summary.sql](checks/quality_summary.sql) | Kiểm tra khóa thiếu và khóa sự kiện lặp |
| 3 | [level_metrics.sql](metrics/level_metrics.sql) | Tổng hợp số lượt, số người và số người đi tiếp trong 24 giờ |
| 4 | [next_day_return.sql](metrics/next_day_return.sql) | Xác định lần đầu gặp màn và kiểm tra hoạt động vào ngày kế |

Các file khác mở rộng những bước này để kiểm tra trạng thái, item hoặc so sánh theo nền tảng và nhóm ngày tham gia.

`level_109_users.sql` ghép kết quả chơi, hoạt động ngày sau và giao dịch theo người để phân tích riêng màn 109.

## Tổng hợp chỉ số màn chơi

`WITH` đặt tên cho từng kết quả trung gian, còn gọi là CTE. Các CTE giúp chia truy vấn thành các bước có thể kiểm tra riêng:

1. `unique_start_events` và `unique_end_events`: loại dòng trùng trên các cột được chọn.
2. `level_starts` và `level_ends`: tính số lượt, số người và kết quả theo màn.
3. `ranked_win_times` và `win_times`: sắp xếp thời gian của lượt thắng để tính trung vị theo màn.
4. `first_starts`: thời điểm bắt đầu đầu tiên của từng người ở từng màn.
5. `level_transitions`: ghép người đó ở màn hiện tại và màn kế; đếm số người đi tiếp trong 24 giờ.
6. `SELECT` cuối: ghép các bảng đã có một dòng cho mỗi màn.

`LEFT JOIN` giữ cả người chưa có lần bắt đầu màn kế tiếp trong mẫu số. Chỉ người đủ 24 giờ quan sát được tính vào tỷ lệ đi tiếp, tránh coi người mới bắt đầu gần cuối dữ liệu là chưa đi tiếp.

`event_timestamp` được tính bằng microsecond; `86400000000` tương ứng 24 giờ. Chỉ số quay lại ngày kế dùng ngày lịch, còn đi tiếp và mua hàng dùng khoảng 24 giờ từ lần đầu bắt đầu màn.

Ngày tham gia được tính từ `user_first_touch_timestamp` theo UTC, cộng `time_zone_offset_seconds`, rồi lấy ngày. Phép cộng bắt đầu từ mốc `1970-01-01`, không phụ thuộc múi giờ của phiên kết nối.

## Hàm sử dụng

| Hàm | Ý nghĩa trong bài |
|---|---|
| `COUNT(*)` | Đếm số dòng trong nhóm |
| `COUNT(DISTINCT x)` | Đếm số giá trị khác nhau, không tính NULL |
| `COUNT(CASE WHEN ... THEN 1 END)` | Đếm các dòng thỏa điều kiện |
| `AVG(CASE WHEN ... THEN x END)` | Trung bình trên các dòng thỏa điều kiện |
| `CASE WHEN ... THEN 1 ELSE 0 END` | Tạo cờ điều kiện 0/1 |
| `COALESCE(x, 0)` | Thay NULL bằng 0 |
| `NULLIF(x, 0)` | Trả về NULL khi mẫu số bằng 0 |
| `ROW_NUMBER() OVER (...)` | Đánh số thứ tự trong mỗi nhóm |
| `COUNT(*) OVER (...)` | Đếm số dòng trong nhóm, giữ lại từng dòng |
| `DATE_ADD(..., INTERVAL 1 DAY)` | Lấy ngày kế tiếp |

## Cách tính trung vị

Giá trị thiếu được loại khỏi phép tính. Với `n` giá trị đã sắp xếp, lấy trung bình các vị trí `FLOOR((n + 1) / 2)` và `FLOOR((n + 2) / 2)`. Khi `n` lẻ, hai vị trí trùng nhau; khi `n` chẵn, lấy hai giá trị ở giữa. Nhóm không có giá trị hợp lệ trả về NULL.

Các truy vấn quay lại theo nhóm dùng `ROW_NUMBER()` để lấy thông tin tại thời điểm đầu tiên có giá trị nhóm hợp lệ. Nếu trùng thời điểm, sắp tiếp theo giá trị nhóm để kết quả nhất quán.

## Quy ước tính toán

- `DISTINCT` loại dòng trùng trên **toàn bộ các cột được chọn**, không mặc nhiên xác định được một lượt chơi duy nhất.
- Số lượt kết thúc khác số người chơi. Tỷ lệ thắng lần đầu chỉ dùng các lượt có `attempt = 1` làm mẫu số.
- Quay lại ngày kế sau lần đầu gặp màn khác D1 tính từ ngày cài đặt; ngày kế cũng khác một cửa sổ 24 giờ liên tục.
- Trước khi ghép, xác định mỗi bảng có bao nhiêu dòng cho một khóa để tránh nhân số dòng.
- Ở màn 109, điều kiện giao dịch trong 24 giờ nằm trong `ON` để giữ cả người không có giao dịch.

Hai file `platform_win_rate.sql` và `cohort_win_rate.sql` mặc định đối chiếu màn 107, 109 và 144. Thay danh sách trong `IN (...)` để xem các màn khác.

Tham khảo cú pháp: [hàm cửa sổ](https://dev.mysql.com/doc/refman/8.0/en/window-functions-usage.html) và [hàm ngày giờ](https://dev.mysql.com/doc/refman/8.0/en/date-and-time-functions.html) trong tài liệu MySQL.
