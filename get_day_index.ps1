$PSModuleAutoloadingPreference = 'None'
# Load necessary assembly (suppress output)
[void][Reflection.Assembly]::LoadWithPartialName("System.Globalization")

# Create a CultureInfo object for the 'en-US' culture using .NET
$enUSCulture = [System.Globalization.CultureInfo]::new("en-US") 

# Get the current date and time
$now = [System.DateTime]::Now

# Format the date as YYYY-MM-DD
$formattedDate = $now.ToString("yyyy-MM-dd", $enUSCulture.DateTimeFormat)

# Get the day name in English
$dayName = $enUSCulture.DateTimeFormat.GetDayName($now.DayOfWeek)

# Output the formatted date and day name
"$formattedDate $dayName"
