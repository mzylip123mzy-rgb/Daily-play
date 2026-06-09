param(
  [datetime]$Date = (Get-Date).Date,
  [string]$OutPath = ''
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

if (-not $OutPath) {
  $root = Split-Path -Parent $PSScriptRoot
  $OutPath = Join-Path $root 'outputs'
  $OutPath = Join-Path $OutPath ('{0:yyyy-MM-dd}-daily-plan-cute.png' -f $Date)
}
$outDir = Split-Path -Parent $OutPath
if ($outDir -and -not (Test-Path -LiteralPath $outDir)) {
  New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

function New-Brush($color) {
  [System.Drawing.SolidBrush]::new($color)
}

function New-Color($r, $g, $b) {
  [System.Drawing.Color]::FromArgb($r, $g, $b)
}

function Draw-RoundRect($g, $rect, $radius, $fill, $stroke) {
  $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $d = $radius * 2
  $path.AddArc($rect.X, $rect.Y, $d, $d, 180, 90)
  $path.AddArc($rect.Right - $d, $rect.Y, $d, $d, 270, 90)
  $path.AddArc($rect.Right - $d, $rect.Bottom - $d, $d, $d, 0, 90)
  $path.AddArc($rect.X, $rect.Bottom - $d, $d, $d, 90, 90)
  $path.CloseFigure()
  $g.FillPath($fill, $path)
  if ($stroke) { $g.DrawPath($stroke, $path) }
  $path.Dispose()
}

function Draw-Sparkles($g, $x, $y, $scale, $brush) {
  $pen = [System.Drawing.Pen]::new($brush.Color, [Math]::Max(2, 3 * $scale))
  foreach ($p in @(@(0,0), @(48,18), @(22,58), @(76,70))) {
    $cx = $x + $p[0] * $scale
    $cy = $y + $p[1] * $scale
    $r = 10 * $scale
    $g.DrawLine($pen, $cx, $cy - $r, $cx, $cy + $r)
    $g.DrawLine($pen, $cx - $r, $cy, $cx + $r, $cy)
  }
  $pen.Dispose()
}

function Draw-Chibi($g, $x, $y, $scale, $theme) {
  $outline = [System.Drawing.Pen]::new((New-Color 82 72 92), 4 * $scale)
  $skin = New-Brush (New-Color 255 229 216)
  $hair = New-Brush (New-Color 94 73 121)
  $cheek = New-Brush (New-Color 255 156 172)
  $eye = New-Brush (New-Color 43 50 68)
  $bow = New-Brush (New-Color 255 127 150)
  $white = New-Brush ([System.Drawing.Color]::White)

  $head = [System.Drawing.RectangleF]::new($x, $y + 28 * $scale, 132 * $scale, 122 * $scale)
  $g.FillEllipse($skin, $head)
  $g.DrawEllipse($outline, $head)

  $bangs = @(
    [System.Drawing.RectangleF]::new($x + 8*$scale, $y + 18*$scale, 56*$scale, 56*$scale),
    [System.Drawing.RectangleF]::new($x + 48*$scale, $y + 12*$scale, 64*$scale, 62*$scale),
    [System.Drawing.RectangleF]::new($x + 88*$scale, $y + 24*$scale, 42*$scale, 46*$scale)
  )
  foreach ($b in $bangs) { $g.FillEllipse($hair, $b) }

  $g.FillEllipse($eye, [System.Drawing.RectangleF]::new($x + 38*$scale, $y + 78*$scale, 13*$scale, 20*$scale))
  $g.FillEllipse($eye, [System.Drawing.RectangleF]::new($x + 86*$scale, $y + 78*$scale, 13*$scale, 20*$scale))
  $g.FillEllipse($white, [System.Drawing.RectangleF]::new($x + 42*$scale, $y + 81*$scale, 4*$scale, 5*$scale))
  $g.FillEllipse($white, [System.Drawing.RectangleF]::new($x + 90*$scale, $y + 81*$scale, 4*$scale, 5*$scale))
  $g.FillEllipse($cheek, [System.Drawing.RectangleF]::new($x + 19*$scale, $y + 103*$scale, 24*$scale, 11*$scale))
  $g.FillEllipse($cheek, [System.Drawing.RectangleF]::new($x + 92*$scale, $y + 103*$scale, 24*$scale, 11*$scale))
  $g.DrawArc($outline, $x + 57*$scale, $y + 100*$scale, 26*$scale, 18*$scale, 15, 150)

  if ($theme -eq 'runner') {
    $cap = New-Brush (New-Color 118 209 184)
    $g.FillPie($cap, $x + 16*$scale, $y + 5*$scale, 100*$scale, 55*$scale, 180, 180)
    $g.DrawArc($outline, $x + 16*$scale, $y + 5*$scale, 100*$scale, 55*$scale, 180, 180)
    $cap.Dispose()
  } elseif ($theme -eq 'english') {
    $g.FillEllipse($bow, [System.Drawing.RectangleF]::new($x + 96*$scale, $y + 19*$scale, 26*$scale, 22*$scale))
    $g.FillEllipse($bow, [System.Drawing.RectangleF]::new($x + 119*$scale, $y + 19*$scale, 26*$scale, 22*$scale))
  } else {
    $g.FillPolygon($hair, @(
      [System.Drawing.PointF]::new($x + 8*$scale, $y + 47*$scale),
      [System.Drawing.PointF]::new($x + 28*$scale, $y + 8*$scale),
      [System.Drawing.PointF]::new($x + 48*$scale, $y + 47*$scale)
    ))
    $g.FillPolygon($hair, @(
      [System.Drawing.PointF]::new($x + 86*$scale, $y + 47*$scale),
      [System.Drawing.PointF]::new($x + 108*$scale, $y + 8*$scale),
      [System.Drawing.PointF]::new($x + 126*$scale, $y + 50*$scale)
    ))
  }

  $skin.Dispose(); $hair.Dispose(); $cheek.Dispose(); $eye.Dispose(); $bow.Dispose(); $white.Dispose(); $outline.Dispose()
}

function Draw-ThemeSticker($g, $theme, $x, $y, $scale) {
  $teal = New-Brush (New-Color 0 128 150)
  $pink = New-Brush (New-Color 255 134 165)
  $yellow = New-Brush (New-Color 255 205 96)
  $purple = New-Brush (New-Color 125 108 214)
  $green = New-Brush (New-Color 105 196 145)
  $line = [System.Drawing.Pen]::new((New-Color 74 80 110), 4 * $scale)

  switch ($theme) {
    'math' {
      Draw-Chibi $g $x $y $scale 'math'
      $g.DrawString('fx', [System.Drawing.Font]::new('Arial', 26*$scale, [System.Drawing.FontStyle]::Bold), $teal, $x + 134*$scale, $y + 55*$scale)
      Draw-Sparkles $g ($x + 145*$scale) ($y + 100*$scale) $scale $yellow
    }
    'physics' {
      Draw-Chibi $g $x $y $scale 'physics'
      $cx = $x + 168*$scale; $cy = $y + 78*$scale
      $g.DrawEllipse($line, [System.Drawing.RectangleF]::new($cx-48*$scale, $cy-18*$scale, 96*$scale, 36*$scale))
      $g.DrawEllipse($line, [System.Drawing.RectangleF]::new($cx-18*$scale, $cy-48*$scale, 36*$scale, 96*$scale))
      $g.FillEllipse($purple, [System.Drawing.RectangleF]::new($cx-10*$scale, $cy-10*$scale, 20*$scale, 20*$scale))
    }
    'english' {
      Draw-Chibi $g $x $y $scale 'english'
      $bubble = [System.Drawing.RectangleF]::new($x + 128*$scale, $y + 32*$scale, 98*$scale, 66*$scale)
      Draw-RoundRect $g $bubble (14*$scale) (New-Brush ([System.Drawing.Color]::White)) $line
      $g.DrawString('ABC', [System.Drawing.Font]::new('Arial', 23*$scale, [System.Drawing.FontStyle]::Bold), $pink, $x + 144*$scale, $y + 48*$scale)
    }
    'runner' {
      Draw-Chibi $g $x $y $scale 'runner'
      $g.DrawLine($line, $x + 142*$scale, $y + 78*$scale, $x + 204*$scale, $y + 78*$scale)
      $g.DrawLine($line, $x + 158*$scale, $y + 116*$scale, $x + 218*$scale, $y + 116*$scale)
      $g.FillEllipse($green, [System.Drawing.RectangleF]::new($x + 150*$scale, $y + 42*$scale, 34*$scale, 20*$scale))
    }
    'moon' {
      Draw-Chibi $g $x $y $scale 'moon'
      $g.FillEllipse($yellow, [System.Drawing.RectangleF]::new($x + 145*$scale, $y + 30*$scale, 68*$scale, 68*$scale))
      $g.FillEllipse((New-Brush (New-Color 248 250 252)), [System.Drawing.RectangleF]::new($x + 166*$scale, $y + 20*$scale, 68*$scale, 72*$scale))
      Draw-Sparkles $g ($x + 145*$scale) ($y + 108*$scale) $scale $purple
    }
    default {
      Draw-Chibi $g $x $y $scale 'daily'
      Draw-Sparkles $g ($x + 140*$scale) ($y + 40*$scale) $scale $pink
      Draw-Sparkles $g ($x + 168*$scale) ($y + 105*$scale) $scale $yellow
    }
  }

  $teal.Dispose(); $pink.Dispose(); $yellow.Dispose(); $purple.Dispose(); $green.Dispose(); $line.Dispose()
}

$themes = @(
  @{ Key='math'; Name='高数小能量'; Accent=(New-Color 0 128 150); Soft=(New-Color 232 247 249) },
  @{ Key='physics'; Name='物理星球'; Accent=(New-Color 115 98 205); Soft=(New-Color 241 238 255) },
  @{ Key='english'; Name='英语甜甜圈'; Accent=(New-Color 232 107 140); Soft=(New-Color 255 240 246) },
  @{ Key='runner'; Name='夜跑冲刺'; Accent=(New-Color 58 151 110); Soft=(New-Color 238 249 241) },
  @{ Key='moon'; Name='月亮复盘'; Accent=(New-Color 184 126 44); Soft=(New-Color 255 247 232) },
  @{ Key='daily'; Name='闪闪日常'; Accent=(New-Color 70 142 198); Soft=(New-Color 236 246 255) }
)

$theme = $themes[($Date.DayOfYear - 1) % $themes.Count]
$weekdayNames = @('周日', '周一', '周二', '周三', '周四', '周五', '周六')
$weekdayName = $weekdayNames[[int]$Date.DayOfWeek]
$termStart = [datetime]'2026-06-08'
$teachingWeek = 14 + [Math]::Floor((($Date.Date - $termStart).TotalDays) / 7)
if ($teachingWeek -lt 1) { $teachingWeek = 1 }

function New-Item($time, $main, $note, $type) {
  @{ Time=$time; Main=$main; Note=$note; Type=$type }
}

function Test-Week($weeks, $week) {
  if ($weeks.Count -eq 2 -and $weeks[0] -is [int] -and $weeks[1] -is [int]) {
    return ($week -ge $weeks[0] -and $week -le $weeks[1])
  }
  foreach ($w in $weeks) {
    if ($w -is [array]) {
      if ($week -ge $w[0] -and $week -le $w[1]) { return $true }
    } elseif ($week -eq $w) {
      return $true
    }
  }
  return $false
}

function Get-CourseForSlot($day, $period, $week) {
  $courses = @(
    @{ Day=1; Period=1; Name='高等数学（二）'; Teacher='李元林'; Place='阅道楼 2楼 201室'; Weeks=@(@(1,15)) },
    @{ Day=1; Period=4; Name='线性代数'; Teacher='郭挺'; Place='阅道楼 1楼 109室'; Weeks=@(@(1,8)) },
    @{ Day=1; Period=4; Name='形势与政策（二）'; Teacher='孙丰'; Place='阅道楼 1楼 120室'; Weeks=@(@(11,14)) },
    @{ Day=2; Period=1; Name='高等数学（二）'; Teacher='李元林'; Place='阅道楼 2楼 201室'; Weeks=@(@(1,15)) },
    @{ Day=2; Period=2; Name='大学英语（二）'; Teacher='曾敏'; Place='文山楼 2楼 220室'; Weeks=@(@(2,16)) },
    @{ Day=2; Period=4; Name='大学生创新创业基础'; Teacher='郭军'; Place='文山楼 1楼 108室'; Weeks=@(@(9,16)) },
    @{ Day=3; Period=1; Name='线性代数'; Teacher='郭挺'; Place='阅道楼 1楼 109室'; Weeks=@(@(1,8)) },
    @{ Day=3; Period=1; Name='专业导论'; Teacher='刘德儿、李恒凯'; Place='阅道楼 1楼 123室'; Weeks=@(@(9,12)) },
    @{ Day=3; Period=2; Name='体育（二）'; Teacher='白雪冰'; Place='东区篮球场（三江乐园）'; Weeks=@(@(1,16)) },
    @{ Day=3; Period=3; Name='大学生创新创业基础'; Teacher='郭军'; Place='文山楼 1楼 108室'; Weeks=@(@(9,16)) },
    @{ Day=3; Period=4; Name='大学物理（一）'; Teacher='罗威'; Place='阅道楼 1楼 107室'; Weeks=@(@(1,14)) },
    @{ Day=4; Period=1; Name='高等数学（二）'; Teacher='李元林'; Place='阅道楼 2楼 201室'; Weeks=@(@(1,14)) },
    @{ Day=4; Period=1; Name='大学英语（二）'; Teacher='曾敏'; Place='文山楼 2楼 220室'; Weeks=@(15) },
    @{ Day=4; Period=3; Name='中国近现代史纲要'; Teacher='邱圣纺'; Place='文山楼 1楼 128室'; Weeks=@(@(1,16)); NoStudy=$true },
    @{ Day=4; Period=4; Name='面向对象程序设计'; Teacher='刘星根'; Place='阅道楼 2楼 203室'; Weeks=@(@(1,9)) },
    @{ Day=5; Period=1; Name='面向对象程序设计'; Teacher='刘星根'; Place='阅道楼 2楼 203室'; Weeks=@(@(1,9)) },
    @{ Day=5; Period=2; Name='大学英语（二）'; Teacher='曾敏'; Place='文山楼 2楼 220室'; Weeks=@(3,5,7,9,11,13,15,17) },
    @{ Day=5; Period=4; Name='大学物理（一）'; Teacher='罗威'; Place='阅道楼 1楼 107室'; Weeks=@(@(1,14)) }
  )
  foreach ($course in $courses) {
    if ($course.Day -eq $day -and $course.Period -eq $period -and (Test-Week $course.Weeks $week)) {
      return $course
    }
  }
  return $null
}

function Get-StudyMainForSlot($period, $day) {
  if ($period -eq 1) { return '高数学习' }
  if ($period -eq 2) { return '英语：单词 + 口语' }
  if ($period -eq 3) { return '物理学习' }
  if ($period -eq 4) { return '错题整理 / 作业推进' }
  return '学习'
}

function Get-StudyNoteForSlot($period, $day) {
  if ($period -eq 1) { return '概念梳理 + 例题训练' }
  if ($period -eq 2) { return '单词复习，跟读/复述15-20分钟' }
  if ($period -eq 3) { return '整理公式 + 做例题，记录不会的题型' }
  if ($period -eq 4) { return '优先处理高数/物理错题' }
  return '保持专注，完成一个小目标'
}

function Get-DayItems($date, $week) {
  $day = [int]$date.DayOfWeek
  $items = New-Object System.Collections.ArrayList
  [void]$items.Add((New-Item '07:20-08:00' '起床、洗漱、早餐' '检查课程和今天的学习任务' 'rest'))

  if ($day -eq 0 -or $day -eq 6) {
    [void]$items.Add((New-Item '08:30-10:00' '高数轻量复习' '回顾本周错题，保留休息感' 'study'))
    [void]$items.Add((New-Item '10:20-11:20' '英语：单词 + 口语' '单词复习，做一次短复述' 'study'))
    [void]$items.Add((New-Item '11:20-14:00' '午饭、休息、整理房间' '周末降低强度' 'rest'))
    [void]$items.Add((New-Item '14:00-15:30' '物理整理' '公式卡片 + 典型题复盘' 'study'))
    [void]$items.Add((New-Item '15:50-17:00' '下周准备' '看课表，列出下周高数/物理重点' 'study'))
  } else {
    $slotTimes = @{
      1 = @{ Travel='08:00-08:10'; Time='08:30-10:05' }
      2 = @{ Travel='10:05-10:15'; Time='10:25-12:00' }
      3 = @{ Travel='13:45-13:55'; Time='14:00-15:35' }
      4 = @{ Travel='15:45-15:55'; Time='15:55-17:30' }
    }
    foreach ($period in 1..4) {
      if ($period -eq 3) {
        [void]$items.Add((New-Item '12:00-13:30' '午饭、休息' '不要刷太久手机' 'rest'))
      }
      $course = Get-CourseForSlot $day $period $week
      $isDuty = (($day -eq 1 -and ($period -eq 2 -or $period -eq 3)) -or ($day -eq 4 -and ($period -eq 2 -or $period -eq 4)))
      if ($course -or $isDuty) {
        $place = if ($isDuty) { '校史馆' } else { ($course.Place -split ' ')[0] }
        [void]$items.Add((New-Item $slotTimes[$period].Travel ('去' + $place) '路程控制在10分钟以内' 'rest'))
      }
      if ($isDuty) {
        [void]$items.Add((New-Item $slotTimes[$period].Time '校史馆值班 + 学习' '值班空隙可背单词/看错题' 'study'))
      } elseif ($course) {
        $note = $course.Place + '；' + $(if ($course.NoStudy) { '这节课不安排额外学习' } else { '课上记录重点和不会的问题' })
        [void]$items.Add((New-Item $slotTimes[$period].Time ('去上课：' + $course.Name) $note 'class'))
      } else {
        [void]$items.Add((New-Item $slotTimes[$period].Time (Get-StudyMainForSlot $period $day) (Get-StudyNoteForSlot $period $day) 'study'))
      }
    }
  }

  [void]$items.Add((New-Item '17:30-19:00' '晚饭、放松' '给晚上学习和跑步留精力' 'rest'))
  [void]$items.Add((New-Item '19:00-20:00' '高数 / 物理补弱' '按今天最卡的内容做同类型题' 'study'))
  [void]$items.Add((New-Item '20:00-20:40' '英语：单词 + 口语' '复习单词，跟读/复述15-20分钟' 'study'))
  [void]$items.Add((New-Item '20:40-21:10' '跑前准备' '换衣服，热身' 'run'))
  [void]$items.Add((New-Item '21:10-22:10' '跑步 5 公里' '必须在21:00-23:00之间完成' 'run'))
  [void]$items.Add((New-Item '22:10-22:50' '拉伸、洗漱、恢复' '放松小腿和大腿后侧' 'run'))
  [void]$items.Add((New-Item '22:50-23:40' '错题/知识点巩固' '写下明天要补的知识点' 'study'))
  [void]$items.Add((New-Item '23:40-00:10' '今日复盘' '高数、物理、英语各写一句完成情况' 'study'))
  [void]$items.Add((New-Item '00:10-00:30' '准备睡觉' '00:30睡觉' 'rest'))
  return $items
}

$width = 1080
$height = 1920
$bmp = [System.Drawing.Bitmap]::new($width, $height)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

$bgTop = $theme.Soft
$bgBottom = New-Color 255 255 255
$bgBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
  [System.Drawing.Rectangle]::new(0, 0, $width, $height),
  $bgTop,
  $bgBottom,
  [System.Drawing.Drawing2D.LinearGradientMode]::Vertical
)
$g.FillRectangle($bgBrush, 0, 0, $width, $height)

$ink = New-Color 24 31 44
$muted = New-Color 87 102 125
$lineColor = New-Color 217 226 235
$fontTitle = [System.Drawing.Font]::new('Microsoft YaHei UI', 35, [System.Drawing.FontStyle]::Bold)
$fontSub = [System.Drawing.Font]::new('Microsoft YaHei UI', 17, [System.Drawing.FontStyle]::Regular)
$fontTime = [System.Drawing.Font]::new('Microsoft YaHei UI', 18, [System.Drawing.FontStyle]::Bold)
$fontMain = [System.Drawing.Font]::new('Microsoft YaHei UI', 20, [System.Drawing.FontStyle]::Bold)
$fontNote = [System.Drawing.Font]::new('Microsoft YaHei UI', 15, [System.Drawing.FontStyle]::Regular)
$fontTag = [System.Drawing.Font]::new('Microsoft YaHei UI', 14, [System.Drawing.FontStyle]::Bold)
$brushInk = New-Brush $ink
$brushMuted = New-Brush $muted
$brushAccent = New-Brush $theme.Accent
$penLine = [System.Drawing.Pen]::new($lineColor, 2)

$left = 52
$y = 48
$title = '{0:yyyy-MM-dd} {1}计划' -f $Date, $weekdayName
$g.DrawString($title, $fontTitle, $brushInk, $left, $y)
$y += 58
$g.DrawString(('第{0}教学周 · 今日主题：{1} · 00:30睡觉' -f $teachingWeek, $theme.Name), $fontSub, $brushMuted, $left, $y)
Draw-ThemeSticker $g $theme.Key 760 34 0.72
$y += 48

$tagRect = [System.Drawing.RectangleF]::new($left, $y, 438, 38)
$tagBrush = New-Brush ([System.Drawing.Color]::FromArgb(248, 255, 255, 255))
Draw-RoundRect $g $tagRect 8 $tagBrush $null
$g.DrawString('每天轮换贴纸 · 清晰优先 · 可爱一点', $fontTag, $brushAccent, $left + 18, $y + 8)
$tagBrush.Dispose()
$y += 54

$items = Get-DayItems $Date $teachingWeek

$typeColors = @{
  class = New-Color 234 241 255
  study = New-Color 229 247 248
  run = New-Color 236 249 239
  rest = New-Color 255 248 234
}

foreach ($item in $items) {
  $cardH = 68
  $rect = [System.Drawing.RectangleF]::new($left, $y, $width - 2*$left, $cardH)
  $fill = New-Brush $typeColors[$item.Type]
  Draw-RoundRect $g $rect 8 $fill $penLine
  $g.FillEllipse($brushAccent, [System.Drawing.RectangleF]::new($left + 16, $y + 23, 10, 10))
  $g.DrawString($item.Time, $fontTime, $brushAccent, $left + 36, $y + 10)
  $g.DrawString($item.Main, $fontMain, $brushInk, $left + 232, $y + 7)
  $g.DrawString($item.Note, $fontNote, $brushMuted, $left + 232, $y + 39)
  $fill.Dispose()
  $y += $cardH + 9
}

Draw-ThemeSticker $g $themes[(($Date.DayOfYear) % $themes.Count)].Key 726 1714 0.64
$g.DrawString('今日重点：高数跟课不掉线，物理补题感，英语单词+口语，晚上跑完5公里。', $fontTag, $brushMuted, $left, 1862)

New-Item -ItemType Directory -Force -Path ([System.IO.Path]::GetDirectoryName($OutPath)) | Out-Null
$bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)

$g.Dispose()
$bmp.Dispose()
$bgBrush.Dispose()
$brushInk.Dispose()
$brushMuted.Dispose()
$brushAccent.Dispose()
$penLine.Dispose()

Write-Output $OutPath
