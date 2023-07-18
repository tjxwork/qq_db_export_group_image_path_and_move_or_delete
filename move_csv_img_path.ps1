# 
# Author: tjxwork tjxwork@outlook.com
# Date: 2023-07-09 11:24:23
# LastEditors: tjxwork tjxwork@outlook.com
# LastEditTime: 2023-07-18 10:56:22
# FilePath: \qq_db_export_group_image_path_and_move_or_delete\move_csv_img_path.ps1
# Description: 
# 
# Copyright (c) 2023 by tjxwork, All Rights Reserved. 
# 

# 没有权限运行脚本的，请管理员权限打开PowerShell运行： Set-ExecutionPolicy -ExecutionPolicy RemoteSigned

# QQ聊天记录路径
$qq_chats_path = "D:\Chats\Tencent Files\303xxx445"

# 存放移动后的QQ群的图片的指定目录，例如：$qq_chats_path\Image_Group_Move_Img
$qq_group_move_img_folder_path = "$qq_chats_path\Image_Group_Move_Img"

# 数据库导出的QQ群的图片路径csv文件夹
$qq_group_csv_folder_path = "C:\Users\xin\Desktop\QQ\QQ_Group_CSV"

# 避免操作此时间线后的图片
$time_line = Get-Date "2023-07-08 12:00:00"

# 黑名单运行模式？ $ture：黑名单，$False：白名单
$blacklist_operation_mode = $False

# 注意！ QQ群的名字，和数据库里面的群表名，两者的名字不一定是一样的。
# 请配合 query_chat_come_from_qq_group.py 查询聊天记录来确定在数据库的表名，复制到以下对应列表

# qq群 移动图片 黑名单
$qq_group_blacklist = @("group_552xxx835")

# qq群 移动图片 白名单
$qq_group_whitelist = @("group_206xxx7139", "group_777xxx650", "group_609xxx153", "group_806xxx657")

# 只处理修改时间在时间线之前、聊天记录文件夹的 Image 下面的 Group Group2 这两个文件夹的图片

# 白名单模式效果：
# 保留白名单内的群聊天图片；
# 其他已知的群图片，按群归类，保留文件夹结构移动到别的地方；
# 没有对应csv记录的群图片，移动到 group_unknown 文件夹

# 黑名单模式效果：
# 黑名单内的群，按群归类，保留文件夹结构移动到别的地方；
# 其余所有图片文件保持在原地不动。

# 由于不同QQ群是有可能使用同一张图片，特别是表情包。
# 所以实际的处理流程是：

# 先把 聊天记录文件夹的 Image 下面的 Group Group2 两个文件夹，移动到聊天记录文件夹内的 Image_Group_Temp 临时文件夹内
# 将修改时间在时间线之后的图片文件，移动回原来的位置

# 黑名单分支流程：
# 把 非黑名单 的csv对应的图片 从 Image_Group_Temp 移动回原来的位置
# 把 黑名单 csv对应的图片，从 Image_Group_Temp 移动到指定目录下（例如：Image_Group_Move_Img）对应的群文件夹（group_xxxxxx）
# 然后把剩下的图片再全部移动回原来的位置

# 白名单流程：
# 然后把 白名单 csv对应的图片，从 Image_Group_Temp 移动回原来的位置
# 然后把 非白名单 有csv对应的图片，从 Image_Group_Temp 移动到指定目录下（例如：Image_Group_Move_Img）对应的群文件夹（group_xxxxxx）
# 再剩下的图片，移动到指定目录下的 group_unknown 文件夹

