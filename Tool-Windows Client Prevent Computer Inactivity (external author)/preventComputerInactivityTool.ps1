<#
.NAME
    preventComputerInactivityTool.ps1

.DESCRIPTION
    Script w/ GUI to Prevent Computer Inactivity

.SYNOPSIS
    This is a little script I use to prevent messenger software from
    marking me as inactive. It presses Scroll Lock once a minute while
    running. I added a time window, for example you can set it to only
    keep you active between 8:00AM - 5:00PM. It runs the job in the
    background, so it will continue to run until you click Turn Off
    even if the tool is closed. I created a shortcut to run the tool
    and pinned it to my taskbar.

.NOTES
    AUTHOR:
    https://www.reddit.com/user/TheCallOfAsheron/

    URL:
    https://www.reddit.com/r/PowerShell/comments/xl9lr5/script_w_gui_to_prevent_computer_inactivity/?rdt=38702

#>

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form = New-Object system.Windows.Forms.Form
$Form.ClientSize = New-Object System.Drawing.Point(200, 70)
$Form.text = "Light"
$Form.FormBorderStyle = 'Fixed3D'
$Form.MaximizeBox = $false
$Form.TopMost = $false

# Generates the application icon
[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null
$bmp = New-Object System.Drawing.Bitmap(16, 16)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.drawline([System.Drawing.Pens]::Green, 1, 11, 15, 11)
$g.drawline([System.Drawing.Pens]::Green, 1, 10, 15, 10)
$g.drawline([System.Drawing.Pens]::Green, 1, 9, 15, 9)
$g.drawline([System.Drawing.Pens]::Green, 2, 8, 14, 8)
$g.drawline([System.Drawing.Pens]::Green, 3, 7, 13, 7)
$g.drawline([System.Drawing.Pens]::Green, 5, 6, 11, 6)
$g.drawline([System.Drawing.Pens]::Green, 8, 5, 8, 5)

$ico = [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
$Form.Icon = $ico





$button = New-Object system.Windows.Forms.Button
$button.Text = "Start"     
$button.width = 180
$button.height = 24
$button.location = New-Object System.Drawing.Point(10, 8)
$button.Font = 'Microsoft Sans Serif,10'
$button.Add_Click({ 
        
        if ( [bool](get-job -Name light | Where-Object { $_.State -eq 'Running' }) ) {
            stop-job -name light  
            $button.text = "Turn On"
            $button.ForeColor = "Green" 
            $Form.Controls.add($CheckBoxSchedule)
            $Form.Controls.add($TextBoxStartTime)
            $Form.Controls.add($TextBoxEndTime)

            $Form.Controls.Remove($LabelStartTime)
            $Form.Controls.Remove($LabelEndTime)
        
        }
        else {
      


            $button.text = "Turn Off"
            $button.ForeColor = "Red"
            if ( $CheckBoxSchedule.checked -eq $true) {
                $start = $TextBoxStartTime.Text
                $end = $TextBoxEndTime.Text
                $min = Get-Date $start
                $max = Get-Date $end
                $LabelStartTime.Text = $start
                $LabelEndTime.Text = $end
            }
            else {
                $min = Get-Date '00:00'
                $max = Get-Date '23:59'
                $LabelStartTime.Text = "00:00"
                $LabelEndTime.Text = "23:59"
            }
          

            $Form.Controls.Remove($CheckBoxSchedule)
            $Form.Controls.Remove($TextBoxStartTime)
            $Form.Controls.Remove($TextBoxEndTime)
       
            $Form.Controls.Add($LabelStartTime)
            $Form.Controls.Add($LabelEndTime)

        
            Start-Job -argumentlist $min, $max -scriptblock {
          
                $WShell = New-Object -com "Wscript.Shell" 
                While ($true) { 
                    $now = get-date
                    if ($Using:min.TimeOfDay -le $now.TimeOfDay -and $Using:max.TimeOfDay -ge $now.TimeOfDay) {
                        $WShell.sendkeys("{SCROLLLOCK}") 

                        Start-Sleep -Seconds 60
                    
                    }
                    else { 
                        Start-Sleep -Seconds 60
                      

                    }
                }
                             
           
            } -name 'light'
        }
    })
$Form.Controls.Add($button)

$CheckBoxSchedule = New-Object system.Windows.Forms.CheckBox
$CheckBoxSchedule.text = "Schedule"
$CheckBoxSchedule.AutoSize = $false
$CheckBoxSchedule.width = 85
$CheckBoxSchedule.height = 20
$CheckBoxSchedule.location = New-Object System.Drawing.Point(10, 38)
$CheckBoxSchedule.Font = 'Microsoft Sans Serif,10'
$Form.Controls.Add($CheckBoxSchedule)

$TextBoxStartTime = New-Object system.Windows.Forms.TextBox
$TextBoxStartTime.multiline = $false
$TextBoxStartTime.width = 40
$TextBoxStartTime.height = 20
$TextBoxStartTime.location = New-Object System.Drawing.Point(100, 36)
$TextBoxStartTime.Font = 'Microsoft Sans Serif,10'
$TextBoxStartTime.Text = '07:00'
$Form.Controls.Add($TextBoxStartTime)

$TextBoxEndTime = New-Object system.Windows.Forms.TextBox
$TextBoxEndTime.multiline = $false
$TextBoxEndTime.width = 40
$TextBoxEndTime.height = 20
$TextBoxEndTime.location = New-Object System.Drawing.Point(150, 36)
$TextBoxEndTime.Font = 'Microsoft Sans Serif,10'
$TextBoxEndTime.Text = '16:00'
$Form.Controls.Add($TextBoxEndTime)

$LabelStartTime = New-Object system.Windows.Forms.Label
$LabelStartTime.width = 40
$LabelStartTime.height = 20
$LabelStartTime.location = New-Object System.Drawing.Point(50, 36)
$LabelStartTime.Font = 'Microsoft Sans Serif,10'

$LabelEndTime = New-Object system.Windows.Forms.Label
$LabelEndTime.width = 40
$LabelEndTime.height = 20
$LabelEndTime.location = New-Object System.Drawing.Point(100, 36)
$LabelEndTime.Font = 'Microsoft Sans Serif,10'



if ( [bool](get-job -Name light | Where-Object { $_.State -eq 'Running' }) ) {
    $button.text = "Turn Off"
    $button.ForeColor = "Red"
}
else {
    $button.text = "Turn On"
    $button.ForeColor = "Green"
}
[void]$Form.ShowDialog()