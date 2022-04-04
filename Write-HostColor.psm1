#Requires -Version 7.2
Set-StrictMode -Version Latest


# mapping from ConsoleColor to PSStyle color names
$ConsoleColorToPSStyle = @{
	DarkBlue = "Blue"
	Blue = "BrightBlue"
	DarkGreen = "Green"
	Green = "BrightGreen"
	DarkCyan = "Cyan"
	Cyan = "BrightCyan"
	DarkRed = "Red"
	Red = "BrightRed"
	DarkMagenta = "Magenta"
	Magenta = "BrightMagenta"
	DarkYellow = "Yellow"
	Yellow = "BrightYellow"

	Black = "Black"
	Gray = "White"
	DarkGray = "BrightBlack"
	White = "BrightWhite"
}


function GetColorEscapeSequence($Color, $PSStylePalette) {
	if (-not $Color) {
		return ""

	} elseif ($Color -is [Array] -and @($Color).Count -eq 3) {
		# RGB color set as a 3-tuple
		return $PSStylePalette.FromRgb($Color[0], $Color[1], $Color[2])

	} elseif ($Color.Length -eq 7 -and $Color[0] -eq "#") {
		# CSS color (e.g. #aabbcc)
		$R, $G, $B = 1, 3, 5 | % {[Convert]::FromHexString($Color.Substring($_, 2))}
		return $PSStylePalette.FromRgb($R, $G, $B)

	} elseif ($Color[0] -eq 27 -and $Color[-1] -eq 109) {
		# VT color escape sequence, leave unchanged
		# this may be an arbitrary escape sequence, not just a color, but I don't want to write a VT parser here
		return $Color

	} elseif ($Color -in [Enum]::GetNames([System.ConsoleColor])) {
		return $PSStylePalette | Select-Object -ExpandProperty $ConsoleColorToPSStyle[$Color]

	} else {
		throw "Unknown color name/format: '$Color'"
	}
}

function Write-HostColor {
	[CmdletBinding()]
	param(
			[Parameter(Mandatory, ValueFromPipeline)]
			[Object]
		$Object,
			[switch]
		$NoNewline,
			[string]
		$Separator = " ",
			[ArgumentCompletions("Black", "DarkBlue", "DarkGreen", "DarkCyan", "DarkRed",
				"DarkMagenta", "DarkYellow", "Gray", "DarkGray", "Blue", "Green", "Cyan",
				"Red", "Magenta", "Yellow", "White")]
		$ForegroundColor,
			[ArgumentCompletions("Black", "DarkBlue", "DarkGreen", "DarkCyan", "DarkRed",
				"DarkMagenta", "DarkYellow", "Gray", "DarkGray", "Blue", "Green", "Cyan",
				"Red", "Magenta", "Yellow", "White")]
		$BackgroundColor
	)
	
	begin {
		$FgColorStr = GetColorEscapeSequence $ForegroundColor $PSStyle.Foreground
		$BgColorStr = GetColorEscapeSequence $BackgroundColor $PSStyle.Background
		$ColorResetStr = if ($FgColorStr -or $BgColorStr) {$PSStyle.Reset} else {""}
	}

	process {
		$Str = $Object | Join-String -Separator $Separator
		$Host.UI.Write($FgColorStr + $BgColorStr + $Str + $(if (-not $NoNewline) {"`n"}) + $ColorResetStr)
	}
}
