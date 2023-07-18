import os

def modify_last_line(file_path, new_line):
    # 获取文件大小
    file_size = os.path.getsize(file_path)

    # 打开文件以二进制模式进行读写
    with open(file_path, 'r+b') as file:
        # 定位到倒数第二个字节
        file.seek(-2, os.SEEK_END)
        
        # 循环向前搜索换行符位置
        while file.read(1) != b'\n':
            file.seek(-2, os.SEEK_CUR)

        # 获取当前位置
        current_pos = file.tell()
        
        # 将文件截断至当前位置
        file.truncate(current_pos)
        
        # 在最后一行末尾写入新内容
        file.write(new_line.encode())

# 调用示例
file_path = './temp.sql'
new_line = 'COMMIT;'
modify_last_line(file_path, new_line)