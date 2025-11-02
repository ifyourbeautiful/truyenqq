#!/bin/bash

if ! command -v pup &> /dev/null || ! command -v curl &> /dev/null; then
    echo "⚠️ 'curl' hoặc 'pup' chưa được cài đặt."
    echo "   Hãy cài đặt chúng rồi mình tiếp tục nha! (♡ >ω< ♡)"
    exit 1
fi

OUTPUT_FILE="data.txt"
DOMAIN="https://truyenqqgo.com"
> "$OUTPUT_FILE" 

echo "♻️  Đã dọn dẹp và chuẩn bị file '$OUTPUT_FILE'"
TOTAL_PAGES=370

if ! [[ "$TOTAL_PAGES" =~ ^[0-9]+$ ]] || [ "$TOTAL_PAGES" -eq 0 ]; then
    echo "😥 Oops! Có vẻ như đây không phải là một con số hợp lệ."
    exit 1
fi

echo "🚀 Okay các sếp! Sẽ bắt đầu hành trình 'khám phá' $TOTAL_PAGES trang. Hẹ hẹ hẹ!"

SELECTOR='div.last_chapter > a[href]'

for (( page=1; page<=TOTAL_PAGES; page++ ))
do
    if [ "$page" -eq 1 ]; then
        current_url="${DOMAIN}/truyen-moi-cap-nhat/trang-1.html"
    else
        current_url="${DOMAIN}/truyen-moi-cap-nhat/trang-${page}.html"
    fi
    echo -e "\n🔎 Đang phân tích Trang $page tại: $current_url"

    links_found=$(curl -sL -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0" "$current_url" | pup "$SELECTOR attr{href}")

    if [ -n "$links_found" ]; then
    
        echo "$links_found" | while read -r relative_link; do
            echo "${DOMAIN}${relative_link}" >> "$OUTPUT_FILE"
        done

        count=$(echo "$links_found" | wc -l)
        echo "✅ Tìm thấy, xử lý và đã lưu $count link đầy đủ!"
    else
        echo "⚠️ Không tìm thấy link nào ở trang hiện tại."
    fi

    echo "💤 Tạm nghỉ 2 giây..."
    sleep 2
    echo "-------------------------------------------------------------------"
done

# --- [[ BÁO CÁO KẾT QUẢ ]] ---
total_links=$(cat "$OUTPUT_FILE" | wc -l)
echo -e "\n🎉 Hoàn thành xuất sắc nhiệm vụ!"
echo "✨ Toàn bộ $total_links 'viên ngọc' link đã được cất giữ an toàn trong file '$OUTPUT_FILE'."
