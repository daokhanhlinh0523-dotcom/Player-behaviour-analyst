# Đánh giá thử thách qua từng màn

Phân tích độ khó, khả năng đi tiếp và tỷ lệ quay lại trong game puzzle. Repository chứa truy vấn MySQL 8.0+ và các script Python của dự án.

## Đọc mã nguồn

1. [Tài liệu SQL](sql/README.md): danh mục truy vấn và quy ước tính toán.
2. [Biểu đồ báo cáo](build_report_charts.py): tạo biểu đồ mức tiếp cận, độ khó, hành trình và so sánh nhóm dùng vật phẩm.
3. [Tiện ích dữ liệu](analysis_utils.py): đọc bảng CSV trong môi trường phân tích.
4. [Script thực thi](run_analysis.py): chạy notebook trong môi trường phân tích.

## Tóm tắt phân tích

1. **Bài toán:** tìm màn cần ưu tiên điều tra từ hành vi người chơi.
2. **Cách làm:** tính tỷ lệ không thắng, so với các màn gần đó và dùng IQR để tìm chênh lệch bất thường.
3. **Kiểm tra thêm:** đối chiếu khả năng đi tiếp, quay lại ngày sau và kết quả theo nhóm người chơi.
4. **Kết luận:** đề xuất nơi cần xem lại cấu hình và bản ghi lượt chơi.
