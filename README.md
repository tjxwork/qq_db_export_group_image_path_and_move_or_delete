<!--
 * @Author: tjxwork tjxwork@outlook.com
 * @Date: 2023-07-18 10:39:13
 * @LastEditors: tjxwork tjxwork@outlook.com
 * @LastEditTime: 2023-07-18 11:34:07
 * @FilePath: \qq_db_export_group_image_path_and_move_or_delete\README.md
 * @Description: 
 * 
 * Copyright (c) 2023 by tjxwork, All Rights Reserved. 
-->
# QQ数据库导出群图片路径并移动或者删除
在Windows平台下，读取解密解码后的QQ数据库，导出QQ群消息中的图片路径，将其按QQ群分类来进行移动（删除）

## 前置项目：  

https://github.com/Young-Lord/qq-win-db-key  
先用 qq-win-db-key 来解密QQ数据库  

https://github.com/saucer-man/qq_msg_decode  
然后 qq_msg_decode 来解码QQ数据库  


## 建议操作：  
建议先使用 sqlite-tools-win32-x86 来修复数据库再进行下一步操作。  
损坏机率应该挺高的，官方案例：[微信 SQLite 数据库修复实践](https://cloud.tencent.com/developer/article/2256739)  

下载地址：https://www.sqlite.org/download.html  
检查与修复命令：  

```
打开数据库文件
sqlite3> .open Msg.db

检查是否出错
sqlite3> .selftest

将数据库导出为 temp.sql 
sqlite3> .output temp.sql
sqlite3> .dump

需要修改 temp.sql 文件最后一行为 "COMMIT;" 后再操作

将 temp.sql 复制到新的数据库
sqlite3> .open NewMsg.db
sqlite3> .read temp.sql
sqlite3> .quit
```

## 脚本作用：
- [modify_temp_sql_last_line.py](https://github.com/tjxwork/qq_db_export_group_image_path_and_move_or_delete/blob/main/modify_temp_sql_last_line.py)  
    用于：修改sqlite tools导出 .sql 文件的最后一行为 "COMMIT;"  
- [regex_processing_img_path_to_csv.py](https://github.com/tjxwork/qq_db_export_group_image_path_and_move_or_delete/blob/main/regex_processing_img_path_to_csv.py)  
    用于：读取QQ数据库，导出QQ群中的图片数据为csv文件。  
- [query_chat_come_from_qq_group.py](https://github.com/tjxwork/qq_db_export_group_image_path_and_move_or_delete/blob/main/query_chat_come_from_qq_group.py)  
    用于：根据QQ群的消息记录，来查询此QQ群对应的在QQ数据库中的表名。  
- [move_csv_img_path.ps1](https://github.com/tjxwork/qq_db_export_group_image_path_and_move_or_delete/blob/main/move_csv_img_path.ps1)  
    用于：按指定的群来移动特定QQ群的图片到指定路径下。  