# 按文件路径列表来移动文件的函数
function Move-FilePathList {
    <#
    .SYNOPSIS
    提供 源文件夹路径 和 目标文件夹路径 按 文件列表 来移动文件
    
    .DESCRIPTION
    有两种输入模式
    提供 源文件夹路径，目标文件路径，文件列表 参数的情况下。
    会以 文件列表 与 源文件夹路径 拼接文件路径，将对应的文件保持文件夹结构，移动到 目标文件路径 下

    只提供 源文件夹路径，目标文件路径 参数的情况下。
    会以 源文件夹路径 获取路径下的所有文件，将文件保持文件夹结构，移动到 目标文件路径 下
    提供 时间线 参数的情况下，获取 源文件夹路径 下的所有文件时，会筛选 时间线 之后的文件

    提供 日志名称 参数时，会在 源文件夹路径 下，以csv格式保存追加生成移动操作的记录日志。

    .PARAMETER SourceFolderPath
    源文件夹路径，必须，字符串路径形式。
    
    .PARAMETER DestinationFolderPath
    目标文件夹路径，必须，字符串路径形式。

    .PARAMETER FileList
    文件列表，非必须，字符串路径列表形式。

    .PARAMETER Timeline
    时间线，非必须，时间变量形式。

    .PARAMETER Timeline
    日志名称，非必须，字符串路径形式。

    .EXAMPLE
    Move-FileList -SourceFolderPath "D:\A" -DestinationFolderPath "D:\B" -FileList @("A1\A11\1.txt","A2\A22\2.txt")
    # D:\B\A1\A11\1.txt
    # D:\B\A2\A22\2.txt
    #>
    param (
        [Parameter(Mandatory = $true)]
        $SourceFolderPath,
        [Parameter(Mandatory = $true)]
        $DestinationFolderPath,
        $FilePathList,
        $Timeline,
        $LogName
    )

    # 日志的辅助函数
    function Write-MoveOperationLog {
        param (
            [Parameter(Mandatory = $true)]
            [string] $LogName,
    
            [Parameter(Mandatory = $true)]
            [string] $FilePath,
    
            [Parameter(Mandatory = $true)]
            [string] $SourceFilePath,
    
            [Parameter(Mandatory = $true)]
            [string] $DestinationFilePath,

            [string] $StatusMessage
        )
    
        $LogTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss:fff"
        $LogInfo = "$LogTime,$FilePath,$SourceFilePath,$DestinationFilePath,$StatusMessage"
        $LogInfo | Out-File -FilePath "$SourceFolderPath\log_$LogName.csv" -Encoding utf8 -Append
    }

    # 创建父文件夹，移动文件，输出日志的辅助函数
    function Move-ParentFolderMoveLog {
        param (
            [Parameter(Mandatory = $true)]
            $SourceFilePath,
            [Parameter(Mandatory = $true)]
            $DestinationFilePath,
            [Parameter(Mandatory = $true)]
            $FilePath
        )
        # 目标文件路径对应的父级文件夹路径
        $ParentFolder = Split-Path -Path $DestinationFilePath -Parent
    
        # 如果目标文件路径对应的父级文件夹不存在便新建
        if (-not (Test-Path -LiteralPath $ParentFolder)) {
            New-Item -ItemType Directory -Path $ParentFolder | Out-Null
        }

        # 移动文件
        try {
            # 要测试的话，在下面这行命令后面加上 -WhatIf
            Move-Item -LiteralPath $SourceFilePath -Destination $DestinationFilePath -ErrorAction Stop
            $StatusMessage = "成功移动"
        }
        catch {
            $StatusMessage = $_.Exception.Message
            Write-Warning $StatusMessage
        }

        if ( $LogName ) {
            # 日志记录
            Write-MoveOperationLog -LogName $LogName -FilePath $FilePath -SourceFilePath $SourceFilePath -DestinationFilePath $DestinationFilePath -StatusMessage $StatusMessage
        }
    }

    # 主体函数开始

    # 有传入 文件列表 的
    if ( $FilePathList ) {
        foreach ( $FilePath in $FilePathList) {

            # 源文件路径
            $SourceFilePath = Join-Path -Path $SourceFolderPath -ChildPath $FilePath
    
            # 目标文件路径
            $DestinationFilePath = Join-Path -Path $DestinationFolderPath -ChildPath $FilePath
    
            # 创建目标文件路径对应的父级文件夹，移动文件，生成日志
            Move-ParentFolderMoveLog -SourceFilePath $SourceFilePath -DestinationFilePath $DestinationFilePath -FilePath $FilePath
        }
    }

    # 没传入 文件列表 的
    if ( -not $FilePathList) {

        if ($Timeline) {
            $SourceFileList = Get-ChildItem -Path $SourceFolderPath -Recurse | Where-Object { $_.LastWriteTime -gt $Timeline -and -not $_.PSIsContainer -and $_.Name -notlike "log_*.csv" } 
        }
        else {
            $SourceFileList = Get-ChildItem -Path $SourceFolderPath -Recurse | Where-Object { -not $_.PSIsContainer -and $_.Name -notlike "log_*.csv" }
        }

        foreach ( $SourceFile in $SourceFileList) {
            # 源文件路径
            $SourceFilePath = $SourceFile.FullName

            # 目标文件路径
            $FilePath = $SourceFilePath.Replace( $SourceFolderPath , "")
            $DestinationFilePath = Join-Path -Path $DestinationFolderPath -ChildPath $FilePath

            # 创建目标文件路径对应的父级文件夹，移动文件，生成日志
            Move-ParentFolderMoveLog -SourceFilePath $SourceFilePath -DestinationFilePath $DestinationFilePath -FilePath $FilePath
        }
    }

}

