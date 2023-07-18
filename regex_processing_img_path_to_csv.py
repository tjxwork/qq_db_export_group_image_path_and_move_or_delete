# 
# Author: tjxwork tjxwork@outlook.com
# Date: 2023-07-08 12:03:09
# LastEditors: tjxwork tjxwork@outlook.com
# LastEditTime: 2023-07-08 19:59:37
# FilePath: \undefinedc:\Users\xin\Desktop\QQ\regex_processing_img_path_to_csv.py
# Description: 
# 
# Copyright (c) 2023 by tjxwork, All Rights Reserved. 
# 

import os
import sqlite3
import re
import csv
import numpy

# QQ聊天记录数据库的路径
qq_msg3_db_path = "Msg.db"

# QQ聊天记录相关csv的存放路径
csv_folder_path = "QQ_Group_CSV"
os.makedirs(csv_folder_path, exist_ok=True)

# 连接到 QQ 聊天记录数据库的 SQLite 数据库
qq_database = sqlite3.connect(qq_msg3_db_path)

# 创建游标对象
cursor = qq_database.cursor()

# 执行查询，获取 qq_database 所有的表
query = "SELECT name FROM sqlite_master WHERE type = 'table'"
cursor.execute(query)
qq_database_table_list = cursor.fetchall()


# 使用正则表达式进行过滤，获取符合 QQ 群聊天记录的表
regex_group_table = r"^group_[0-9]{5,}$"
qq_database_group_table_list = [row[0] for row in qq_database_table_list if re.search(regex_group_table, row[0])]
print("获取到:", len(qq_database_group_table_list), "个 QQ 群")


# 符合 QQ 群聊天记录的表写入对应的 CSV 文件
with open(f'{csv_folder_path}/qq_database_group_table_list.csv', 'w', newline='') as file:
    writer = csv.writer(file)
    for group_table in qq_database_group_table_list:
        writer.writerow([group_table])

# 定义出错的QQ群列表变量
error_qq_group_list = []

# 循环查询各个表里面有图片标签的信息
for table_name in qq_database_group_table_list:

    # 执行查询，获取表中包含图片标签的信息
    query = f"SELECT DecodedMsg FROM {table_name} WHERE DecodedMsg LIKE '%[t:img,path=UserDataImage:%'"
    #下面一行 cursor.execute(query) 可能出现报错
    try:
        cursor.execute(query)
    except Exception as e:
        print(f"{table_name}在执行查询时发生错误:", e)
        error_qq_group_list.append({table_name})
        continue  # 跳过本次循环，执行下一次迭代

    img_msg_list = cursor.fetchall()
    print( {table_name}, "\t获取到:\t", len(img_msg_list), "条图片信息")


    # 循环处理所有包含图片标签的信息
    img_path_list = []
    for img_msg in img_msg_list:
        # 使用正则表达式提取包含图片标签的信息中的路径
        regex_img_path = r"\[t:img,path=UserDataImage:(.*?),hash=.*?\]"

        try:
            img_path = re.findall(regex_img_path, img_msg[0])
        except Exception as e:
            print(f"{img_msg}在执行查询时发生错误:", e)
            error_qq_group_list.append({img_msg})
        
        img_path_list.extend(img_path)
    print({table_name}, "\t处理了:\t", len(img_path_list), "条图片信息")


    # 处理后的图片路径数据去重
    img_path_list = numpy.unique(img_path_list)
    print({table_name}, "\t去重后:\t", len(img_path_list), "条图片信息\n")


    # 将提取的图片路径写入对应的 CSV 文件
    with open(f'{csv_folder_path}/{table_name}.csv', 'w', newline='') as file:
        writer = csv.writer(file)
        for img_path in img_path_list:
            writer.writerow([img_path])


# 将出错群的信息写入 CSV 文件
with open(f'{csv_folder_path}/error_qq_group_list.csv', 'w', newline='') as file:
    writer = csv.writer(file)
    for error_qq_group in error_qq_group_list:
        writer.writerow([error_qq_group])


# 关闭游标和数据库连接
cursor.close()
qq_database.close()

