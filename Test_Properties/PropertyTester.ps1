# This script writes 1000 unicode bytes to each EXIF property and then reads it to find which properties will work for storage.

param (
	[Parameter(Mandatory=$true)][string]$WImagePath
)

# Quick hack to hide the errors of unusable properties

$ErrorActionPreference = 'SilentlyContinue'

# Get the full path of the original image, as it will be needed when working with the image

$absOriginalImagePath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($pwd, $WImagePath))

# Create temp image to write the property to

$testImageFilePath = [System.IO.Path]::GetTempFileName()

# Some initializations

[int32[]]$storageProperties = 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,254,255,256,257,258,259,262,263,264,265,266,269,270,271,272,273,274,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,296,297,301,305,306,315,316,317,318,319,320,321,322,323,324,325,332,333,334,336,337,338,339,340,341,342,512,513,514,515,517,518,519,520,521,529,530,531,532,769,770,771,800,20481,20482,20483,20484,20485,20486,20487,20488,20489,20490,20491,20492,20493,20494,20495,20496,20497,20498,20499,20500,20501,20502,20503,20504,20505,20506,20507,20512,20513,20514,20515,20516,20517,20518,20519,20520,20521,20522,20523,20524,20525,20526,20527,20528,20529,20530,20531,20532,20533,20534,20535,20536,20537,20538,20539,20624,20625,20736,20737,20738,20739,20740,20752,20753,20754,20755,33432,33434,33437,34665,34675,34850,34852,34853,34855,34856,36864,36867,36868,37121,37122,37377,37378,37379,37380,37381,37382,37383,37384,37385,37386,37500,37510,37520,37521,37522,40960,40961,40962,40963,40964,40965,41483,41484,41486,41487,41488,41492,41493,41495,41728,41729,41730

Add-Type -AssemblyName system.drawing 

# Initialize the unicode encoder

$encoder = new-object System.Text.UnicodeEncoding

# Create a variable to store usable properties

$usableProperties = @()
$unusableProperties = @()

foreach ($propertyId in $storageProperties)
	{
	
		# Load the original image and read the first property to use as base

		$WImage = New-Object -TypeName system.drawing.bitmap -ArgumentList $absOriginalImagePath
		$WImageBaseProperty = $WImage.GetPropertyItem($WImage.PropertyIdList[0])
		
		# Prepare Test data

		$testString = $testString = (-join ((65..90) + (97..122) | Get-Random -Count 10 | % {[char]$_})) * 100
		$WImageEncodedString = $encoder.Getbytes($testString)
	
		# Load the image from the last good known backup
	

		$WImageBaseProperty.Type = 1
		$WImageBaseProperty.Id = $propertyId
		$WImageBaseProperty.Value = $WImageEncodedString
		$WImageBaseProperty.Len = $WImageEncodedString.Length
		
		# Store the property, save the image in the test image file, and close it.
		
		$WImage.SetPropertyItem($WImageBaseProperty)
		$WImage.Save($testImageFilePath)
		$WImage.Dispose()
		
		# Load again the saved image to be tested and try to recover the data we just wrote.
		
		$WImageTested = New-Object -TypeName system.drawing.bitmap -ArgumentList $testImageFilePath
		$ImageProperty = $WImageTested.GetPropertyItem($propertyId)
		$PocString = [System.Text.Encoding]::Unicode.GetString($ImageProperty.Value)
		
		# Check if the property has been correctly saved
		
		if ($PocString -eq $testString) {

			# If the property is the same that the one written, store the property as usable,
			# update the working backup of the image, and close the tested image.

			$usableProperties += $propertyId		
		
		}

		$WImageTested.Dispose()
		Remove-Item -path $testImageFilePath
		
	}
	
return $usableProperties