#!/bin/bash

# --- [[ HÀM HỖ TRỢ ]] ---
# Hàm (function) để cố gắng cài đặt một package
install_package() {
    local package_name="$1"
    echo "🔧 Đang thử cài đặt '$package_name'..."

    # Kiểm tra các trình quản lý gói phổ biến
    if command -v apt-get &> /dev/null; then
        echo "    (Sử dụng apt-get... bạn có thể cần nhập mật khẩu sudo)"
        sudo apt-get update >/dev/null
        sudo apt-get install -y "$package_name"
    elif command -v dnf &> /dev/null; then
        echo "    (Sử dụng dnf... bạn có thể cần nhập mật khẩu sudo)"
        sudo dnf install -y "$package_name"
    elif command -v pacman &> /dev/null; then
        echo "    (Sử dụng pacman... bạn có thể cần nhập mật khẩu sudo)"
        sudo pacman -S --noconfirm "$package_name"
    elif command -v brew &> /dev/null; then
        echo "    (Sử dụng Homebrew...)"
        brew install "$package_name"
    elif command -v yum &> /dev/null; then # Cho CentOS/RHEL cũ
        echo "    (Sử dụng yum... bạn có thể cần nhập mật khẩu sudo)"
        sudo yum install -y "$package_name"
    elif command -v apk &> /dev/null; then # Cho Alpine Linux
         echo "    (Sử dụng apk... bạn có thể cần nhập mật khẩu sudo)"
         sudo apk add "$package_name"
    else
        echo "❌ Không tìm thấy trình quản lý gói quen thuộc (apt, dnf, pacman, brew, yum, apk)."
        return 1 # Báo hiệu thất bại
    fi

    # Kiểm tra lại sau khi cài
    if ! command -v "$package_name" &> /dev/null; then
        echo "❌ Cài đặt '$package_name' không thành công."
        return 1
    else
        echo "✅ Đã cài đặt '$package_name' thành công!"
        return 0 # Báo hiệu thành công
    fi
}
# --- [[ KẾT THÚC HÀM ]] ---


# --- [[ KIỂM TRA CÔNG CỤ ]] ---
# 1. Kiểm tra curl
if ! command -v curl &> /dev/null; then
    echo "⚠️ 'curl' chưa được cài đặt."
    install_package "curl"
    if [ $? -ne 0 ]; then # Kiểm tra mã lỗi trả về từ hàm
        echo "😥 Không thể tiếp tục nếu không có 'curl'. Tạm biệt!"
        exit 1
    fi
fi

# 2. Kiểm tra pup
if ! command -v pup &> /dev/null; then
    echo "⚠️ 'pup' chưa được cài đặt."
    
    # Thử cài đặt 'pup' bằng trình quản lý gói
    install_package "pup"
    
    # Nếu thất bại, thử cài bằng 'go' (nếu 'go' đã được cài)
    if [ $? -ne 0 ]; then
        echo "    ...Thử phương án dự phòng: cài 'pup' bằng 'go' (nếu có)..."
        if command -v go &> /dev/null; then
            # Đảm bảo $HOME/go/bin có trong PATH
            export PATH=$PATH:$(go env GOPATH)/bin:$HOME/go/bin
            go install github.com/ericchiang/pup@latest
        else
            echo "    'go' cũng không được cài đặt."
        fi
    fi

    # Kiểm tra lần cuối cùng
    if ! command -v pup &> /dev/null; then
        echo "😥 Đã thử mọi cách nhưng vẫn không cài được 'pup'."
        echo "   Vui lòng cài 'pup' thủ công (ví dụ: 'go install github.com/ericchiang/pup@latest') rồi chạy lại."
        exit 1
    fi
fi

echo "✅ 'curl' và 'pup' đều đã sẵn sàng!"
# --- [[ KẾT THÚC KIỂM TRA ]] ---


# --- [[ BẮT ĐẦU SCRIPT CHÍNH ]] ---
OUTPUT_FILE="data.txt"
DOMAIN="https://truyenqqgo.com"
> "$OUTPUT_FILE" 

echo "♻️  Đã dọn dẹp và chuẩn bị file '$OUTPUT_FILE'"
TOTAL_PAGES=370 # Bạn có thể thay đổi số trang ở đây

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

    # Thêm -L để theo dõi chuyển hướng (redirects)
    links_found=$(curl -sL -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0" "$current_url" | pup "$SELECTOR attr{href}")

    if [ -n "$links_found" ]; then
    
        echo "$links_found" | while read -r relative_link; do
            # Đảm bảo link bắt đầu bằng /
            if [[ ! "$relative_link" == /* ]]; then
                relative_link="/$relative_link"
            fi
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
