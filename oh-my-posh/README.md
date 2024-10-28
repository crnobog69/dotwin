oh-my-posh init pwsh --config 'C:\Users\68vul\OneDrive\Desktop\dotwin\oh-my-posh\posh.json' | Invoke-Expression

# Shows navigable menu of all options when hitting Tab

Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

# Autocompletion for arrow keys

Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

# aliases

Set-Alias -Name c -Value clear

# fetch

# fastfetch
