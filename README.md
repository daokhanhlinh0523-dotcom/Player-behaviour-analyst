# Đánh giá thử thách qua từng màn

Phân tích độ khó, khả năng đi tiếp và tỷ lệ quay lại trong game puzzle bằng Python và MySQL 8.0+.

## Đọc bài

1. [Báo cáo PDF](output/pdf/Puzzle_Level_Analysis_Report.pdf): kết quả và hướng điều tra.
2. [Notebook phân tích](puzzle_analysis.ipynb): công thức, bảng đối chiếu và biểu đồ.
3. [Truy vấn SQL](sql/): kiểm tra và tổng hợp dữ liệu.
4. [Biểu đồ báo cáo](build_report_charts.py): script tạo các hình trong báo cáo.

## Tóm tắt phân tích

1. **Bài toán:** tìm màn cần ưu tiên điều tra từ hành vi người chơi.
2. **Cách làm:** tính tỷ lệ không thắng, so với các màn gần đó và dùng IQR để tìm chênh lệch bất thường.
3. **Kiểm tra thêm:** đối chiếu khả năng đi tiếp, quay lại ngày sau và kết quả theo nhóm người chơi.
4. **Kết luận:** đề xuất nơi cần xem lại cấu hình và bản ghi lượt chơi.
