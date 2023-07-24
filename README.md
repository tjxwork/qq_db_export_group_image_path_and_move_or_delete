# QQ数据库导出群图片路径并移动或者删除

在Windows平台下，读取解密解码后的QQ数据库，导出QQ群消息中的图片路径，将其按QQ群分类来进行移动（删除）

## 不算更新的更新：

7月24日，腾讯NT架构QQ那边有工作人员联系我想确认一下问题，沟通过程中发现。  
NT架构QQ 在 2023.07.21 更新的 v9.9.1，  
已经可以识别到旧的聊天记录图片了。  
也可以在新版本里面直接修改聊天记录的路径了。  

现在删除整个群的聊天记录的话，是可以把旧的群图片一起删除的，但是只删除群图片这个操作，说是得要问问产品做不做。  

在确认过程中，我还碰到NTQQ的两个Bug：  

 - 消息记录在按日期筛选的时候，部分消息缺失及出现非此日期的消息。  
 - 有少量的部分图片，在NTQQ消息记录中会显示为“图片已过期”，但是切回旧QQ的消息记录是能正常显示的。

暂时不清楚是不是个例问题。  

总结：**打算直接完全删除群聊天记录的，可以直接更新NTQQ 9.9.1来尝试了一下。**  

如果NTQQ那边愿意更新只删除群图片功能的话，那这个项目的使命很快就要结束了。  

![image](img/NTQQ_9.9.1_官方人员沟通.png)



## 图文教程：

[Python 加 PowerShell 删除指定 QQ 群的图片 - tjxblog](https://www.tjxblog.com/blog/2023-0009)



## 视频教程：

[删除指定QQ群的图片【tjxwork】 - bilibili](https://www.bilibili.com/video/BV1NM4y1s7tS/)

[删除指定QQ群的图片【tjxwork】 - YouTube](https://www.youtube.com/watch?v=lMe9MrxBN-c)



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
sqlite> .open Msg.db

检查是否出错
sqlite> .selftest

将数据库导出为 temp.sql 
sqlite> .output temp.sql
sqlite> .dump

需要修改 temp.sql 文件最后一行为 "COMMIT;" 后再操作

将 temp.sql 复制到新的数据库
sqlite> .open NewMsg.db
sqlite> .read temp.sql
sqlite> .quit
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