# 预处理黑白名单列表，去空格
# $prefix = "group_" 本来是打算直接看群号来填的，会帮加前缀，但是发现数据库和群号不一定对应之后，反正都要查询复制了，还不如直接复制了，不补了。
$qq_group_blacklist = $qq_group_blacklist | ForEach-Object { $_.Trim() }
$qq_group_whitelist = $qq_group_whitelist | ForEach-Object { $_.Trim() }

# qq_group_alllist 所有文件名单，使用 Get-ChildItem 获取，符合群名格式的，去掉csv后缀
$qq_group_alllist = Get-ChildItem -Path $qq_group_csv_folder_path | Where-Object { $_.BaseName -like "group_*" } 
$qq_group_alllist = $qq_group_alllist | ForEach-Object { $_.ToString().Split('.')[0] }

if (-not $qq_group_alllist) {
    Write-Host "获取不到所有csv文件名单，终止脚本"
    exit
}

if ( -not (Test-Path -Path "$qq_chats_path\Image\Group") ) {
    Write-Host "获取不到 $qq_chats_path\Image\Group 文件夹"
    Write-Host "尝试在移动后的路径查找……"    
    if ( -not (Test-Path -Path "$qq_chats_path\Image_Group_Temp\Group") ) {
        Write-Host "获取不到 $qq_chats_path\Image_Group_Temp\Group 文件夹"
        Write-Host "终止脚本 "
        exit
    }
    Write-Host "已在移动后的路径中 $qq_chats_path\Image_Group_Temp\ 找到 Group 文件夹" 
}

# 非黑名单列表
$qq_group_not_blacklist = (Compare-Object $qq_group_alllist $qq_group_blacklist).InputObject 

# 非白名单列表
$qq_group_not_whitelist = (Compare-Object $qq_group_alllist $qq_group_whitelist).InputObject


Write-Host "`n导出QQ群数量为：$($qq_group_alllist.Count)`n"


if ($blacklist_operation_mode) {
    Write-Host "当前运行模式为：黑名单`n" 
    Write-Host "  黑名单数量为：$($qq_group_blacklist.Count)"
    Write-Host "  黑名单列表为：$qq_group_blacklist`n"
    Write-Host "非黑名单数量为：$($qq_group_not_blacklist.Count)"
    Write-Host "非黑名单列表为：$qq_group_not_blacklist`n"
}
else {
    Write-Host "当前运行模式为：白名单`n" 
    Write-Host "  白名单数量为：$($qq_group_whitelist.Count)"
    Write-Host "  白名单列表为：$qq_group_whitelist`n"
    Write-Host "非白名单数量为：$($qq_group_not_whitelist.Count)"
    Write-Host "非白名单列表为：$qq_group_not_whitelist`n"
}

