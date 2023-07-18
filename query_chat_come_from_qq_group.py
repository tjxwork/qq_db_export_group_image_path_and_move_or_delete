# 
# Author: tjxwork tjxwork@outlook.com
# Date: 2023-07-08 19:51:09
# LastEditors: tjxwork tjxwork@outlook.com
# LastEditTime: 2023-07-08 21:05:00
# FilePath: \undefinedc:\Users\xin\Desktop\QQ\query_chat_come_from_qq_group.py
# Description: 
# 
# Copyright (c) 2023 by tjxwork, All Rights Reserved. 
# 

import sqlite3
import re

# QQ聊天记录数据库的路径
qq_msg3_db_path = "Msg.db"


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
qq_database_group_table_list = []
for row in qq_database_table_list:
    if re.search(regex_group_table, row[0]):
        qq_database_group_table_list.append(row[0])

print("获取到:", len(qq_database_group_table_list), "个 QQ 群")


# 定义出错的QQ群列表变量
error_qq_group_list = []


while True:
    # 要查询的聊天记录
    query_chat_text = input("\n输入 quit 退出，请输入聊天文本: ")


    # 判断是否退出循环
    if query_chat_text.lower() == "quit":
        break

    # 循环查询各个表里面的信息
    for table_name in qq_database_group_table_list:

        # 执行查询，获取表中包含图片标签的信息
        query = f"SELECT DecodedMsg FROM {table_name} WHERE DecodedMsg LIKE '%{query_chat_text}%'"
        #下面一行 cursor.execute(query) 可能出现报错
        try:
            cursor.execute(query)
        except Exception as e:
            print(f"{table_name}在执行查询时发生错误:", e)
            error_qq_group_list.append({table_name})
            continue  # 跳过本次循环，执行下一次迭代

        consistent_text = cursor.fetchall()

        if consistent_text :
            print( table_name, "\t找到了:\t", consistent_text, "信息")


# 关闭游标和数据库连接
cursor.close()
qq_database.close()

