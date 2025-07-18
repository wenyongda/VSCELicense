# 加载 VSCELicense 模块
try {
    Import-Module -Name 'C:\VSCELicense\VSCELicense.psd1' -ErrorAction Stop
} catch {
    Write-Error "无法加载模块 'C:\VSCELicense\VSCELicense.psd1'，请确认路径是否正确。错误信息: $_"
    exit 1
}


# 获取许可证信息
try {
    $output = Get-VSCELicenseExpirationDate -ErrorAction Stop | Out-String
} catch {
    Write-Error "执行 Get-VSCELicenseExpirationDate 时出错: $_"
    exit 1
}

# 使用正则表达式提取版本号和过期日期
$version = $null
$expDateStr = $null

if ($output -match '(?m)^\s*(\d{4})\s+(\d{2}/\d{2}/\d{4}\s+\d{2}:\d{2}:\d{2})') {
    $version = $matches[1].Trim()
    $expDateStr = $matches[2].Trim()
    Write-Host "找到版本: $version"
    Write-Host "过期日期: $expDateStr"
} else {
    Write-Error "无法从输出中找到版本和过期日期"
    exit 1
}

# 将过期日期字符串解析为 DateTime 对象
try {
    $expirationDate = [datetime]::ParseExact($expDateStr, 'dd/MM/yyyy HH:mm:ss', $null)
} catch {
    Write-Error "日期格式解析失败: $expDateStr. 错误: $_"
    exit 1
}

# 获取当前时间并设置阈值
$currentTime = Get-Date
$threshold = $currentTime.AddDays(1)

Write-Host "当前时间: $currentTime"
Write-Host "过期时间: $expirationDate"
Write-Host "阈值时间（当前时间 + 1天）: $threshold"

# 判断是否在1天内过期
if ($expirationDate -le $threshold) {
    Write-Host "许可证即将过期，正在执行 Set-VSCELicenseExpirationDate 命令..."
    try {
        Set-VSCELicenseExpirationDate -Version $version -ErrorAction Stop
        Write-Host "Set-VSCELicenseExpirationDate 命令执行成功。"
    } catch {
        Write-Error "执行 Set-VSCELicenseExpirationDate 时出错: $_"
        exit 1
    }
} else {
    Write-Host "许可证未在一天内过期，无需操作。"
}