Write-Host "所有的移动操作将会在 $qq_chats_path\Image_Group_Temp\ 下生成日志"
Write-Host "开始后会结束QQ的进程`n"

Write-Host "按下回车键开始，关闭窗口结束"
Read-Host
Write-Host "`n"


# 开始时间
$start_time = Get-Date

# 结束 QQ 进程
Stop-Process -Name "QQ" | Out-Null

Write-Host "存储群图片的 Group、Group2 文件夹"
Write-Host "从 $qq_chats_path\Image\ 移动"
Write-Host "到 $qq_chats_path\Image_Group_Temp\`n"
# 先把 聊天记录文件夹的 Image 下面的 Group、Group2 直接移动到，聊天记录文件夹内的 Image_Group_Temp 临时文件夹内；
# 如果 Image_Group_Temp 文件夹不存在便新建
if (!(Test-Path -LiteralPath "$qq_chats_path\Image_Group_Temp\")) {
    New-Item -ItemType Directory -Path "$qq_chats_path\Image_Group_Temp\"
}
Move-Item -Path "$qq_chats_path\Image\Group" -Destination "$qq_chats_path\Image_Group_Temp\"
Move-Item -Path "$qq_chats_path\Image\Group2" -Destination "$qq_chats_path\Image_Group_Temp\"


Write-Host "文件修改时间在 $($time_line.ToString("yyyy-MM-dd HH:mm:ss")) 之后的图片"
Write-Host "从 $qq_chats_path\Image_Group_Temp\ 移动"
Write-Host "到 $qq_chats_path\Image\ `n"
# 将修改时间在时间线之后的图片文件，移动回原来的位置； 获取 起始路径，Image_Group_Temp 文件夹下，在时间线之后的所有文件
Move-FilePathList -SourceFolderPath "$qq_chats_path\Image_Group_Temp\" -DestinationFolderPath "$qq_chats_path\Image\" -Timeline $time_line -LogName "timeline_after_file"


# 判断黑白名单模式
if ( $blacklist_operation_mode ) {

    Write-Host "非黑名单csv对应的图片"
    Write-Host "从 $qq_chats_path\Image_Group_Temp\ 移动回"
    Write-Host "到 $qq_chats_path\Image\ `n"

    # 循环读取 非黑名单列表 中的csv文件 
    foreach ($not_blacklist_file in $qq_group_not_blacklist) {

        $not_blacklist_file_data = (Import-Csv -Path "$qq_group_csv_folder_path\$not_blacklist_file.csv" -Header "Path").Path

        Write-Host "开始移动，非黑名单，$not_blacklist_file"

        if ( $null -eq $not_blacklist_file_data ) {
            Write-Host "$not_blacklist_file 空白，跳过"
            continue
        }

        # 把 非黑名单 的csv对应的图片 从 Image_Group_Temp 移动回原来的位置
        Move-FilePathList -SourceFolderPath "$qq_chats_path\Image_Group_Temp\" -DestinationFolderPath "$qq_chats_path\Image\" -FilePathList $not_blacklist_file_data  -LogName "not_blacklist_$not_blacklist_file"
    }


    Write-Host "`n黑名单csv对应的图片"
    Write-Host "从 $qq_chats_path\Image_Group_Temp\ 移动"
    Write-Host "到 $qq_group_move_img_folder_path\ 下对应的群文件夹`n"

    # 循环读取 黑名单列表 中的csv文件
    foreach ($blacklist_file in $qq_group_blacklist) {

        $blacklist_file_data = (Import-Csv -Path "$qq_group_csv_folder_path\$blacklist_file.csv" -Header "Path").Path

        Write-Host "开始移动，黑名单，$blacklist_file"

        if ( $null -eq $blacklist_file_data ) {
            Write-Host "$blacklist_file 空白，跳过"
            continue
        }

        # 把 黑名单csv对应的图片，从 Image_Group_Temp 移动到，指定目录下（例如：Image_Group_Move_Img）对应的群文件夹（group_xxxxxx）
        Move-FilePathList -SourceFolderPath "$qq_chats_path\Image_Group_Temp\" -DestinationFolderPath "$qq_group_move_img_folder_path\$blacklist_file\" -FilePathList $blacklist_file_data  -LogName "blacklist_$blacklist_file"
    }


    Write-Host "`n剩下的图片"
    Write-Host "从 $qq_chats_path\Image_Group_Temp\ 移动回"
    Write-Host "到 $qq_chats_path\Image\`n"

    # 剩下的图片，移动回原来的位置 
    Move-FilePathList -SourceFolderPath "$qq_chats_path\Image_Group_Temp\" -DestinationFolderPath "$qq_chats_path\Image\" -LogName "blacklist_mode_remain_img_go_back_image"


}
else {

    Write-Host "白名单csv对应的图片"
    Write-Host "从 $qq_chats_path\Image_Group_Temp\ 移动回"
    Write-Host "到 $qq_chats_path\Image\`n"

    # 循环读取 白名单列表 中的csv文件 
    foreach ($whitelist_file in $qq_group_whitelist) {

        $whitelist_file_data = (Import-Csv -Path "$qq_group_csv_folder_path\$whitelist_file.csv" -Header "Path").Path

        Write-Host "开始操作，白名单，$whitelist_file"

        if ( $null -eq $whitelist_file_data ) {
            Write-Host "$whitelist_file 空白，跳过"
            continue
        }

        # 把 白名单csv对应的图片 移动回原来的位置
        Move-FilePathList -SourceFolderPath "$qq_chats_path\Image_Group_Temp\" -DestinationFolderPath "$qq_chats_path\Image\" -FilePathList $whitelist_file_data  -LogName "whitelist_$whitelist_file"
    }

    Write-Host "`n非白名单csv对应的图片"
    Write-Host "从 $qq_chats_path\Image_Group_Temp\ 移动"
    Write-Host "到 $qq_group_move_img_folder_path\ 下对应的群文件夹下`n"

    # 循环读取 非白名单列表 中的csv文件
    foreach ($not_whitelist_file in $qq_group_not_whitelist) {

        $not_whitelist_file_data = (Import-Csv -Path "$qq_group_csv_folder_path\$not_whitelist_file.csv" -Header "Path").Path

        Write-Host "开始操作，非白名单，$not_whitelist_file"

        if ( $null -eq $not_whitelist_file_data ) {
            Write-Host "$not_whitelist_file 空白，跳过"
            continue
        }

        # 把 非白名单csv对应的图片 从 Image_Group_Temp 移动到，指定目录下（例如：Image_Group_Move_Img）对应的群文件夹（group_xxxxxx）
        Move-FilePathList -SourceFolderPath "$qq_chats_path\Image_Group_Temp\" -DestinationFolderPath "$qq_group_move_img_folder_path\$not_whitelist_file\" -FilePathList $not_whitelist_file_data  -LogName "not_whitelist_$not_whitelist_file"
    }


    Write-Host "`n剩下的图片"
    Write-Host "从 $qq_chats_path\Image_Group_Temp\ 移动"
    Write-Host "到 $qq_group_move_img_folder_path\group_unknown 下`n"

    # 剩下的图片，移动到指定目录下的 group_unknown 文件夹
    Move-FilePathList -SourceFolderPath "$qq_chats_path\Image_Group_Temp\" -DestinationFolderPath "$qq_group_move_img_folder_path\group_unknown\" -LogName "whitelist_mode_img_to_group_unknown"

}


# 结束时间
$end_time = Get-Date

# 输出运行时间
$execution_time = $end_time - $start_time
Write-Host "累计用时：$execution_time `n"